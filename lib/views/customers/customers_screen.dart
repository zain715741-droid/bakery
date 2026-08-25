import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/customer_model.dart';
import '../../providers/customer_provider.dart';
import '../../providers/branding_provider.dart';

class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  void _showCustomerModal(BuildContext context, {CustomerModel? customerToEdit}) {
    final provider = Provider.of<CustomerProvider>(context, listen: false);

    final nameController = TextEditingController(text: customerToEdit?.name ?? '');
    final phoneController = TextEditingController(text: customerToEdit?.phone ?? '');
    final emailController = TextEditingController(text: customerToEdit?.email ?? '');
    final addressController = TextEditingController(text: customerToEdit?.address ?? '');
    final postcodeController = TextEditingController(text: customerToEdit?.postcode ?? '');
    final notesController = TextEditingController(text: customerToEdit?.notes ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customerToEdit == null ? "Add New Customer" : "Edit Customer Profile",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Full Name *", hintText: "e.g. John Smith", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: phoneController,
                        decoration: const InputDecoration(labelText: "Phone Number", hintText: "e.g. 07123 456789", border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: postcodeController,
                        decoration: const InputDecoration(labelText: "Postcode / Zip", border: OutlineInputBorder(), hintText: "e.g. SW1A 1AA"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: "Email Address", hintText: "customer@example.com", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: "Street Address", hintText: "123 High Street", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: "Customer Notes / Preferences", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      final name = nameController.text.trim();
                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Please enter customer name"), backgroundColor: Colors.red),
                        );
                        return;
                      }

                      final newCust = CustomerModel(
                        id: customerToEdit?.id ?? 'cust_${DateTime.now().millisecondsSinceEpoch}',
                        name: name,
                        phone: phoneController.text.trim(),
                        email: emailController.text.trim(),
                        address: addressController.text.trim(),
                        postcode: postcodeController.text.trim().toUpperCase(),
                        notes: notesController.text.trim(),
                        totalOrders: customerToEdit?.totalOrders ?? 0,
                        totalSpent: customerToEdit?.totalSpent ?? 0.0,
                      );

                      if (customerToEdit != null) {
                        provider.updateCustomer(newCust);
                      } else {
                        provider.addCustomer(newCust);
                      }

                      final messenger = ScaffoldMessenger.of(context);
                      Navigator.pop(ctx);
                      messenger.showSnackBar(
                        SnackBar(content: Text("Customer '${newCust.name}' saved successfully!"), backgroundColor: Colors.green),
                      );
                    },
                    child: const Text("Save Customer Profile"),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final customerProvider = Provider.of<CustomerProvider>(context);
    final branding = Provider.of<BrandingProvider>(context).branding;
    final primaryColor = branding.primaryColor;
    final currencyFormat = NumberFormat.currency(symbol: branding.currencySymbol, decimalDigits: 2);

    final customers = customerProvider.filteredCustomers;

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (val) => customerProvider.setSearchQuery(val),
              decoration: InputDecoration(
                hintText: "Search customer by name, phone, or postcode...",
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: customerProvider.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () => customerProvider.setSearchQuery(''),
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
          Expanded(
            child: customers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline_rounded, size: 60, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text("No customers found", style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                        const SizedBox(height: 6),
                        Text("Tap the '+ New Customer' button below to add a customer profile.", style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: customers.length,
                    itemBuilder: (context, index) {
                      final cust = customers[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: primaryColor.withValues(alpha: 0.12),
                            child: Text(
                              cust.name.isNotEmpty ? cust.name[0].toUpperCase() : 'C',
                              style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  cust.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (cust.postcode.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.brown.shade50, borderRadius: BorderRadius.circular(6)),
                                  child: Text(cust.postcode, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.brown)),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text("Phone: ${cust.phone} • Email: ${cust.email}"),
                              if (cust.address.isNotEmpty) Text("Address: ${cust.address}", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 12,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.shopping_bag_outlined, size: 14, color: primaryColor),
                                      const SizedBox(width: 4),
                                      Text("${cust.totalOrders} order(s)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor)),
                                    ],
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.payments_outlined, size: 14, color: Colors.green.shade800),
                                      const SizedBox(width: 4),
                                      Text("Total: ${currencyFormat.format(cust.totalSpent)}", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _showCustomerModal(context, customerToEdit: cust),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        onPressed: () => _showCustomerModal(context),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text("New Customer"),
      ),
    );
  }
}
