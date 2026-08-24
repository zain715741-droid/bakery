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
  final selectedCustomerId = RxnString();
  final fulfillment = FulfillmentType.collection.obs;
  final paymentStatus = PaymentStatus.unpaid.obs;
  final targetDate = DateTime.now().add(const Duration(days: 1)).obs;
  final orderItems = <OrderItem>[].obs;
  final notesController = TextEditingController();

  @override
  void onClose() {
    notesController.dispose();
    super.dispose();
  }

  void resetForm() {
    selectedCustomerId.value = null;
    fulfillment.value = FulfillmentType.collection;
    paymentStatus.value = PaymentStatus.unpaid;
    targetDate.value = DateTime.now().add(const Duration(days: 1));
    orderItems.clear();
    notesController.text = '';
  }

  void addItemDialog() {
    final recipes = Get.find<RecipeProvider>().recipes;
    if (recipes.isEmpty) {
      Get.snackbar("Catalog Empty", "No recipes available. Add recipes first!", backgroundColor: Colors.brown, colorText: Colors.white);
      return;
    }

    final selectedRecipeId = recipes.first.id.obs;
    final qtyController = TextEditingController(text: '1');

    Get.dialog(
      AlertDialog(
        title: const Text("Add Product to Order"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(() => DropdownButtonFormField<String>(
                  initialValue: selectedRecipeId.value,
                  decoration: const InputDecoration(labelText: "Select Bakery Product"),
                  items: recipes.map((r) => DropdownMenuItem(value: r.id, child: Text("${r.title} (£${r.sellingPrice.toStringAsFixed(2)})"))).toList(),
                  onChanged: (val) {
                    if (val != null) selectedRecipeId.value = val;
                  },
                )),
            const SizedBox(height: 12),
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Quantity", border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final qty = int.tryParse(qtyController.text) ?? 1;
              if (qty > 0) {
                final recipe = recipes.firstWhere((r) => r.id == selectedRecipeId.value);
                orderItems.add(
                  OrderItem(
                    recipeId: recipe.id,
                    recipeName: recipe.title,
                    quantity: qty,
                    unitPrice: recipe.sellingPrice,
                  ),
                );
                Get.back();
              }
            },
            child: const Text("Add Item"),
          ),
        ],
      ),
    );
  }

  void submitOrder() {
    if (orderItems.isEmpty) {
      Get.snackbar("Missing Items", "Please add at least 1 item to the order.", backgroundColor: Colors.orange.shade900, colorText: Colors.white);
      return;
    }

    final orderProvider = Get.find<OrderProvider>();
    final customerProvider = Get.find<CustomerProvider>();
    final recipeProvider = Get.find<RecipeProvider>();
    final inventoryProvider = Get.find<InventoryProvider>();
    final branding = Get.find<BrandingProvider>().branding;

    CustomerModel customer;
    if (selectedCustomerId.value != null) {
      customer = customerProvider.customers.firstWhere((c) => c.id == selectedCustomerId.value);
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

    final newOrder = OrderModel(
      id: 'ord_${DateTime.now().millisecondsSinceEpoch}',
      invoiceNumber: orderProvider.generateNextInvoiceNumber(),
      customerId: customer.id,
      customerName: customer.name,
      customerPhone: customer.phone,
      customerAddress: customer.address,
      customerPostcode: customer.postcode,
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

    Get.back();
    Get.snackbar(
      "Order Created",
      "Order ${newOrder.invoiceNumber} created! Inventory stock updated automatically.",
      backgroundColor: Colors.green.shade800,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
    );
  }
}
