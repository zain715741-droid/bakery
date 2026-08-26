import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/customer_model.dart';
import '../services/database_service.dart';

class CustomerProvider extends ChangeNotifier {
  List<CustomerModel> _customers = [];
  String _searchQuery = '';
  StreamSubscription<List<CustomerModel>>? _customersSubscription;

  CustomerProvider() {
    _initLiveStream();
  }

  void _initLiveStream() {
    _customersSubscription = DatabaseService.instance.customersStream.listen(
      (liveCustomers) {
        if (liveCustomers.isNotEmpty) {
          _customers = liveCustomers;
          notifyListeners();
        }
      },
      onError: (err) {
        debugPrint("Error in live customers stream: $err");
      },
    );
  }

  @override
  void dispose() {
    _customersSubscription?.cancel();
    super.dispose();
  }

  List<CustomerModel> get customers => List.unmodifiable(_customers);
  String get searchQuery => _searchQuery;

  List<CustomerModel> get filteredCustomers {
    if (_searchQuery.isEmpty) return _customers;
    final query = _searchQuery.toLowerCase();
    return _customers.where((c) {
      return c.name.toLowerCase().contains(query) ||
          c.phone.contains(query) ||
          c.email.toLowerCase().contains(query) ||
          c.postcode.toLowerCase().contains(query);
    }).toList();
  }

  void setCustomers(List<CustomerModel> list) {
    _customers = list;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void addCustomer(CustomerModel customer) {
    _customers.add(customer);
    notifyListeners();
    DatabaseService.instance.saveDocument('customers', customer.id, customer.toMap());
  }

  void updateCustomer(CustomerModel customer) {
    final idx = _customers.indexWhere((c) => c.id == customer.id);
    if (idx != -1) {
      _customers[idx] = customer;
      notifyListeners();
      DatabaseService.instance.saveDocument('customers', customer.id, customer.toMap());
    }
  }

  void deleteCustomer(String id) {
    _customers.removeWhere((c) => c.id == id);
    notifyListeners();
    DatabaseService.instance.deleteDocument('customers', id);
  }

  void recordCustomerOrder(String customerId, double orderTotal) {
    final idx = _customers.indexWhere((c) => c.id == customerId);
    if (idx != -1) {
      final current = _customers[idx];
      final updated = current.copyWith(
        totalOrders: current.totalOrders + 1,
        totalSpent: current.totalSpent + orderTotal,
      );
      _customers[idx] = updated;
      notifyListeners();
      DatabaseService.instance.saveDocument('customers', updated.id, updated.toMap());
    }
  }
}
