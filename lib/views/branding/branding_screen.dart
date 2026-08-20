import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/branding_provider.dart';
import '../widgets/role_guard.dart';

class BrandingScreen extends StatefulWidget {
  const BrandingScreen({super.key});

  @override
  State<BrandingScreen> createState() => _BrandingScreenState();
}

class _BrandingScreenState extends State<BrandingScreen> {
  late TextEditingController _businessNameController;
  late TextEditingController _ownerNameController;
  late TextEditingController _welcomeController;
  late TextEditingController _currencyController;
  late TextEditingController _vatController;

  final List<Map<String, dynamic>> _themePalettes = [
    {'name': 'Warm Amber (Default)', 'primary': 0xFF8D6E63, 'accent': 0xFFD81B60},
    {'name': 'Espresso & Gold', 'primary': 0xFF4A2E2B, 'accent': 0xFFD99B26},
    {'name': 'Rose Artisan', 'primary': 0xFFAD1457, 'accent': 0xFF7B1FA2},
    {'name': 'Emerald Organic', 'primary': 0xFF2E7D32, 'accent': 0xFF1565C0},
  ];

  @override
  void initState() {
    super.initState();
    final branding = Provider.of<BrandingProvider>(context, listen: false).branding;
    _businessNameController = TextEditingController(text: branding.businessName);
    _ownerNameController = TextEditingController(text: branding.ownerName);
    _welcomeController = TextEditingController(text: branding.welcomeMessage);
    _currencyController = TextEditingController(text: branding.currencySymbol);
    _vatController = TextEditingController(text: (branding.vatRate * 100).toStringAsFixed(0));
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _ownerNameController.dispose();
    _welcomeController.dispose();
    _currencyController.dispose();
    _vatController.dispose();
    super.dispose();
  }

  void _saveBranding() {
    final provider = Provider.of<BrandingProvider>(context, listen: false);

    final vatPercent = double.tryParse(_vatController.text) ?? 20.0;

    final updated = provider.branding.copyWith(
      businessName: _businessNameController.text.trim(),
      ownerName: _ownerNameController.text.trim(),
      welcomeMessage: _welcomeController.text.trim(),
      currencySymbol: _currencyController.text.trim(),
      vatRate: vatPercent / 100.0,
    );

    provider.updateBranding(updated);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Branding settings updated globally!"), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brandingProvider = Provider.of<BrandingProvider>(context);
    final branding = brandingProvider.branding;
    final primaryColor = branding.primaryColor;

    return RoleGuard(
      canAccess: (auth) => auth.permissions.canEditBranding,
      fallback: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline_rounded, size: 60, color: Colors.grey),
              const SizedBox(height: 12),
              const Text("Branding Customization Restricted", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text("Only the Bakery Owner can edit business branding.", style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFDFBF7),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Live Branding Preview Header
              Card(
                color: primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white24,
                        child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              branding.businessName,
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text("Owner: ${branding.ownerName}", style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12)),
                            Text(branding.welcomeMessage, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11, fontStyle: FontStyle.italic)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              const Text("Business Identity & Taglines", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextField(
                controller: _businessNameController,
                decoration: const InputDecoration(labelText: "Bakery Business Name", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _ownerNameController,
                decoration: const InputDecoration(labelText: "Owner Name", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _welcomeController,
                decoration: const InputDecoration(labelText: "Welcome Tagline / Motto", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),

              const Text("Theme Color Presets", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _themePalettes.map((p) {
                  final isSelected = branding.primaryColorValue == p['primary'];
                  return ChoiceChip(
                    avatar: CircleAvatar(backgroundColor: Color(p['primary']), radius: 8),
                    label: Text(p['name']),
                    selected: isSelected,
                    selectedColor: Color(p['primary']),
                    labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                    onSelected: (selected) {
                      if (selected) {
                        brandingProvider.updateColors(
                          primaryColor: p['primary'],
                          accentColor: p['accent'],
                        );
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              const Text("Currency & Tax Configuration", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _currencyController,
                      decoration: const InputDecoration(labelText: "Currency Symbol", border: OutlineInputBorder(), hintText: "£"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _vatController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "UK VAT Rate (%)", border: OutlineInputBorder(), hintText: "20"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveBranding,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Save Branding Settings", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
