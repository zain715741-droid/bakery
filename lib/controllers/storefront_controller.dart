import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/order_model.dart';
import '../models/recipe_model.dart';
import '../models/customer_model.dart';
import '../providers/order_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/customer_provider.dart';
import '../providers/recipe_provider.dart';

class CartItem {
  final RecipeModel recipe;
  int quantity;

  CartItem({
    required this.recipe,
    this.quantity = 1,
  });

  double get lineTotal => quantity * recipe.sellingPrice;
}

class StorefrontController extends GetxController {
  // Category & Search filters
  final RxString selectedCategory = 'All'.obs;
  final RxString searchQuery = ''.obs;
  final searchController = TextEditingController();

  // Cart
  final RxList<CartItem> cartItems = <CartItem>[].obs;

  // Checkout Form
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final addressController = TextEditingController();
  final postcodeController = TextEditingController();
  final notesController = TextEditingController();
  final Rx<FulfillmentType> fulfillmentType = FulfillmentType.collection.obs;
  final Rx<DateTime> targetDate = DateTime.now().add(const Duration(hours: 3)).obs;
  final RxString selectedTimeSlot = 'Today (in 2-3 hours)'.obs;
  final Rx<double?> deliveryLatitude = Rx<double?>(null);
  final Rx<double?> deliveryLongitude = Rx<double?>(null);

  // Tracking
  final trackQueryController = TextEditingController();
  final Rx<OrderModel?> trackedOrder = Rx<OrderModel?>(null);
  final RxList<OrderModel> customerOrderHistory = <OrderModel>[].obs;
  final RxBool hasSearchedTracking = false.obs;

  // Active placed order for success screen
  final Rx<OrderModel?> lastPlacedOrder = Rx<OrderModel?>(null);

  int get totalCartItemCount => cartItems.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => cartItems.fold(0.0, (sum, item) => sum + item.lineTotal);

  double get vatAmount => subtotal * 0.20; // 20% standard UK VAT

  double get grandTotal => subtotal + vatAmount;

  void setCategory(String category) {
    selectedCategory.value = category;
  }

  void updateSearch(String query) {
    searchQuery.value = query;
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
  }

  void setDeliveryCoordinates(double lat, double lng, {String? formattedAddress}) {
    deliveryLatitude.value = lat;
    deliveryLongitude.value = lng;
    if (formattedAddress != null && formattedAddress.isNotEmpty) {
      addressController.text = formattedAddress;
    }
  }

  void addToCart(RecipeModel recipe, {int quantity = 1}) {
    final existingIndex = cartItems.indexWhere((item) => item.recipe.id == recipe.id);
    if (existingIndex != -1) {
      cartItems[existingIndex].quantity += quantity;
      cartItems.refresh();
    } else {
      cartItems.add(CartItem(recipe: recipe, quantity: quantity));
    }

    Get.snackbar(
      'Added to Cart',
      '${recipe.title} (x$quantity) added to your order',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF2C1810),
      colorText: const Color(0xFFF7E7CE),
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: const Icon(Icons.shopping_bag_outlined, color: Color(0xFFD4AF37)),
    );
  }

  void updateQuantity(String recipeId, int newQuantity) {
    if (newQuantity <= 0) {
      removeFromCart(recipeId);
      return;
    }
    final idx = cartItems.indexWhere((i) => i.recipe.id == recipeId);
    if (idx != -1) {
      cartItems[idx].quantity = newQuantity;
      cartItems.refresh();
    }
  }

  void removeFromCart(String recipeId) {
    cartItems.removeWhere((item) => item.recipe.id == recipeId);
  }

  void clearCart() {
    cartItems.clear();
  }

  int getItemQuantityInCart(String recipeId) {
    final item = cartItems.firstWhereOrNull((i) => i.recipe.id == recipeId);
    return item?.quantity ?? 0;
  }

  List<RecipeModel> getFilteredRecipes(List<RecipeModel> allRecipes) {
    return allRecipes.where((recipe) {
      final matchesCategory = selectedCategory.value == 'All' ||
          recipe.category.toLowerCase() == selectedCategory.value.toLowerCase();

      final query = searchQuery.value.trim().toLowerCase();
      final matchesSearch = query.isEmpty ||
          recipe.title.toLowerCase().contains(query) ||
          recipe.category.toLowerCase().contains(query) ||
          recipe.notes.toLowerCase().contains(query) ||
          recipe.allergens.any((a) => a.toLowerCase().contains(query));

      return matchesCategory && matchesSearch;
    }).toList();
  }

  // Order Placement
  OrderModel? submitOrder({
    required OrderProvider orderProvider,
    required InventoryProvider inventoryProvider,
    required CustomerProvider customerProvider,
    required RecipeProvider recipeProvider,
  }) {
    if (cartItems.isEmpty) {
      Get.snackbar('Cart is Empty', 'Please add items before placing an order.',
          backgroundColor: Colors.red.shade800, colorText: Colors.white);
      return null;
    }

    final name = nameController.text.trim();
    final phone = phoneController.text.trim();

    if (name.isEmpty) {
      Get.snackbar('Name Required', 'Please enter your name for the order.',
          backgroundColor: Colors.red.shade800, colorText: Colors.white);
      return null;
    }

    if (phone.isEmpty) {
      Get.snackbar('Phone Required', 'Please enter your phone number so we can contact you regarding your order.',
          backgroundColor: Colors.red.shade800, colorText: Colors.white);
      return null;
    }

    if (fulfillmentType.value == FulfillmentType.delivery && addressController.text.trim().isEmpty) {
      Get.snackbar('Address Required', 'Please enter delivery address for home delivery.',
          backgroundColor: Colors.red.shade800, colorText: Colors.white);
      return null;
    }

    // 1. Create or retrieve customer profile
    String customerId = 'cust_${DateTime.now().millisecondsSinceEpoch}';
    final existingCustomer = customerProvider.customers.firstWhereOrNull(
      (c) => c.phone.trim() == phone || (emailController.text.isNotEmpty && c.email.trim().toLowerCase() == emailController.text.trim().toLowerCase()),
    );

    if (existingCustomer != null) {
      customerId = existingCustomer.id;
    } else {
      final newCustomer = CustomerModel(
        id: customerId,
        name: name,
        phone: phone,
        email: emailController.text.trim(),
        address: addressController.text.trim(),
        postcode: postcodeController.text.trim().toUpperCase(),
        notes: 'Registered via Online Customer Storefront',
      );
      customerProvider.addCustomer(newCustomer);
    }

    // 2. Build Order Items
    final orderItems = cartItems.map((cartItem) {
      return OrderItem(
        recipeId: cartItem.recipe.id,
        recipeName: cartItem.recipe.title,
        quantity: cartItem.quantity,
        unitPrice: cartItem.recipe.sellingPrice,
      );
    }).toList();

    // 3. Generate Order Model
    final orderId = 'ord_${DateTime.now().millisecondsSinceEpoch}';
    final invoiceNumber = orderProvider.generateNextInvoiceNumber();

    final order = OrderModel(
      id: orderId,
      invoiceNumber: invoiceNumber,
      customerId: customerId,
      customerName: name,
      customerPhone: phone,
      customerAddress: addressController.text.trim(),
      customerPostcode: postcodeController.text.trim().toUpperCase(),
      latitude: deliveryLatitude.value,
      longitude: deliveryLongitude.value,
      items: orderItems,
      status: OrderStatus.pending,
      fulfillment: fulfillmentType.value,
      paymentStatus: PaymentStatus.unpaid,
      vatRate: 0.20,
      createdAt: DateTime.now(),
      targetDate: targetDate.value,
      notes: notesController.text.trim().isNotEmpty
          ? '[Online Storefront Order] ${notesController.text.trim()}'
          : '[Online Storefront Order]',
    );

    // 4. Save through OrderProvider (also automatically adjusts stock and records customer sales)
    orderProvider.createOrder(
      order: order,
      recipesCatalog: recipeProvider.recipes,
      inventoryProvider: inventoryProvider,
      customerProvider: customerProvider,
    );

    lastPlacedOrder.value = order;

    // Track this order immediately
    trackedOrder.value = order;
    hasSearchedTracking.value = true;
    trackQueryController.text = invoiceNumber;

    // Clear cart and customer form
    clearCart();
    notesController.clear();

    return order;
  }

  // Order Tracking Lookup
  void searchOrderForTracking(List<OrderModel> allOrders) {
    final query = trackQueryController.text.trim().toLowerCase();
    hasSearchedTracking.value = true;

    if (query.isEmpty) {
      trackedOrder.value = null;
      customerOrderHistory.clear();
      return;
    }

    // Search by invoice # or phone number
    final matches = allOrders.where((o) {
      final matchesInvoice = o.invoiceNumber.toLowerCase() == query || o.invoiceNumber.toLowerCase().contains(query);
      final matchesPhone = o.customerPhone.replaceAll(RegExp(r'[\s\-\(\)]'), '') == query.replaceAll(RegExp(r'[\s\-\(\)]'), '') ||
          o.customerPhone.toLowerCase().contains(query);
      return matchesInvoice || matchesPhone;
    }).toList();

    // Sort newest first
    matches.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (matches.isNotEmpty) {
      trackedOrder.value = matches.first;
      customerOrderHistory.assignAll(matches);
    } else {
      trackedOrder.value = null;
      customerOrderHistory.clear();
    }
  }

  void selectOrderFromHistory(OrderModel order) {
    trackedOrder.value = order;
    trackQueryController.text = order.invoiceNumber;
  }
}
