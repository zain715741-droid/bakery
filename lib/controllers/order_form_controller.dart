import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/order_model.dart';
import '../models/customer_model.dart';
import '../providers/order_provider.dart';
import '../providers/recipe_provider.dart';
import '../providers/customer_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/branding_provider.dart';

class OrderFormController extends GetxController {
  final selectedCustomerId = 'walk_in'.obs;
  final fulfillment = FulfillmentType.collection.obs;
  final paymentStatus = PaymentStatus.unpaid.obs;
  final targetDate = DateTime.now().add(const Duration(days: 1)).obs;
  final orderItems = <OrderItem>[].obs;
  final notesController = TextEditingController();
  final addressController = TextEditingController();
  final postcodeController = TextEditingController();

  final Rx<double?> deliveryLatitude = Rx<double?>(null);
  final Rx<double?> deliveryLongitude = Rx<double?>(null);

  void resetForm() {
    selectedCustomerId.value = 'walk_in';
    fulfillment.value = FulfillmentType.collection;
    paymentStatus.value = PaymentStatus.unpaid;
    targetDate.value = DateTime.now().add(const Duration(days: 1));
    orderItems.clear();
    notesController.text = '';
    addressController.text = '';
    postcodeController.text = '';
    deliveryLatitude.value = null;
    deliveryLongitude.value = null;
  }

  void setDeliveryCoordinates(double lat, double lng, {String? formattedAddress, String? postcode}) {
    deliveryLatitude.value = lat;
    deliveryLongitude.value = lng;
    if (formattedAddress != null && formattedAddress.isNotEmpty) {
      addressController.text = formattedAddress;
    }
    if (postcode != null && postcode.isNotEmpty) {
      postcodeController.text = postcode;
    }
  }

  void submitOrder(BuildContext context) {
    if (orderItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please add at least 1 item to the order."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final orderProvider = Get.find<OrderProvider>();
    final customerProvider = Get.find<CustomerProvider>();
    final recipeProvider = Get.find<RecipeProvider>();
    final inventoryProvider = Get.find<InventoryProvider>();
    final branding = Get.find<BrandingProvider>().branding;

    CustomerModel customer;
    if (selectedCustomerId.value != 'walk_in' && selectedCustomerId.value.isNotEmpty) {
      customer = customerProvider.customers.firstWhere(
        (c) => c.id == selectedCustomerId.value,
        orElse: () => CustomerModel(
          id: 'guest_cust',
          name: 'Counter / Walk-in Customer',
          phone: '',
          email: '',
          address: 'Bakery Storefront',
          postcode: 'STORE',
        ),
      );
    } else {
      customer = CustomerModel(
        id: 'guest_cust',
        name: 'Counter / Walk-in Customer',
        phone: '',
        email: '',
        address: 'Bakery Storefront',
        postcode: 'STORE',
      );
    }

    final deliveryAddr = addressController.text.trim().isNotEmpty
        ? addressController.text.trim()
        : customer.address;
    final deliveryPost = postcodeController.text.trim().isNotEmpty
        ? postcodeController.text.trim()
        : customer.postcode;

    final newOrder = OrderModel(
      id: 'ord_${DateTime.now().millisecondsSinceEpoch}',
      invoiceNumber: orderProvider.generateNextInvoiceNumber(),
      customerId: customer.id,
      customerName: customer.name,
      customerPhone: customer.phone,
      customerAddress: deliveryAddr,
      customerPostcode: deliveryPost,
      latitude: deliveryLatitude.value,
      longitude: deliveryLongitude.value,
      items: List.from(orderItems),
      status: OrderStatus.pending,
      fulfillment: fulfillment.value,
      paymentStatus: paymentStatus.value,
      vatRate: branding.vatRate,
      createdAt: DateTime.now(),
      targetDate: targetDate.value,
      notes: notesController.text.trim(),
    );

    orderProvider.createOrder(
      order: newOrder,
      recipesCatalog: recipeProvider.recipes,
      inventoryProvider: inventoryProvider,
      customerProvider: customerProvider,
    );

    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text("Order ${newOrder.invoiceNumber} created successfully!"),
        backgroundColor: Colors.green.shade800,
      ),
    );
  }
}
