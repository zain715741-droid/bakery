import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../controllers/order_form_controller.dart';
import '../../models/order_model.dart';
import '../../providers/customer_provider.dart';
import '../../providers/branding_provider.dart';

class OrderFormScreen extends StatelessWidget {
  const OrderFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<OrderFormController>()
        ? Get.find<OrderFormController>()
        : Get.put(OrderFormController());
    final branding = Get.find<BrandingProvider>().branding;
    final customers = Get.find<CustomerProvider>().customers;
    final primaryColor = branding.primaryColor;
    final currencyFormat = NumberFormat.currency(symbol: branding.currencySymbol, decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Create New Order"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer Selection
            const Text("1. Select Customer", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Obx(() => DropdownButtonFormField<String>(
                  initialValue: controller.selectedCustomerId.value,
                  decoration: const InputDecoration(labelText: "Customer (Optional - leave for Walk-in)", border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem(value: null, child: Text("Walk-in / Counter Customer")),
                    ...customers.map((c) => DropdownMenuItem(value: c.id, child: Text("${c.name} (${c.postcode})"))),
                  ],
                  onChanged: (val) => controller.selectedCustomerId.value = val,
                )),
            const SizedBox(height: 20),

            // Order Items Table
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("2. Order Items", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: controller.addItemDialog,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text("Add Product"),
                  style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Obx(() {
              if (controller.orderItems.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                  child: const Center(child: Text("No items added yet. Click 'Add Product' above.")),
                );
              }

              return Column(
                children: [
                  ...controller.orderItems.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(item.recipeName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("${item.quantity}x @ ${currencyFormat.format(item.unitPrice)} each"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(currencyFormat.format(item.lineTotal), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => controller.orderItems.removeAt(index),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              );
            }),
            const SizedBox(height: 20),

            // Logistics & Status
            const Text("3. Logistics & Fulfillment", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Obx(() => DropdownButtonFormField<FulfillmentType>(
                        initialValue: controller.fulfillment.value,
                        decoration: const InputDecoration(labelText: "Fulfillment", border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: FulfillmentType.collection, child: Text("Collection")),
                          DropdownMenuItem(value: FulfillmentType.delivery, child: Text("Local Delivery")),
                        ],
                        onChanged: (val) {
                          if (val != null) controller.fulfillment.value = val;
                        },
                      )),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Obx(() => DropdownButtonFormField<PaymentStatus>(
                        initialValue: controller.paymentStatus.value,
                        decoration: const InputDecoration(labelText: "Payment", border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: PaymentStatus.unpaid, child: Text("Unpaid (Invoice)")),
                          DropdownMenuItem(value: PaymentStatus.paid, child: Text("Paid (Cash/Card)")),
                        ],
                        onChanged: (val) {
                          if (val != null) controller.paymentStatus.value = val;
                        },
                      )),
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextField(
              controller: controller.notesController,
              decoration: const InputDecoration(labelText: "Order Notes / Dietary Instructions", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),

            // Summary Totals
            Obx(() {
              final subtotal = controller.orderItems.fold(0.0, (sum, i) => sum + i.lineTotal);
              final vat = subtotal * branding.vatRate;
              final total = subtotal + vat;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.brown.shade50, borderRadius: BorderRadius.circular(14)),
                child: Column(
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Subtotal:"), Text(currencyFormat.format(subtotal))]),
                    const SizedBox(height: 4),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("UK VAT (${(branding.vatRate * 100).toInt()}%):"), Text(currencyFormat.format(vat))]),
                    const Divider(),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text("Grand Total:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(currencyFormat.format(total), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: primaryColor)),
                    ]),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: controller.submitOrder,
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text("Confirm & Submit Order", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
