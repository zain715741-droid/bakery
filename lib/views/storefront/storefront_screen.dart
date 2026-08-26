import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';

import '../../controllers/storefront_controller.dart';
import '../../models/order_model.dart';
import '../../models/recipe_model.dart';
import '../../providers/branding_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/recipe_provider.dart';
import '../auth/login_screen.dart';
import '../widgets/location_picker_dialog.dart';
import '../widgets/delivery_tracking_map_dialog.dart';

class StorefrontScreen extends StatefulWidget {
  const StorefrontScreen({super.key});

  @override
  State<StorefrontScreen> createState() => _StorefrontScreenState();
}

class _StorefrontScreenState extends State<StorefrontScreen> {
  late final StorefrontController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<StorefrontController>()
        ? Get.find<StorefrontController>()
        : Get.put(StorefrontController(), permanent: true);
  }

  @override
  Widget build(BuildContext context) {
    final bp = Provider.of<BrandingProvider>(context);
    final rp = Provider.of<RecipeProvider>(context);
    final op = Provider.of<OrderProvider>(context);
    final ip = Provider.of<InventoryProvider>(context);
    final cp = Provider.of<CustomerProvider>(context);
    final branding = bp.branding;
    final primary = branding.primaryColor;
    final accent = branding.accentColor;
    final money = NumberFormat.currency(
      symbol: branding.currencySymbol,
      decimalDigits: 2,
    );
    final categories = ['All', ...rp.categories];

    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE6),
      body: Stack(
        children: [
          // Ambient luxury background glow
          Positioned(
            top: 150,
            right: -120,
            child: _ambientGlow(360, accent, 0.08),
          ),
          Positioned(
            bottom: 100,
            left: -140,
            child: _ambientGlow(400, const Color(0xFFD9B98C), 0.14),
          ),

          Obx(() {
            final recipes = controller.getFilteredRecipes(rp.recipes);
            final selected = controller.selectedCategory.value;

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Luxury Pinned Top Navigation Bar
                SliverAppBar(
                  pinned: true,
                  elevation: 0,
                  backgroundColor: const Color(0xFF2C1810),
                  toolbarHeight: 76,
                  titleSpacing: 16,
                  title: Row(
                    children: [
                      Container(
                        height: 44,
                        width: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFFF6D77A),
                              accent,
                              Color.alphaBlend(Colors.black12, accent),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF2C1810),
                          ),
                          child: const Icon(
                            Icons.bakery_dining_rounded,
                            color: Color(0xFFD4AF37),
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              branding.businessName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.playfairDisplay(
                                color: const Color(0xFFFFFCF7),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              branding.welcomeMessage.isNotEmpty
                                  ? branding.welcomeMessage
                                  : 'Artisanal bakes, freshly crafted daily',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                color: const Color(0xFFD9B98C),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    _headerAction(
                      icon: Icons.pin_drop_outlined,
                      label: 'Map',
                      color: accent,
                      onTap: () async {
                        final result = await showDialog<Map<String, dynamic>>(
                          context: context,
                          builder: (_) => LocationPickerDialog(
                            initialLocation: LatLng(
                              controller.deliveryLatitude.value ?? 31.5204,
                              controller.deliveryLongitude.value ?? 74.3587,
                            ),
                            initialAddress: controller.addressController.text,
                            initialPostcode: controller.postcodeController.text,
                            primaryColor: primary,
                            accentColor: accent,
                          ),
                        );
                        if (result != null) {
                          final LatLng point = result['latLng'];
                          final String address = result['address'] ?? '';
                          final String postcode = result['postcode'] ?? '';
                          if (postcode.isNotEmpty) {
                            controller.postcodeController.text = postcode;
                          }
                          controller.setDeliveryCoordinates(
                            point.latitude,
                            point.longitude,
                            formattedAddress: address,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('📍 Delivery pin set: $address'),
                                backgroundColor: const Color(0xFF2C1810),
                              ),
                            );
                          }
                        }
                      },
                    ),
                    _headerAction(
                      icon: Icons.local_shipping_outlined,
                      label: 'Track',
                      color: const Color(0xFFFFFCF7),
                      onTap: () =>
                          _showOrderTrackingSheet(context, op, branding),
                    ),
                    IconButton(
                      tooltip: 'Staff Portal',
                      onPressed: () => Get.to(() => const LoginScreen()),
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: accent.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Icon(
                          Icons.admin_panel_settings_outlined,
                          color: accent,
                          size: 17,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 12, left: 4),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          IconButton(
                            onPressed: () => _showCartCheckoutSheet(
                              context,
                              orderProvider: op,
                              inventoryProvider: ip,
                              customerProvider: cp,
                              recipeProvider: rp,
                              branding: branding,
                            ),
                            icon: const Icon(
                              Icons.shopping_bag_outlined,
                              color: Color(0xFFFFFCF7),
                              size: 24,
                            ),
                          ),
                          if (controller.totalCartItemCount > 0)
                            Positioned(
                              right: 4,
                              top: 6,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                constraints: const BoxConstraints(
                                  minWidth: 19,
                                  minHeight: 19,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [const Color(0xFFF0CE72), accent],
                                  ),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF2C1810),
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '${controller.totalCartItemCount}',
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFF2C1810),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Hero Banner with Luxury Gold Theme
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF2C1810),
                          Color.alphaBlend(
                            Colors.black38,
                            const Color(0xFF2C1810),
                          ),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.4),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2C1810)
                              .withValues(alpha: 0.25),
                          blurRadius: 28,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [const Color(0xFFF0CE72), accent],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.auto_awesome,
                                    size: 12,
                                    color: Color(0xFF2C1810),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'ARTISAN BAKES',
                                    style: GoogleFonts.outfit(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.2,
                                      color: const Color(0xFF2C1810),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.schedule_rounded,
                              size: 14,
                              color: Color(0xFFD4AF37),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '07:00 - 19:00',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFFD9B98C),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Made Fresh.\nMade For You.',
                          style: GoogleFonts.playfairDisplay(
                            color: const Color(0xFFFFFCF7),
                            fontSize: 30,
                            height: 1.1,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Handcrafted breads, delicate pastries and gourmet cakes prepared with master heritage techniques.',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFE2D3BF),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFCF7),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFE2D3BF),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: controller.searchController,
                            onChanged: controller.updateSearch,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: const Color(0xFF2C1810),
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText:
                                  'Search sourdough, cakes, croissants...',
                              hintStyle: GoogleFonts.outfit(
                                color: const Color(0xFFAA9B8F),
                                fontSize: 12,
                              ),
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                color: Color(0xFFA67C1E),
                                size: 20,
                              ),
                              suffixIcon:
                                  controller.searchQuery.value.isNotEmpty
                                  ? IconButton(
                                      onPressed: controller.clearSearch,
                                      icon: const Icon(
                                        Icons.close_rounded,
                                        size: 18,
                                        color: Color(0xFFA67C1E),
                                      ),
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Menu Section Heading
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
                    child: Row(
                      children: [
                        Text(
                          'Explore Collection',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2C1810),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5EEE4),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE3D6C6)),
                          ),
                          child: Text(
                            '${recipes.length} Available',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFA67C1E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Category Chips Selector
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 48,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      itemBuilder: (_, i) {
                        final cat = categories[i];
                        final active =
                            selected.toLowerCase() == cat.toLowerCase();

                        return GestureDetector(
                          onTap: () => controller.setCategory(cat),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 8, bottom: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              gradient: active
                                  ? LinearGradient(
                                      colors: [const Color(0xFFF0CE72), accent],
                                    )
                                  : null,
                              color: active ? null : const Color(0xFFFFFCF7),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: active
                                    ? accent
                                    : const Color(0xFFE2D3BF),
                              ),
                              boxShadow: active
                                  ? [
                                      BoxShadow(
                                        color: accent.withValues(alpha: 0.25),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                cat,
                                style: GoogleFonts.outfit(
                                  color: active
                                      ? const Color(0xFF2C1810)
                                      : const Color(0xFF806F63),
                                  fontSize: 12,
                                  fontWeight: active
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Recipe Cards Grid
                if (recipes.isEmpty)
                  SliverToBoxAdapter(child: _emptyState(primary, accent))
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 360,
                            mainAxisExtent: 335,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                          ),
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _buildProductCard(
                          context,
                          recipe: recipes[i],
                          primaryColor: primary,
                          accentColor: accent,
                          currencyFormat: money,
                          inventoryProvider: ip,
                          customerProvider: cp,
                          orderProvider: op,
                          recipeProvider: rp,
                          branding: branding,
                        ),
                        childCount: recipes.length,
                      ),
                    ),
                  ),
              ],
            );
          }),

          // Floating Persistent Bottom Cart Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Obx(() {
              final count = controller.totalCartItemCount;
              if (count == 0) return const SizedBox.shrink();

              return SafeArea(
                top: false,
                child: Container(
                  margin: const EdgeInsets.all(14),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C1810),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.4),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        height: 42,
                        width: 42,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [const Color(0xFFF0CE72), accent],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            '$count',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: const Color(0xFF2C1810),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              money.format(controller.grandTotal),
                              style: GoogleFonts.outfit(
                                color: const Color(0xFFFFFCF7),
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Including VAT • Ready for checkout',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFFD9B98C),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _showCartCheckoutSheet(
                          context,
                          orderProvider: op,
                          inventoryProvider: ip,
                          customerProvider: cp,
                          recipeProvider: rp,
                          branding: branding,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: const Color(0xFF2C1810),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 13,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Checkout',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.arrow_forward_rounded, size: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TOP BAR BUTTON HELPER
  // ==========================================
  Widget _headerAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 5),
              Text(
                label,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // EMPTY STATE
  // ==========================================
  Widget _emptyState(Color primary, Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.bakery_dining_outlined,
              size: 48,
              color: Color(0xFFA67C1E),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Bakes Available',
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2C1810),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try switching categories or clearing search keywords.',
            style: GoogleFonts.outfit(
              color: const Color(0xFF806F63),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              controller.clearSearch();
              controller.setCategory('All');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2C1810),
              foregroundColor: const Color(0xFFFFFCF7),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Show All Bakes',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // PRODUCT CARD
  // ==========================================
  Widget _buildProductCard(
    BuildContext context, {
    required RecipeModel recipe,
    required Color primaryColor,
    required Color accentColor,
    required NumberFormat currencyFormat,
    required InventoryProvider inventoryProvider,
    required CustomerProvider customerProvider,
    required OrderProvider orderProvider,
    required RecipeProvider recipeProvider,
    required dynamic branding,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF7),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2D3BF), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B4B32).withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Visual Card Header
          Container(
            height: 114,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFF8F3EB),
                  accentColor.withValues(alpha: 0.22),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22),
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    _getCategoryIcon(recipe.category),
                    size: 50,
                    color: const Color(0xFFA67C1E),
                  ),
                ),
                Positioned(
                  left: 12,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFCF7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2D3BF)),
                    ),
                    child: Text(
                      recipe.category.toUpperCase(),
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFA67C1E),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Material(
                    color: const Color(0xFFFFFCF7),
                    shape: const CircleBorder(),
                    child: IconButton(
                      tooltip: 'Recipe Details',
                      onPressed: () => _showRecipeDetailsDialog(
                        context,
                        recipe,
                        primaryColor,
                        accentColor,
                        currencyFormat,
                      ),
                      icon: const Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFFA67C1E),
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Card Body
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2C1810),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recipe.notes.isEmpty
                        ? 'Freshly baked with natural artisanal sourdough starters.'
                        : recipe.notes,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF806F63),
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                  const Spacer(),
                  if (recipe.allergens.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFFE082)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            size: 12,
                            color: Color(0xFFE65100),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              recipe.allergens.join(', '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                color: const Color(0xFFBF360C),
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currencyFormat.format(recipe.sellingPrice),
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF2C1810),
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              '${recipe.yieldServings} portion',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF806F63),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Obx(() {
                        final qty = controller.getItemQuantityInCart(recipe.id);
                        if (qty > 0) {
                          return Container(
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5EEE4),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE3D6C6),
                              ),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 28,
                                  ),
                                  onPressed: () => controller.updateQuantity(
                                    recipe.id,
                                    qty - 1,
                                  ),
                                  icon: const Icon(
                                    Icons.remove,
                                    size: 14,
                                    color: Color(0xFF2C1810),
                                  ),
                                ),
                                Text(
                                  '$qty',
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF2C1810),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 28,
                                  ),
                                  onPressed: () => controller.updateQuantity(
                                    recipe.id,
                                    qty + 1,
                                  ),
                                  icon: const Icon(
                                    Icons.add,
                                    size: 14,
                                    color: Color(0xFF2C1810),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return ElevatedButton.icon(
                          onPressed: () => controller.addToCart(recipe),
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: Text(
                            'Add',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2C1810),
                            foregroundColor: const Color(0xFFFFFCF7),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 9,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'breads':
      case 'sourdough':
        return Icons.breakfast_dining_rounded;
      case 'cakes':
        return Icons.cake_rounded;
      case 'pastries':
      case 'croissants':
        return Icons.bakery_dining_rounded;
      case 'cookies':
        return Icons.cookie_rounded;
      default:
        return Icons.lunch_dining_rounded;
    }
  }

  // ==========================================
  // RECIPE DETAILS MODAL
  // ==========================================
  void _showRecipeDetailsDialog(
    BuildContext context,
    RecipeModel recipe,
    Color primaryColor,
    Color accentColor,
    NumberFormat currencyFormat,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: const Color(0xFFFFFCF7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xFFE2D3BF)),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480, maxHeight: 580),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          recipe.title,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2C1810),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Color(0xFF806F63),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Category: ${recipe.category} • Yield: ${recipe.yieldServings} portion',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFA67C1E),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Divider(height: 24, color: Color(0xFFE2D6C9)),
                  if (recipe.notes.isNotEmpty) ...[
                    Text(
                      'BAKERY NOTES',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFA67C1E),
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      recipe.notes,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: const Color(0xFF2C1810),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    'ALLERGENS & DIETARY INFORMATION',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFA67C1E),
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (recipe.allergens.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: recipe.allergens.map((a) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E1),
                            border: Border.all(color: const Color(0xFFFFE082)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            a,
                            style: GoogleFonts.outfit(
                              color: const Color(0xFFBF360C),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }).toList(),
                    )
                  else
                    Text(
                      'No common allergens declared in standard recipe.',
                      style: GoogleFonts.outfit(
                        color: Colors.green.shade800,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  const SizedBox(height: 18),
                  Text(
                    'BAKING SPECIFICATIONS',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFA67C1E),
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildSpecPill(
                        'Prep Time',
                        '${recipe.prepTimeMins} mins',
                        Icons.timer_outlined,
                      ),
                      const SizedBox(width: 8),
                      _buildSpecPill(
                        'Bake Time',
                        '${recipe.bakeTimeMins} mins',
                        Icons.local_fire_department_outlined,
                      ),
                      const SizedBox(width: 8),
                      _buildSpecPill(
                        'Oven Temp',
                        '${recipe.bakingTempC}°C',
                        Icons.thermostat_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        currencyFormat.format(recipe.sellingPrice),
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2C1810),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          controller.addToCart(recipe);
                          Navigator.pop(ctx);
                        },
                        icon: const Icon(Icons.add_shopping_cart, size: 16),
                        label: Text(
                          'Add to Order',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2C1810),
                          foregroundColor: const Color(0xFFFFFCF7),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSpecPill(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF5EEE4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE3D6C6)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: const Color(0xFFA67C1E)),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: const Color(0xFF2C1810),
              ),
            ),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: const Color(0xFF806F63),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // CART & CHECKOUT SHEET
  // ==========================================
  void _showCartCheckoutSheet(
    BuildContext context, {
    required OrderProvider orderProvider,
    required InventoryProvider inventoryProvider,
    required CustomerProvider customerProvider,
    required RecipeProvider recipeProvider,
    required dynamic branding,
  }) {
    final primaryColor = branding.primaryColor;
    final accentColor = branding.accentColor;
    final currencyFormat = NumberFormat.currency(
      symbol: branding.currencySymbol,
      decimalDigits: 2,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final screenHeight = MediaQuery.of(context).size.height;
        return SizedBox(
          height: screenHeight * 0.90,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 700),
            decoration: const BoxDecoration(
              color: Color(0xFFFFFCF7),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 18,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2C1810),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.shopping_bag_outlined,
                        color: Color(0xFFD4AF37),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Your Bakery Cart & Checkout',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFFFCF7),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Color(0xFFFFFCF7),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: Obx(() {
                    if (controller.cartItems.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.remove_shopping_cart_outlined,
                              size: 56,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Your Cart Is Empty',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2C1810),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Explore our menu and add your favourite artisanal treats.',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF806F63),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ORDER ITEMS',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFFA67C1E),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.6,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: controller.cartItems.length,
                            separatorBuilder: (ctx, idx) => const Divider(
                              height: 16,
                              color: Color(0xFFE2D6C9),
                            ),
                            itemBuilder: (context, index) {
                              final item = controller.cartItems[index];
                              return Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.recipe.title,
                                          style: GoogleFonts.playfairDisplay(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: const Color(0xFF2C1810),
                                          ),
                                        ),
                                        Text(
                                          '${currencyFormat.format(item.recipe.sellingPrice)} each',
                                          style: GoogleFonts.outfit(
                                            color: const Color(0xFF806F63),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF5EEE4),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: const Color(0xFFE3D6C6),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.remove,
                                            size: 15,
                                            color: Color(0xFF2C1810),
                                          ),
                                          onPressed: () =>
                                              controller.updateQuantity(
                                                item.recipe.id,
                                                item.quantity - 1,
                                              ),
                                        ),
                                        Text(
                                          '${item.quantity}',
                                          style: GoogleFonts.outfit(
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF2C1810),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.add,
                                            size: 15,
                                            color: Color(0xFF2C1810),
                                          ),
                                          onPressed: () =>
                                              controller.updateQuantity(
                                                item.recipe.id,
                                                item.quantity + 1,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Text(
                                    currencyFormat.format(item.lineTotal),
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF2C1810),
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const Divider(height: 32, color: Color(0xFFE2D6C9)),

                          // Fulfillment Preference
                          Text(
                            'FULFILLMENT PREFERENCE',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFFA67C1E),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.6,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Obx(() {
                            final current = controller.fulfillmentType.value;
                            return Row(
                              children: [
                                Expanded(
                                  child: _fulfillmentOption(
                                    title: 'Store Collection',
                                    icon: Icons.storefront_rounded,
                                    isSelected:
                                        current == FulfillmentType.collection,
                                    accentColor: accentColor,
                                    onTap: () =>
                                        controller.fulfillmentType.value =
                                            FulfillmentType.collection,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _fulfillmentOption(
                                    title: 'Home Delivery',
                                    icon: Icons.delivery_dining_rounded,
                                    isSelected:
                                        current == FulfillmentType.delivery,
                                    accentColor: accentColor,
                                    onTap: () =>
                                        controller.fulfillmentType.value =
                                            FulfillmentType.delivery,
                                  ),
                                ),
                              ],
                            );
                          }),
                          const SizedBox(height: 20),

                          // Customer Information Form
                          Text(
                            'CONTACT & DELIVERY DETAILS',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFFA67C1E),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.6,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _checkoutTextField(
                                  controller: controller.nameController,
                                  hint: 'Full Name *',
                                  icon: Icons.person_outline_rounded,
                                  primaryColor: primaryColor,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _checkoutTextField(
                                  controller: controller.phoneController,
                                  hint: 'Phone Number *',
                                  icon: Icons.phone_outlined,
                                  primaryColor: primaryColor,
                                  keyboardType: TextInputType.phone,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _checkoutTextField(
                            controller: controller.emailController,
                            hint: 'Email Address (Optional for e-receipt)',
                            icon: Icons.email_outlined,
                            primaryColor: primaryColor,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 10),

                          // Delivery specifics
                          Obx(() {
                            if (controller.fulfillmentType.value ==
                                FulfillmentType.delivery) {
                              return Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: _checkoutTextField(
                                          controller:
                                              controller.addressController,
                                          hint: 'Delivery Street Address *',
                                          icon: Icons.home_outlined,
                                          primaryColor: primaryColor,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        flex: 1,
                                        child: _checkoutTextField(
                                          controller:
                                              controller.postcodeController,
                                          hint: 'Postcode *',
                                          icon: Icons.pin_drop_outlined,
                                          primaryColor: primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: () async {
                                        final result =
                                            await showDialog<
                                              Map<String, dynamic>
                                            >(
                                              context: context,
                                              builder: (_) =>
                                                  LocationPickerDialog(
                                                    initialLocation: LatLng(
                                                      controller
                                                              .deliveryLatitude
                                                              .value ??
                                                          31.5204,
                                                      controller
                                                              .deliveryLongitude
                                                              .value ??
                                                          74.3587,
                                                    ),
                                                    initialAddress: controller
                                                        .addressController
                                                        .text,
                                                    initialPostcode: controller
                                                        .postcodeController
                                                        .text,
                                                    primaryColor: primaryColor,
                                                    accentColor: accentColor,
                                                  ),
                                            );
                                        if (result != null) {
                                          final LatLng latLng =
                                              result['latLng'];
                                          final String addr =
                                              result['address'] ?? '';
                                          final String postcode =
                                              result['postcode'] ?? '';
                                          if (postcode.isNotEmpty) {
                                            controller.postcodeController.text =
                                                postcode;
                                          }
                                          controller.setDeliveryCoordinates(
                                            latLng.latitude,
                                            latLng.longitude,
                                            formattedAddress: addr,
                                          );
                                        }
                                      },
                                      icon: const Icon(
                                        Icons.pin_drop_rounded,
                                        size: 16,
                                      ),
                                      label: Text(
                                        controller.deliveryLatitude.value !=
                                                null
                                            ? '📍 Location Pinned (${controller.deliveryLatitude.value!.toStringAsFixed(3)}, ${controller.deliveryLongitude.value!.toStringAsFixed(3)})'
                                            : '📍 Pin Exact Location on Map',
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(
                                          0xFF2C1810,
                                        ),
                                        side: const BorderSide(
                                          color: Color(0xFFE2D3BF),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                ],
                              );
                            }
                            return const SizedBox.shrink();
                          }),

                          _checkoutTextField(
                            controller: controller.notesController,
                            hint: 'Special Baking Notes / Collection Instructions',
                            icon: Icons.note_alt_outlined,
                            primaryColor: primaryColor,
                          ),
                          const Divider(height: 32, color: Color(0xFFE2D6C9)),

                          // Order Summary Card
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5EEE4),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFE3D6C6),
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Subtotal:',
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFF806F63),
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      currencyFormat.format(
                                        controller.subtotal,
                                      ),
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF2C1810),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'UK VAT (20%):',
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFF806F63),
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      currencyFormat.format(
                                        controller.vatAmount,
                                      ),
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF2C1810),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(
                                  height: 18,
                                  color: Color(0xFFE2D6C9),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Grand Total:',
                                      style: GoogleFonts.outfit(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF2C1810),
                                      ),
                                    ),
                                    Text(
                                      currencyFormat.format(
                                        controller.grandTotal,
                                      ),
                                      style: GoogleFonts.outfit(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF2C1810),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Place Order Button
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFFF0CE72),
                                    accentColor,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: accentColor.withValues(alpha: 0.25),
                                    blurRadius: 20,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                  final order = controller.submitOrder(
                                    orderProvider: orderProvider,
                                    inventoryProvider: inventoryProvider,
                                    customerProvider: customerProvider,
                                    recipeProvider: recipeProvider,
                                  );

                                  if (order != null) {
                                    Navigator.pop(ctx);
                                    _showOrderSuccessDialog(
                                      context,
                                      order,
                                      branding,
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: const Color(0xFF2C1810),
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                child: Text(
                                  'Confirm & Place Order (${currencyFormat.format(controller.grandTotal)})',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _fulfillmentOption({
    required String title,
    required IconData icon,
    required bool isSelected,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF5EEE4) : const Color(0xFFFFFCF7),
          border: Border.all(
            color: isSelected ? accentColor : const Color(0xFFE2D3BF),
            width: isSelected ? 1.8 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? const Color(0xFFA67C1E)
                  : const Color(0xFF806F63),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected
                    ? const Color(0xFF2C1810)
                    : const Color(0xFF806F63),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _checkoutTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color primaryColor,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.outfit(
        fontSize: 13,
        color: const Color(0xFF2C1810),
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.outfit(
          color: const Color(0xFFAA9B8F),
          fontSize: 12,
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF9A8A7D), size: 18),
        filled: true,
        fillColor: const Color(0xFFF8F3EB),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE3D6C6)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE3D6C6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 1.5),
        ),
      ),
    );
  }

  // ==========================================
  // ORDER SUCCESS DIALOG
  // ==========================================
  void _showOrderSuccessDialog(
    BuildContext context,
    OrderModel order,
    dynamic branding,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          backgroundColor: const Color(0xFFFFFCF7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xFFE2D3BF)),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 460),
            padding: const EdgeInsets.all(26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green.shade800,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Order Placed Successfully!',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2C1810),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Your invoice number is:',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF806F63),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5EEE4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE3D6C6)),
                  ),
                  child: Text(
                    order.invoiceNumber,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFA67C1E),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Our master bakers have received your ticket. You can track progress in real-time!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF806F63),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2C1810),
                          side: const BorderSide(color: Color(0xFFE2D3BF)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Continue Shopping',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          final orderProvider = Provider.of<OrderProvider>(
                            context,
                            listen: false,
                          );
                          _showOrderTrackingSheet(
                            context,
                            orderProvider,
                            branding,
                          );
                        },
                        icon: const Icon(
                          Icons.local_shipping_outlined,
                          size: 16,
                        ),
                        label: Text(
                          'Track Order',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2C1810),
                          foregroundColor: const Color(0xFFFFFCF7),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // ORDER TRACKING BOTTOM SHEET
  // ==========================================
  void _showOrderTrackingSheet(
    BuildContext context,
    OrderProvider orderProvider,
    dynamic branding,
  ) {
    final primaryColor = branding.primaryColor;
    final accentColor = branding.accentColor;
    final currencyFormat = NumberFormat.currency(
      symbol: branding.currencySymbol,
      decimalDigits: 2,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final screenHeight = MediaQuery.of(context).size.height;
        return SizedBox(
          height: screenHeight * 0.88,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 700),
            decoration: const BoxDecoration(
              color: Color(0xFFFFFCF7),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 18,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2C1810),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.local_shipping_rounded,
                        color: Color(0xFFD4AF37),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Live Order Tracker',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFFFCF7),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Color(0xFFFFFCF7),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _checkoutTextField(
                          controller: controller.trackQueryController,
                          hint: 'Invoice # (e.g. INV-2026-101) or Phone #',
                          icon: Icons.search_rounded,
                          primaryColor: primaryColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () => controller.searchOrderForTracking(
                          orderProvider.orders,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2C1810),
                          foregroundColor: const Color(0xFFFFFCF7),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Track',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Results
                Expanded(
                  child: Obx(() {
                    final order = controller.trackedOrder.value;
                    final hasSearched = controller.hasSearchedTracking.value;
                    final history = controller.customerOrderHistory;

                    if (!hasSearched && order == null) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.manage_search_rounded,
                                size: 54,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Track Your Fresh Bakes',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 18,
                                  color: const Color(0xFF2C1810),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Enter your invoice or phone number above to see real-time baking and dispatch status.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF806F63),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (hasSearched && order == null) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.search_off_rounded,
                              size: 50,
                              color: Color(0xFFE65100),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No Orders Found',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 18,
                                color: const Color(0xFF2C1810),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Please verify your invoice # or phone number.',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF806F63),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (history.length > 1) ...[
                            Text(
                              'YOUR ORDERS (${history.length}):',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFFA67C1E),
                                fontWeight: FontWeight.w800,
                                fontSize: 10,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              height: 38,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: history.length,
                                itemBuilder: (context, idx) {
                                  final histOrder = history[idx];
                                  final isSelected = histOrder.id == order!.id;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ChoiceChip(
                                      label: Text(histOrder.invoiceNumber),
                                      selected: isSelected,
                                      selectedColor: const Color(0xFF2C1810),
                                      labelStyle: GoogleFonts.outfit(
                                        color: isSelected
                                            ? Colors.white
                                            : const Color(0xFF2C1810),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      onSelected: (_) => controller
                                          .selectOrderFromHistory(histOrder),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const Divider(height: 20, color: Color(0xFFE2D6C9)),
                          ],

                          // Order Header Summary Card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5EEE4),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFE3D6C6),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      order!.invoiceNumber,
                                      style: GoogleFonts.outfit(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF2C1810),
                                      ),
                                    ),
                                    _buildStatusBadge(order.status),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Customer: ${order.customerName} (${order.customerPhone})',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    color: const Color(0xFF2C1810),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Fulfillment: ${order.fulfillment == FulfillmentType.delivery ? "🚚 Home Delivery" : "🛍️ Store Collection"}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: const Color(0xFF806F63),
                                  ),
                                ),
                                if (order.customerAddress.isNotEmpty)
                                  Text(
                                    'Address: ${order.customerAddress}, ${order.customerPostcode}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      color: const Color(0xFF806F63),
                                    ),
                                  ),
                                if (order.fulfillment ==
                                    FulfillmentType.delivery) ...[
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) =>
                                              DeliveryTrackingMapDialog(
                                                order: order,
                                                primaryColor: primaryColor,
                                                accentColor: accentColor,
                                                isDriverView: false,
                                              ),
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.map_rounded,
                                        size: 16,
                                      ),
                                      label: const Text(
                                        'View Live Dispatch & Route Map',
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF2C1810,
                                        ),
                                        foregroundColor: const Color(
                                          0xFFFFFCF7,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 11,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        textStyle: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Timeline
                          Text(
                            'LIVE TIMELINE',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFFA67C1E),
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                              letterSpacing: 1.6,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildStatusTimeline(
                            order.status,
                            primaryColor,
                            accentColor,
                          ),
                          const SizedBox(height: 20),

                          // Items List
                          Text(
                            'ORDER ITEMS (${order.items.length})',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFFA67C1E),
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                              letterSpacing: 1.6,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFCF7),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFE2D3BF),
                              ),
                            ),
                            child: Column(
                              children: [
                                ...order.items.map((item) {
                                  return ListTile(
                                    dense: true,
                                    title: Text(
                                      item.recipeName,
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF2C1810),
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${item.quantity} x ${currencyFormat.format(item.unitPrice)}',
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFF806F63),
                                        fontSize: 11,
                                      ),
                                    ),
                                    trailing: Text(
                                      currencyFormat.format(item.lineTotal),
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF2C1810),
                                      ),
                                    ),
                                  );
                                }),
                                const Divider(
                                  height: 1,
                                  color: Color(0xFFE2D6C9),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Total Paid:',
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF2C1810),
                                        ),
                                      ),
                                      Text(
                                        currencyFormat.format(
                                          order.totalAmount,
                                        ),
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF2C1810),
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // STATUS TIMELINE STEPPER
  // ==========================================
  Widget _buildStatusTimeline(
    OrderStatus status,
    Color primaryColor,
    Color accentColor,
  ) {
    final steps = [
      {
        'title': 'Order Received',
        'desc': 'Logged into bakery queue',
        'status': OrderStatus.pending,
      },
      {
        'title': 'Baking & Preparation',
        'desc': 'Master bakers at work',
        'status': OrderStatus.baking,
      },
      {
        'title': 'Ready for Handover',
        'desc': 'Freshly boxed & awaiting dispatch',
        'status': OrderStatus.ready,
      },
      {
        'title': 'Completed',
        'desc': 'Delivered or collected',
        'status': OrderStatus.completed,
      },
    ];

    int currentStepIndex = 0;
    if (status == OrderStatus.baking) currentStepIndex = 1;
    if (status == OrderStatus.ready) currentStepIndex = 2;
    if (status == OrderStatus.completed) currentStepIndex = 3;

    if (status == OrderStatus.cancelled) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.cancel_outlined, color: Colors.red),
            const SizedBox(width: 10),
            Text(
              'This order has been cancelled.',
              style: GoogleFonts.outfit(
                color: Colors.red.shade900,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: List.generate(steps.length, (index) {
        final isDone = index <= currentStepIndex;
        final isCurrent = index == currentStepIndex;
        final step = steps[index];

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isDone
                        ? (isCurrent ? accentColor : const Color(0xFF2C1810))
                        : const Color(0xFFE2D6C9),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      isDone
                          ? (isCurrent ? Icons.refresh : Icons.check)
                          : Icons.circle,
                      color: isDone
                          ? (isCurrent ? const Color(0xFF2C1810) : Colors.white)
                          : Colors.grey.shade600,
                      size: isDone ? 16 : 8,
                    ),
                  ),
                ),
                if (index < steps.length - 1)
                  Container(
                    width: 2,
                    height: 36,
                    color: index < currentStepIndex
                        ? const Color(0xFF2C1810)
                        : const Color(0xFFE2D6C9),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step['title'] as String,
                      style: GoogleFonts.outfit(
                        fontWeight: isCurrent
                            ? FontWeight.bold
                            : FontWeight.w600,
                        color: isDone
                            ? const Color(0xFF2C1810)
                            : const Color(0xFF806F63),
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      step['desc'] as String,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF806F63),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  // ==========================================
  // STATUS BADGE
  // ==========================================
  Widget _buildStatusBadge(OrderStatus status) {
    Color bg;
    Color fg;

    switch (status) {
      case OrderStatus.pending:
        bg = const Color(0xFFFFF8E1);
        fg = const Color(0xFFE65100);
        break;
      case OrderStatus.baking:
        bg = const Color(0xFFFFE0B2);
        fg = const Color(0xFFBF360C);
        break;
      case OrderStatus.ready:
        bg = const Color(0xFFE3F2FD);
        fg = const Color(0xFF1565C0);
        break;
      case OrderStatus.completed:
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF2E7D32);
        break;
      case OrderStatus.cancelled:
        bg = Colors.red.shade100;
        fg = Colors.red.shade900;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.displayName,
        style: GoogleFonts.outfit(
          color: fg,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  // ==========================================
  // AMBIENT GLOW HELPER
  // ==========================================
  Widget _ambientGlow(double size, Color color, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: opacity),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: opacity),
            blurRadius: 120,
            spreadRadius: 20,
          ),
        ],
      ),
    );
  }
}
