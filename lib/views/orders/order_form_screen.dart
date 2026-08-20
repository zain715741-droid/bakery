import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/order_model.dart';
import '../../models/customer_model.dart';
import '../../providers/order_provider.dart';
import '../../providers/recipe_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/branding_provider.dart';

class OrderFormScreen extends StatefulWidget {
  const OrderFormScreen({super.key});

  @override
  State<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends State<OrderFormScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedCustomerId;
  FulfillmentType _fulfillment = FulfillmentType.collection;
  PaymentStatus _paymentStatus = PaymentStatus.unpaid;
  final DateTime _targetDate = DateTime.now().add(const Duration(days: 1));

  final List<OrderItem> _orderItems = [];
  final TextEditingController _notesController = TextEditingController();

  void _addItemDialog() {
    final recipes = Provider.of<RecipeProvider>(context, listen: false).recipes;
    if (recipes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No recipes available in catalog. Add recipes first!")),
      );
      return;
    }

    String selectedRecipeId = recipes.first.id;
    final qtyController = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final recipe = recipes.firstWhere((r) => r.id == selectedRecipeId);

          return AlertDialog(
            title: const Text("Add Product to Order"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedRecipeId,
                  decoration: const InputDecoration(labelText: "Select Bakery Product"),
                  items: recipes.map((r) {
                    return DropdownMenuItem(
                      value: r.id,
                      child: Text("${r.title} (£${r.sellingPrice.toStringAsFixed(2)})"),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedRecipeId = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: qtyController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Quantity",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: () {
                  final qty = int.tryParse(qtyController.text) ?? 1;
                  if (qty > 0) {
                    setState(() {
                      _orderItems.add(
                        OrderItem(
                          recipeId: recipe.id,
                          recipeName: recipe.title,
                          quantity: qty,
                          unitPrice: recipe.sellingPrice,
                        ),
                      );
                    });
                    Navigator.pop(ctx);
                  }
                },
                child: const Text("Add Item"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _submitOrder() {
    if (_orderItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add at least 1 item to the order.")),
      );
      return;
    }

    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
    final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
    final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
    final branding = Provider.of<BrandingProvider>(context, listen: false).branding;

    CustomerModel customer;
    if (_selectedCustomerId != null) {
      customer = customerProvider.customers.firstWhere((c) => c.id == _selectedCustomerId);
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
      items: _orderItems,
      status: OrderStatus.pending,
      fulfillment: _fulfillment,
      paymentStatus: _paymentStatus,
      vatRate: branding.vatRate,
      createdAt: DateTime.now(),
      targetDate: _targetDate,
      notes: _notesController.text.trim(),
    );

    orderProvider.createOrder(
      order: newOrder,
      recipesCatalog: recipeProvider.recipes,
      inventoryProvider: inventoryProvider,
      customerProvider: customerProvider,
    );

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Order ${newOrder.invoiceNumber} created! Inventory stock updated automatically."),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final branding = Provider.of<BrandingProvider>(context).branding;
    final customers = Provider.of<CustomerProvider>(context).customers;
    final primaryColor = branding.primaryColor;
    final currencyFormat = NumberFormat.currency(symbol: branding.currencySymbol, decimalDigits: 2);

    final subtotal = _orderItems.fold(0.0, (sum, i) => sum + i.lineTotal);
    final vatAmount = subtotal * branding.vatRate;
    final total = subtotal + vatAmount;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Create New Order"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Customer Selection
              const Text("1. Select Customer", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedCustomerId,
                decoration: const InputDecoration(
                  labelText: "Customer (Optional - leave for Walk-in)",
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text("Walk-in / Counter Customer")),
                  ...customers.map((c) => DropdownMenuItem(value: c.id, child: Text("${c.name} (${c.postcode})"))),
                ],
                onChanged: (val) => setState(() => _selectedCustomerId = val),
              ),
              const SizedBox(height: 20),

              // Product Items List
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("2. Order Items", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ElevatedButton.icon(
                    onPressed: _addItemDialog,
                    icon: const Icon(Icons.add_shopping_cart, size: 18),
                    label: const Text("Add Product"),
                    style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_orderItems.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                  child: const Center(child: Text("No items added yet. Tap 'Add Product' to select recipes.")),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _orderItems.length,
                  itemBuilder: (context, idx) {
                    final item = _orderItems[idx];
                    return Card(
                      child: ListTile(
                        title: Text(item.recipeName),
                        subtitle: Text("${item.quantity} x ${currencyFormat.format(item.unitPrice)}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(currencyFormat.format(item.lineTotal), style: const TextStyle(fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => setState(() => _orderItems.removeAt(idx)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 20),

              // Fulfillment & Payment details
              const Text("3. Fulfillment & Payment", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<FulfillmentType>(
                      initialValue: _fulfillment,
                      decoration: const InputDecoration(labelText: "Fulfillment", border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: FulfillmentType.collection, child: Text("Customer Collection")),
                        DropdownMenuItem(value: FulfillmentType.delivery, child: Text("Local Delivery")),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _fulfillment = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<PaymentStatus>(
                      initialValue: _paymentStatus,
                      decoration: const InputDecoration(labelText: "Payment Status", border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: PaymentStatus.unpaid, child: Text("Unpaid")),
                        DropdownMenuItem(value: PaymentStatus.paid, child: Text("Paid")),
                        DropdownMenuItem(value: PaymentStatus.partiallyPaid, child: Text("Partially Paid")),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _paymentStatus = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: "Order Notes / Customization Requests", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),

              // Calculation Summary Box
              Card(
                color: Colors.brown.shade50,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Subtotal:"),
                          Text(currencyFormat.format(subtotal)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("VAT (${(branding.vatRate * 100).toInt()}%):"),
                          Text(currencyFormat.format(vatAmount)),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("TOTAL AMOUNT DUE:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(currencyFormat.format(total), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: primaryColor)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submitOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Confirm & Create Order", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
