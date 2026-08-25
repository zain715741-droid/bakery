import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../controllers/storefront_controller.dart';
import '../../models/order_model.dart';
import '../../models/recipe_model.dart';
import '../../providers/branding_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/recipe_provider.dart';
import '../auth/login_screen.dart';
import 'package:latlong2/latlong.dart';
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
    final brandingProvider = Provider.of<BrandingProvider>(context);
    final recipeProvider = Provider.of<RecipeProvider>(context);
    final orderProvider = Provider.of<OrderProvider>(context);
    final inventoryProvider = Provider.of<InventoryProvider>(context);
    final customerProvider = Provider.of<CustomerProvider>(context);

    final branding = brandingProvider.branding;
    final primaryColor = branding.primaryColor;
    final accentColor = branding.accentColor;
    final currencyFormat = NumberFormat.currency(symbol: branding.currencySymbol, decimalDigits: 2);

    final allRecipes = recipeProvider.recipes;
    final categories = ['All', ...recipeProvider.categories];

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      body: Obx(() {
        final filteredRecipes = controller.getFilteredRecipes(allRecipes);
        final selectedCategory = controller.selectedCategory.value;

        return CustomScrollView(
          slivers: [
            // 1. App Bar with Brand & Navigation Actions
            SliverAppBar(
              pinned: true,
              floating: false,
              elevation: 3,
              backgroundColor: primaryColor,
              expandedHeight: 80,
              toolbarHeight: 70,
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryColor,
                      Color.alphaBlend(accentColor.withValues(alpha: 0.15), primaryColor),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: accentColor, width: 1.5),
                    ),
                    child: Icon(Icons.bakery_dining_rounded, color: accentColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          branding.businessName,
                          style: GoogleFonts.playfairDisplay(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          branding.welcomeMessage.isNotEmpty ? branding.welcomeMessage : 'Artisan Fresh Bakes & Online Ordering',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                // Track Order button
                TextButton.icon(
                  onPressed: () => _showOrderTrackingSheet(context, orderProvider, branding),
                  icon: const Icon(Icons.local_shipping_outlined, color: Colors.white, size: 18),
                  label: Text(
                    'Track Order',
                    style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(width: 8),

                // Staff Login button
                TextButton.icon(
                  onPressed: () => Get.to(() => const LoginScreen()),
                  icon: Icon(Icons.admin_panel_settings_rounded, color: accentColor, size: 18),
                  label: Text(
                    'Staff Portal',
                    style: GoogleFonts.outfit(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: accentColor.withValues(alpha: 0.5)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Cart Button with Badge
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 26),
                      tooltip: 'View Cart',
                      onPressed: () => _showCartCheckoutSheet(
                        context,
                        orderProvider: orderProvider,
                        inventoryProvider: inventoryProvider,
                        customerProvider: customerProvider,
                        recipeProvider: recipeProvider,
                        branding: branding,
                      ),
                    ),
                    if (controller.totalCartItemCount > 0)
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: accentColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: primaryColor, width: 2),
                          ),
                          constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                          child: Center(
                            child: Text(
                              '${controller.totalCartItemCount}',
                              style: const TextStyle(
                                color: Color(0xFF1E100B),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
              ],
            ),

            // 2. Hero Banner & Search Section
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryColor,
                      Color.alphaBlend(accentColor.withValues(alpha: 0.25), primaryColor),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.stars_rounded, size: 14, color: Color(0xFF1E100B)),
                              const SizedBox(width: 4),
                              Text(
                                'Fresh Daily Bakes',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1E100B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Icon(Icons.access_time_filled_rounded, size: 14, color: accentColor),
                            const SizedBox(width: 4),
                            Text(
                              'Open Today • 07:00 - 19:00',
                              style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Handcrafted Artisan Baking,\nDelivered Fresh to You',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Browse our fresh breads, signature pastries, and bespoke cakes. Place your order for in-store collection or doorstep delivery.',
                      style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                    ),
                    const SizedBox(height: 18),

                    // Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: controller.searchController,
                        onChanged: controller.updateSearch,
                        style: GoogleFonts.outfit(fontSize: 14, color: Colors.black87),
                        decoration: InputDecoration(
                          hintText: 'Search delicious pastries, sourdough, cakes, allergens...',
                          hintStyle: GoogleFonts.outfit(fontSize: 14, color: Colors.grey.shade500),
                          prefixIcon: Icon(Icons.search_rounded, color: primaryColor),
                          suffixIcon: controller.searchQuery.value.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close_rounded, size: 18),
                                  onPressed: controller.clearSearch,
                                )
                              : const SizedBox.shrink(),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3. Category Filter Chips
            SliverToBoxAdapter(
              child: SizedBox(
                height: 48,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final isSelected = selectedCategory.toLowerCase() == cat.toLowerCase();
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text(
                          cat,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.white : const Color(0xFF4A3E39),
                          ),
                        ),
                        selectedColor: primaryColor,
                        backgroundColor: Colors.white,
                        checkmarkColor: accentColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected ? primaryColor : Colors.grey.shade300,
                          ),
                        ),
                        onSelected: (_) => controller.setCategory(cat),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // 4. Products Grid
            if (filteredRecipes.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cookie_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No Bakes Found',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try choosing another category or clearing your search.',
                          style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            controller.clearSearch();
                            controller.setCategory('All');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('View All Bakes'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 380,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    mainAxisExtent: 340,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final recipe = filteredRecipes[index];
                      return _buildProductCard(
                        context,
                        recipe: recipe,
                        primaryColor: primaryColor,
                        accentColor: accentColor,
                        currencyFormat: currencyFormat,
                        inventoryProvider: inventoryProvider,
                        customerProvider: customerProvider,
                        orderProvider: orderProvider,
                        recipeProvider: recipeProvider,
                        branding: branding,
                      );
                    },
                    childCount: filteredRecipes.length,
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        );
      }),

      // 5. Floating Bottom Cart Summary Banner
      bottomSheet: Obx(() {
        final count = controller.totalCartItemCount;
        if (count == 0) return const SizedBox.shrink();

        return Container(
          decoration: BoxDecoration(
            color: primaryColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E100B)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total: ${currencyFormat.format(controller.grandTotal)} (inc. VAT)',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Tap to review cart & checkout',
                        style: GoogleFonts.outfit(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showCartCheckoutSheet(
                    context,
                    orderProvider: orderProvider,
                    inventoryProvider: inventoryProvider,
                    customerProvider: customerProvider,
                    recipeProvider: recipeProvider,
                    branding: branding,
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('Checkout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: const Color(0xFF1E100B),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header thumbnail / category badge
          Container(
            height: 110,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryColor.withValues(alpha: 0.08),
                  accentColor.withValues(alpha: 0.18),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    _getCategoryIcon(recipe.category),
                    size: 52,
                    color: primaryColor.withValues(alpha: 0.7),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      recipe.category,
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: const Icon(Icons.info_outline_rounded, color: Color(0xFF6B4423), size: 20),
                    tooltip: 'Recipe Details & Allergens',
                    onPressed: () => _showRecipeDetailsDialog(context, recipe, primaryColor, accentColor, currencyFormat),
                  ),
                ),
              ],
            ),
          ),

          // Card Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
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
                    recipe.notes.isNotEmpty ? recipe.notes : 'Freshly baked with premium artisanal ingredients.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade600, height: 1.2),
                  ),
                  const Spacer(),

                  // Allergens Tag Line
                  if (recipe.allergens.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, size: 12, color: Colors.amber.shade800),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Contains: ${recipe.allergens.join(', ')}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 10, color: Colors.amber.shade900, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Price and Add to Cart Action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currencyFormat.format(recipe.sellingPrice),
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          Text(
                            'Yield: ${recipe.yieldServings} portion',
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                      Obx(() {
                        final qty = controller.getItemQuantityInCart(recipe.id);
                        if (qty > 0) {
                          return Container(
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove, size: 16),
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  padding: EdgeInsets.zero,
                                  color: primaryColor,
                                  onPressed: () => controller.updateQuantity(recipe.id, qty - 1),
                                ),
                                Text(
                                  '$qty',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 13),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add, size: 16),
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  padding: EdgeInsets.zero,
                                  color: primaryColor,
                                  onPressed: () => controller.updateQuantity(recipe.id, qty + 1),
                                ),
                              ],
                            ),
                          );
                        }

                        return ElevatedButton.icon(
                          onPressed: () => controller.addToCart(recipe),
                          icon: const Icon(Icons.add_shopping_cart_rounded, size: 15),
                          label: const Text('Add'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          recipe.title,
                          style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.bold, color: primaryColor),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Category: ${recipe.category} • Yield: ${recipe.yieldServings} servings',
                    style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const Divider(height: 24),
                  if (recipe.notes.isNotEmpty) ...[
                    Text('Description', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(recipe.notes, style: GoogleFonts.outfit(fontSize: 13, color: Colors.black87)),
                    const SizedBox(height: 16),
                  ],
                  Text('Allergens & Dietary Advice', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 6),
                  if (recipe.allergens.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: recipe.allergens.map((a) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            border: Border.all(color: Colors.amber.shade400),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(a, style: TextStyle(color: Colors.brown.shade800, fontSize: 12, fontWeight: FontWeight.w600)),
                        );
                      }).toList(),
                    )
                  else
                    const Text('No declared common allergens in base recipe.', style: TextStyle(color: Colors.green, fontSize: 12)),
                  const SizedBox(height: 16),
                  Text('Baking Specifications', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildSpecPill('Prep Time', '${recipe.prepTimeMins} mins', Icons.timer_outlined),
                      const SizedBox(width: 8),
                      _buildSpecPill('Bake Time', '${recipe.bakeTimeMins} mins', Icons.local_fire_department_outlined),
                      const SizedBox(width: 8),
                      _buildSpecPill('Temp', '${recipe.bakingTempC}°C', Icons.thermostat_outlined),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        currencyFormat.format(recipe.sellingPrice),
                        style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: primaryColor),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          controller.addToCart(recipe);
                          Navigator.pop(ctx);
                        },
                        icon: const Icon(Icons.add_shopping_cart),
                        label: const Text('Add to Order'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F4EE),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF8B5E3C)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 10)),
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
    final currencyFormat = NumberFormat.currency(symbol: branding.currencySymbol, decimalDigits: 2);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final screenHeight = MediaQuery.of(context).size.height;
        return SizedBox(
          height: screenHeight * 0.9,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 700),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.shopping_bag_outlined, color: accentColor),
                    const SizedBox(width: 10),
                    Text(
                      'Your Bakery Cart & Checkout',
                      style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
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
                          Icon(Icons.remove_shopping_cart_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 14),
                          Text('Your cart is empty', style: GoogleFonts.playfairDisplay(fontSize: 18, color: primaryColor)),
                          const SizedBox(height: 6),
                          Text('Add items from the menu to place an order.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                        ],
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cart Items List
                        Text('Order Items', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor)),
                        const SizedBox(height: 10),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: controller.cartItems.length,
                          separatorBuilder: (ctx, idx) => const Divider(height: 16),
                          itemBuilder: (context, index) {
                            final item = controller.cartItems[index];
                            return Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item.recipe.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                      Text(
                                        '${currencyFormat.format(item.recipe.sellingPrice)} each',
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove, size: 16),
                                        onPressed: () => controller.updateQuantity(item.recipe.id, item.quantity - 1),
                                      ),
                                      Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      IconButton(
                                        icon: const Icon(Icons.add, size: 16),
                                        onPressed: () => controller.updateQuantity(item.recipe.id, item.quantity + 1),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Text(
                                  currencyFormat.format(item.lineTotal),
                                  style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 14),
                                ),
                              ],
                            );
                          },
                        ),

                        const Divider(height: 32),

                        // Fulfillment Selector
                        Text('Fulfillment Preference', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor)),
                        const SizedBox(height: 8),
                        Obx(() {
                          final current = controller.fulfillmentType.value;
                          return Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => controller.fulfillmentType.value = FulfillmentType.collection,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: current == FulfillmentType.collection ? primaryColor.withValues(alpha: 0.1) : Colors.white,
                                      border: Border.all(
                                        color: current == FulfillmentType.collection ? primaryColor : Colors.grey.shade300,
                                        width: 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.storefront_rounded, color: primaryColor),
                                        const SizedBox(width: 8),
                                        Text('Store Collection', style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: InkWell(
                                  onTap: () => controller.fulfillmentType.value = FulfillmentType.delivery,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: current == FulfillmentType.delivery ? primaryColor.withValues(alpha: 0.1) : Colors.white,
                                      border: Border.all(
                                        color: current == FulfillmentType.delivery ? primaryColor : Colors.grey.shade300,
                                        width: 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.delivery_dining_rounded, color: primaryColor),
                                        const SizedBox(width: 8),
                                        Text('Home Delivery', style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),

                        const SizedBox(height: 20),

                        // Customer Details Form
                        Text('Your Contact & Delivery Information', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor)),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: controller.nameController,
                                decoration: InputDecoration(
                                  labelText: 'Full Name *',
                                  prefixIcon: const Icon(Icons.person_outline),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: controller.phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  labelText: 'Phone Number *',
                                  prefixIcon: const Icon(Icons.phone_outlined),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        TextField(
                          controller: controller.emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email Address (Optional for receipt)',
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 12),

                        Obx(() {
                          if (controller.fulfillmentType.value == FulfillmentType.delivery) {
                            return Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: TextField(
                                        controller: controller.addressController,
                                        decoration: InputDecoration(
                                          labelText: 'Delivery Address *',
                                          prefixIcon: const Icon(Icons.home_outlined),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      flex: 1,
                                      child: TextField(
                                        controller: controller.postcodeController,
                                        textCapitalization: TextCapitalization.characters,
                                        decoration: InputDecoration(
                                          labelText: 'Postcode *',
                                          prefixIcon: const Icon(Icons.pin_drop_outlined),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                // Pin on Map Button
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      final result = await showDialog<Map<String, dynamic>>(
                                        context: context,
                                        builder: (_) => LocationPickerDialog(
                                          initialLocation: LatLng(
                                            controller.deliveryLatitude.value ?? 51.5074,
                                            controller.deliveryLongitude.value ?? -0.1278,
                                          ),
                                          initialAddress: controller.addressController.text,
                                          primaryColor: primaryColor,
                                          accentColor: accentColor,
                                        ),
                                      );
                                      if (result != null) {
                                        final LatLng latLng = result['latLng'];
                                        final String addr = result['address'];
                                        controller.setDeliveryCoordinates(latLng.latitude, latLng.longitude, formattedAddress: addr);
                                      }
                                    },
                                    icon: const Icon(Icons.pin_drop_rounded, size: 16),
                                    label: Text(
                                      controller.deliveryLatitude.value != null
                                          ? '📍 Location Pinned on Map (${controller.deliveryLatitude.value!.toStringAsFixed(3)}, ${controller.deliveryLongitude.value!.toStringAsFixed(3)})'
                                          : '📍 Pin Exact Location on Live Map',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: primaryColor,
                                      side: BorderSide(color: primaryColor.withValues(alpha: 0.6)),
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        }),

                        TextField(
                          controller: controller.notesController,
                          decoration: InputDecoration(
                            labelText: 'Special Baking Notes / Collection Instructions',
                            prefixIcon: const Icon(Icons.note_alt_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),

                        const Divider(height: 32),

                        // Order Pricing Breakdown
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F4EE),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Subtotal:'),
                                  Text(currencyFormat.format(controller.subtotal), style: const TextStyle(fontWeight: FontWeight.w600)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('UK VAT (20%):'),
                                  Text(currencyFormat.format(controller.vatAmount), style: const TextStyle(fontWeight: FontWeight.w600)),
                                ],
                              ),
                              const Divider(height: 18),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Grand Total:', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor)),
                                  Text(
                                    currencyFormat.format(controller.grandTotal),
                                    style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
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
                                _showOrderSuccessDialog(context, order, branding);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Text(
                              'Confirm & Place Order (${currencyFormat.format(controller.grandTotal)})',
                              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
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

  // ==========================================
  // ORDER SUCCESS DIALOG
  // ==========================================
  void _showOrderSuccessDialog(BuildContext context, OrderModel order, dynamic branding) {
    final primaryColor = branding.primaryColor;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_circle_rounded, color: Colors.green.shade700, size: 54),
                ),
                const SizedBox(height: 16),
                Text(
                  'Order Placed Successfully!',
                  style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.bold, color: primaryColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Your invoice number is:',
                  style: GoogleFonts.outfit(color: Colors.grey.shade700, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    order.invoiceNumber,
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Our master bakers have received your order and will start preparation shortly. You can track live progress anytime!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 13, height: 1.3),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Continue Shopping'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          final orderProvider = Provider.of<OrderProvider>(context, listen: false);
                          _showOrderTrackingSheet(context, orderProvider, branding);
                        },
                        icon: const Icon(Icons.local_shipping_outlined, size: 16),
                        label: const Text('Track Order'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
  void _showOrderTrackingSheet(BuildContext context, OrderProvider orderProvider, dynamic branding) {
    final primaryColor = branding.primaryColor;
    final accentColor = branding.accentColor;
    final currencyFormat = NumberFormat.currency(symbol: branding.currencySymbol, decimalDigits: 2);

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
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.local_shipping_rounded, color: accentColor),
                    const SizedBox(width: 10),
                    Text(
                      'Live Order Tracker',
                      style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),

              // Search Box
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller.trackQueryController,
                        decoration: InputDecoration(
                          hintText: 'Enter Invoice # (e.g. INV-2026-101) or Phone #',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        onSubmitted: (_) => controller.searchOrderForTracking(orderProvider.orders),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () => controller.searchOrderForTracking(orderProvider.orders),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Track'),
                    ),
                  ],
                ),
              ),

              // Tracking Results
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
                            Icon(Icons.manage_search_rounded, size: 54, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'Track Your Fresh Bakes',
                              style: GoogleFonts.playfairDisplay(fontSize: 18, color: primaryColor, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Enter your invoice number or phone number above to see real-time baking and delivery status.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
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
                          Icon(Icons.search_off_rounded, size: 54, color: Colors.orange.shade400),
                          const SizedBox(height: 12),
                          Text(
                            'No Orders Found',
                            style: GoogleFonts.playfairDisplay(fontSize: 18, color: primaryColor, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Please double check your invoice # or phone number.',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  }

                  // Found Order View
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Multiple orders selector if searched by phone
                        if (history.length > 1) ...[
                          Text('Your Orders (${history.length}):', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
                                    selectedColor: primaryColor,
                                    labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontSize: 12),
                                    onSelected: (_) => controller.selectOrderFromHistory(histOrder),
                                  ),
                                );
                              },
                            ),
                          ),
                          const Divider(height: 20),
                        ],

                        // Order Header Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFBF8F2),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    order!.invoiceNumber,
                                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
                                  ),
                                  _buildStatusBadge(order.status),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text('Customer: ${order.customerName} (${order.customerPhone})', style: const TextStyle(fontSize: 13)),
                              Text(
                                'Fulfillment: ${order.fulfillment == FulfillmentType.delivery ? "🚚 Home Delivery" : "🛍️ Store Collection"}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                              if (order.customerAddress.isNotEmpty)
                                Text('Address: ${order.customerAddress}, ${order.customerPostcode}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                              if (order.fulfillment == FulfillmentType.delivery) ...[
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) => DeliveryTrackingMapDialog(
                                          order: order,
                                          primaryColor: primaryColor,
                                          accentColor: accentColor,
                                          isDriverView: false,
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.map_rounded, size: 16),
                                    label: const Text('View Live Delivery Dispatch & Route Map'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Progress Stepper
                        Text('Live Baking & Fulfillment Timeline', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: primaryColor)),
                        const SizedBox(height: 12),
                        _buildStatusTimeline(order.status, primaryColor, accentColor),

                        const SizedBox(height: 20),

                        // Ordered Items
                        Text('Order Items (${order.items.length})', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: primaryColor)),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            children: [
                              ...order.items.map((item) {
                                return ListTile(
                                  dense: true,
                                  title: Text(item.recipeName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('${item.quantity} x ${currencyFormat.format(item.unitPrice)}'),
                                  trailing: Text(currencyFormat.format(item.lineTotal), style: const TextStyle(fontWeight: FontWeight.bold)),
                                );
                              }),
                              const Divider(height: 1),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Total Amount:', style: TextStyle(fontWeight: FontWeight.bold)),
                                    Text(
                                      currencyFormat.format(order.totalAmount),
                                      style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 16),
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
  // TIMELINE STEPPER
  // ==========================================
  Widget _buildStatusTimeline(OrderStatus status, Color primaryColor, Color accentColor) {
    final steps = [
      {'title': 'Order Received', 'desc': 'Logged into bakery queue', 'status': OrderStatus.pending},
      {'title': 'Baking & Preparation', 'desc': 'Master bakers at work', 'status': OrderStatus.baking},
      {'title': 'Ready for Handover', 'desc': 'Freshly boxed & awaiting you', 'status': OrderStatus.ready},
      {'title': 'Completed', 'desc': 'Delivered or collected', 'status': OrderStatus.completed},
    ];

    int currentStepIndex = 0;
    if (status == OrderStatus.baking) currentStepIndex = 1;
    if (status == OrderStatus.ready) currentStepIndex = 2;
    if (status == OrderStatus.completed) currentStepIndex = 3;
    if (status == OrderStatus.cancelled) currentStepIndex = -1;

    if (status == OrderStatus.cancelled) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: const Row(
          children: [
            Icon(Icons.cancel_outlined, color: Colors.red),
            SizedBox(width: 10),
            Text('This order has been cancelled.', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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
                    color: isDone ? (isCurrent ? accentColor : primaryColor) : Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      isDone ? (isCurrent ? Icons.refresh : Icons.check) : Icons.circle,
                      color: isDone ? (isCurrent ? const Color(0xFF1E100B) : Colors.white) : Colors.grey.shade600,
                      size: isDone ? 16 : 8,
                    ),
                  ),
                ),
                if (index < steps.length - 1)
                  Container(
                    width: 2,
                    height: 36,
                    color: index < currentStepIndex ? primaryColor : Colors.grey.shade300,
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
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                        color: isDone ? primaryColor : Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      step['desc'] as String,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
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

  Widget _buildStatusBadge(OrderStatus status) {
    Color bg;
    Color fg;

    switch (status) {
      case OrderStatus.pending:
        bg = Colors.amber.shade100;
        fg = Colors.amber.shade900;
        break;
      case OrderStatus.baking:
        bg = Colors.orange.shade100;
        fg = Colors.orange.shade900;
        break;
      case OrderStatus.ready:
        bg = Colors.blue.shade100;
        fg = Colors.blue.shade900;
        break;
      case OrderStatus.completed:
        bg = Colors.green.shade100;
        fg = Colors.green.shade900;
        break;
      case OrderStatus.cancelled:
        bg = Colors.red.shade100;
        fg = Colors.red.shade900;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(
        status.displayName,
        style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }
}
