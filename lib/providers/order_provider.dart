import 'package:flutter/foundation.dart';
import '../models/order_model.dart';
import '../models/recipe_model.dart';
import 'inventory_provider.dart';
import 'customer_provider.dart';

class OrderProvider extends ChangeNotifier {
  List<OrderModel> _orders = [];
  String _searchQuery = '';
  OrderStatus? _selectedStatusFilter;

  List<OrderModel> get orders => List.unmodifiable(_orders);
  String get searchQuery => _searchQuery;
  OrderStatus? get selectedStatusFilter => _selectedStatusFilter;

  List<OrderModel> get filteredOrders {
    return _orders.where((order) {
      final matchesSearch = order.invoiceNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          order.customerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          order.customerPostcode.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus = _selectedStatusFilter == null || order.status == _selectedStatusFilter;
      return matchesSearch && matchesStatus;
    }).toList();
  }

  int get pendingOrdersCount => _orders.where((o) => o.status == OrderStatus.pending || o.status == OrderStatus.baking).length;

  double get todaySalesTotal {
    final now = DateTime.now();
    return _orders
        .where((o) => o.createdAt.year == now.year && o.createdAt.month == now.month && o.createdAt.day == now.day && o.status != OrderStatus.cancelled)
        .fold(0.0, (sum, o) => sum + o.totalAmount);
  }

  double get monthSalesTotal {
    final now = DateTime.now();
    return _orders
        .where((o) => o.createdAt.year == now.year && o.createdAt.month == now.month && o.status != OrderStatus.cancelled)
        .fold(0.0, (sum, o) => sum + o.totalAmount);
  }

  double get annualSalesTotal {
    final now = DateTime.now();
    return _orders
        .where((o) => o.createdAt.year == now.year && o.status != OrderStatus.cancelled)
        .fold(0.0, (sum, o) => sum + o.totalAmount);
  }

  void setOrders(List<OrderModel> list) {
    _orders = list;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setStatusFilter(OrderStatus? status) {
    _selectedStatusFilter = status;
    notifyListeners();
  }

  String generateNextInvoiceNumber() {
    final nextNumber = _orders.length + 101;
    return 'INV-2026-${nextNumber.toString().padLeft(3, '0')}';
  }

  void createOrder({
    required OrderModel order,
    required List<RecipeModel> recipesCatalog,
    required InventoryProvider inventoryProvider,
    required CustomerProvider customerProvider,
  }) {
    _orders.insert(0, order);

    // 1. Calculate required stock deductions from ingredients in the ordered recipes
    final Map<String, double> deductions = {};
    for (final item in order.items) {
      final recipe = recipesCatalog.firstWhere(
        (r) => r.id == item.recipeId,
        orElse: () => RecipeModel(
          id: '',
          title: item.recipeName,
          category: '',
          prepTimeMins: 0,
          bakeTimeMins: 0,
          bakingTempC: 0,
          yieldServings: 1,
          sellingPrice: item.unitPrice,
          ingredients: [],
          instructions: [],
          notes: '',
          allergens: [],
          nutritionalInfo: const NutritionalInfo(),
        ),
      );

      // Recipe ingredients quantities are per batch yield
      final batchCount = recipe.yieldServings > 0 ? (item.quantity / recipe.yieldServings) : item.quantity.toDouble();

      for (final ingItem in recipe.ingredients) {
        final totalNeeded = ingItem.quantity * batchCount;
        deductions[ingItem.ingredientId] = (deductions[ingItem.ingredientId] ?? 0.0) + totalNeeded;
      }
    }

    // 2. Perform automated stock deduction in inventory
    if (deductions.isNotEmpty) {
      inventoryProvider.deductRecipeStock(deductions);
    }

    // 3. Update customer order totals
    customerProvider.recordCustomerOrder(order.customerId, order.totalAmount);

    notifyListeners();
  }

  void updateOrderStatus(String orderId, OrderStatus newStatus) {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      _orders[idx] = _orders[idx].copyWith(status: newStatus);
      notifyListeners();
    }
  }

  void updatePaymentStatus(String orderId, PaymentStatus paymentStatus) {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      _orders[idx] = _orders[idx].copyWith(paymentStatus: paymentStatus);
      notifyListeners();
    }
  }
}
