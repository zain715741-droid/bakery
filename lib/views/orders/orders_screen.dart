import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../controllers/order_form_controller.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import '../../providers/branding_provider.dart';
import '../widgets/role_guard.dart';
import 'order_form_screen.dart';
import 'invoice_preview_screen.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<OrderProvider, BrandingProvider>(
      builder: (context, orderProvider, brandingProvider, _) {
        final branding = brandingProvider.branding;
        final primaryColor = branding.primaryColor;
        final currencyFormat = NumberFormat.currency(symbol: branding.currencySymbol, decimalDigits: 2);
        final dateFormat = DateFormat('dd MMM yyyy, HH:mm');

        final orders = orderProvider.filteredOrders;

        return Scaffold(
          backgroundColor: const Color(0xFFFDFBF7),
          body: Column(
            children: [
              // Search & Status Filters
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  onChanged: (val) => orderProvider.setSearchQuery(val),
                  decoration: InputDecoration(
                    hintText: "Search order by invoice #, customer, or postcode...",
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: orderProvider.searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () => orderProvider.setSearchQuery(''),
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _buildStatusChip(null, "All Orders", orderProvider, primaryColor),
                    _buildStatusChip(OrderStatus.pending, "Pending", orderProvider, primaryColor),
                    _buildStatusChip(OrderStatus.baking, "Baking", orderProvider, primaryColor),
                    _buildStatusChip(OrderStatus.ready, "Ready", orderProvider, primaryColor),
                    _buildStatusChip(OrderStatus.completed, "Completed", orderProvider, primaryColor),
                    _buildStatusChip(OrderStatus.cancelled, "Cancelled", orderProvider, primaryColor),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Orders List
              Expanded(
                child: orders.isEmpty
                    ? Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long_outlined, size: 64, color: Colors.brown.shade300),
                              const SizedBox(height: 14),
                              Text(
                                "No Orders in View",
                                style: TextStyle(color: primaryColor, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                orderProvider.searchQuery.isNotEmpty || orderProvider.selectedStatusFilter != null
                                    ? "No orders match your filter criteria."
                                    : "Ready to take customer orders? Create your first bakery order below!",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                              ),
                              const SizedBox(height: 18),
                              ElevatedButton.icon(
                                onPressed: () {
                                  final formCtrl = Get.isRegistered<OrderFormController>()
                                      ? Get.find<OrderFormController>()
                                      : Get.put(OrderFormController());
                                  formCtrl.resetForm();
                                  Get.to(() => const OrderFormScreen());
                                },
                                icon: const Icon(Icons.add_shopping_cart, size: 18),
                                label: const Text("Create First Order"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          final order = orders[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Invoice # & Status Badge
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    order.invoiceNumber,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  PopupMenuButton<OrderStatus>(
                                    initialValue: order.status,
                                    onSelected: (newStatus) {
                                      orderProvider.updateOrderStatus(order.id, newStatus);
                                    },
                                    child: Chip(
                                      label: Text(
                                        order.status.displayName,
                                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                      backgroundColor: _getStatusColor(order.status),
                                    ),
                                    itemBuilder: (context) => OrderStatus.values.map((status) {
                                      return PopupMenuItem(
                                        value: status,
                                        child: Text(status.displayName),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text("Customer: ${order.customerName} (${order.customerPostcode})", style: const TextStyle(fontWeight: FontWeight.w600)),
                              Text("Created: ${dateFormat.format(order.createdAt)}", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                              const SizedBox(height: 10),

                              // Items Summary
                              Text(
                                "Items: ${order.items.map((i) => '${i.quantity}x ${i.recipeName}').join(', ')}",
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 12),
                              const Divider(height: 1),
                              const SizedBox(height: 8),

                              // Amount & Actions
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            "Total: ${currencyFormat.format(order.totalAmount)}",
                                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            final nextPayment = order.paymentStatus == PaymentStatus.paid ? PaymentStatus.unpaid : PaymentStatus.paid;
                                            orderProvider.updatePaymentStatus(order.id, nextPayment);
                                          },
                                          child: Text(
                                            "Payment: ${order.paymentStatus.name.toUpperCase()}",
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: order.paymentStatus == PaymentStatus.paid ? Colors.green.shade800 : Colors.red.shade800,
                                              decoration: TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => InvoicePreviewScreen(order: order, branding: branding),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 15),
                                    label: const Text("Invoice", style: TextStyle(fontSize: 12)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.brown.shade800,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: RoleGuard(
        canAccess: (auth) => auth.permissions.canCreateOrders,
        child: FloatingActionButton.extended(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          onPressed: () {
            final formCtrl = Get.isRegistered<OrderFormController>()
                ? Get.find<OrderFormController>()
                : Get.put(OrderFormController());
            formCtrl.resetForm();
            Get.to(() => const OrderFormScreen());
          },
          icon: const Icon(Icons.add_shopping_cart),
          label: const Text("New Order"),
        ),
      ),
    );
      },
    );
  }

  Widget _buildStatusChip(OrderStatus? status, String label, OrderProvider provider, Color primaryColor) {
    final isSelected = provider.selectedStatusFilter == status;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: primaryColor,
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        onSelected: (selected) {
          provider.setStatusFilter(selected ? status : null);
        },
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.baking:
        return Colors.brown;
      case OrderStatus.ready:
        return Colors.blue;
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }
}
