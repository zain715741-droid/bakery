// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../controllers/order_form_controller.dart';
import '../../models/order_model.dart';
import '../../providers/customer_provider.dart';
import '../../providers/branding_provider.dart';
import '../../providers/recipe_provider.dart';
import 'package:latlong2/latlong.dart';
import '../widgets/location_picker_dialog.dart';

class OrderFormScreen extends StatelessWidget {
  const OrderFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<OrderFormController>()
        ? Get.find<OrderFormController>()
        : Get.put(OrderFormController());
    final branding = Provider.of<BrandingProvider>(context).branding;
    final customerProvider = Provider.of<CustomerProvider>(context);
    final customers = customerProvider.customers;
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
                  key: const ValueKey('order_customer_select'),
                  value: controller.selectedCustomerId.value,
                  decoration: const InputDecoration(labelText: "Customer (Optional)", border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem<String>(value: 'walk_in', child: Text("Walk-in / Counter Customer")),
                    ...customers.map((c) => DropdownMenuItem<String>(value: c.id, child: Text("${c.name} (${c.postcode})"))),
                  ],
                  onChanged: (val) {
                    if (val != null) controller.selectedCustomerId.value = val;
                  },
                )),
            const SizedBox(height: 20),

            // Order Items Table
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("2. Order Items", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: () async {
                    final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
                    final item = await showDialog<OrderItem>(
                      context: context,
                      builder: (ctx) => AddProductDialog(recipes: recipeProvider.recipes),
                    );
                    if (item != null) {
                      controller.orderItems.add(item);
                    }
                  },
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
                        value: controller.fulfillment.value,
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
                        value: controller.paymentStatus.value,
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
            const SizedBox(height: 12),

            // Delivery Map Picker for Local Delivery
            Obx(() {
              if (controller.fulfillment.value == FulfillmentType.delivery) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.brown.shade50.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.delivery_dining_rounded, color: primaryColor, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            "Delivery Destination & GPS Pin",
                            style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: controller.addressController,
                              decoration: const InputDecoration(
                                labelText: "Delivery Street Address",
                                hintText: "e.g. House 12, Main Boulevard",
                                prefixIcon: Icon(Icons.location_city_outlined, size: 18),
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 1,
                            child: TextField(
                              controller: controller.postcodeController,
                              decoration: const InputDecoration(
                                labelText: "Postcode",
                                hintText: "54000",
                                prefixIcon: Icon(Icons.pin_drop_outlined, size: 18),
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final result = await showDialog<Map<String, dynamic>>(
                              context: context,
                              builder: (_) => LocationPickerDialog(
                                initialLocation: LatLng(
                                  controller.deliveryLatitude.value ?? 31.5204,
                                  controller.deliveryLongitude.value ?? 74.3587,
                                ),
                                initialAddress: controller.addressController.text,
                                initialPostcode: controller.postcodeController.text,
                                primaryColor: primaryColor,
                                accentColor: branding.accentColor,
                              ),
                            );
                            if (result != null) {
                              final LatLng latLng = result['latLng'];
                              final String addr = result['address'] ?? '';
                              final String postcode = result['postcode'] ?? '';
                              controller.setDeliveryCoordinates(
                                latLng.latitude,
                                latLng.longitude,
                                formattedAddress: addr,
                                postcode: postcode,
                              );
                            }
                          },
                          icon: const Icon(Icons.pin_drop_rounded, size: 18),
                          label: Text(
                            controller.deliveryLatitude.value != null
                                ? "📍 Pinned: (${controller.deliveryLatitude.value!.toStringAsFixed(4)}, ${controller.deliveryLongitude.value!.toStringAsFixed(4)}) - Tap to Change"
                                : "📍 Open Live Map & Search Address",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryColor,
                            side: BorderSide(color: primaryColor),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            }),

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
                onPressed: () => controller.submitOrder(context),
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

class AddProductDialog extends StatefulWidget {
  final List<dynamic> recipes;

  const AddProductDialog({super.key, required this.recipes});

  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  late bool _isCustom;
  String? _selectedRecipeId;
  late final TextEditingController _customNameController;
  late final TextEditingController _customPriceController;
  late final TextEditingController _qtyController;

  @override
  void initState() {
    super.initState();
    _isCustom = widget.recipes.isEmpty;
    _selectedRecipeId = widget.recipes.isNotEmpty ? widget.recipes.first.id : null;
    _customNameController = TextEditingController();
    _customPriceController = TextEditingController(text: '3.50');
    _qtyController = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _customNameController.dispose();
    _customPriceController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  void _submit() {
    final qty = int.tryParse(_qtyController.text) ?? 1;
    if (qty <= 0) return;

    if (!_isCustom && widget.recipes.isNotEmpty && _selectedRecipeId != null) {
      final recipe = widget.recipes.firstWhere((r) => r.id == _selectedRecipeId, orElse: () => widget.recipes.first);
      Navigator.pop(
        context,
        OrderItem(
          recipeId: recipe.id,
          recipeName: recipe.title,
          quantity: qty,
          unitPrice: recipe.sellingPrice,
        ),
      );
    } else {
      final name = _customNameController.text.trim();
      if (name.isEmpty) return;
      final price = double.tryParse(_customPriceController.text) ?? 3.50;

      Navigator.pop(
        context,
        OrderItem(
          recipeId: 'custom_${DateTime.now().millisecondsSinceEpoch}',
          recipeName: name,
          quantity: qty,
          unitPrice: price,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Add Product to Order"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.recipes.isNotEmpty) ...[
              Row(
                children: [
                  ChoiceChip(
                    label: const Text("From Catalog"),
                    selected: !_isCustom,
                    onSelected: (val) => setState(() => _isCustom = !val),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text("Custom Item"),
                    selected: _isCustom,
                    onSelected: (val) => setState(() => _isCustom = val),
                  ),
                ],
              ),
              const SizedBox(height: 14),
            ],
            if (!_isCustom && widget.recipes.isNotEmpty) ...[
              DropdownButtonFormField<String>(
                key: const ValueKey('catalog_dropdown'),
                initialValue: _selectedRecipeId,
                decoration: const InputDecoration(labelText: "Select Bakery Product", border: OutlineInputBorder()),
                items: widget.recipes.map((r) => DropdownMenuItem<String>(value: r.id as String, child: Text("${r.title} (£${r.sellingPrice.toStringAsFixed(2)})"))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedRecipeId = val);
                },
              ),
              const SizedBox(height: 12),
            ] else ...[
              TextField(
                key: const ValueKey('custom_name_field'),
                controller: _customNameController,
                decoration: const InputDecoration(labelText: "Product Name *", hintText: "e.g. Sourdough Loaf", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                key: const ValueKey('custom_price_field'),
                controller: _customPriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Unit Price (£) *", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _qtyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Quantity", border: OutlineInputBorder()),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(onPressed: _submit, child: const Text("Add Item")),
      ],
    );
  }
}
