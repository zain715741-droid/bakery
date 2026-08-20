import 'package:flutter_test/flutter_test.dart';
import 'package:bakery/models/user_model.dart';
import 'package:bakery/models/ingredient_model.dart';
import 'package:bakery/models/recipe_model.dart';
import 'package:bakery/models/order_model.dart';
import 'package:bakery/providers/inventory_provider.dart';

void main() {
  group('Bakery Application Core Logic Unit Tests', () {
    test('UserPermissions for RBAC Roles', () {
      final ownerPerms = UserPermissions.forRole(UserRole.owner);
      expect(ownerPerms.canManageUsers, isTrue);
      expect(ownerPerms.canViewFinancials, isTrue);
      expect(ownerPerms.canEditRecipes, isTrue);

      final staffPerms = UserPermissions.forRole(UserRole.staff);
      expect(staffPerms.canManageUsers, isFalse);
      expect(staffPerms.canViewFinancials, isFalse);
      expect(staffPerms.canEditRecipes, isFalse);
      expect(staffPerms.canCreateOrders, isTrue);
    });

    test('Recipe Cost Calculation Logic', () {
      final ingredient = IngredientModel(
        id: 'ing_1',
        name: 'Butter',
        category: 'Dairy',
        currentStock: 1000,
        unit: 'g',
        purchasePrice: 10.0,
        purchaseQuantity: 1000, // £0.01 per gram
        supplierName: 'Dairy Co',
        lowStockThreshold: 100,
      );

      final recipe = RecipeModel(
        id: 'rec_1',
        title: 'Test Cake',
        category: 'Cakes',
        prepTimeMins: 10,
        bakeTimeMins: 20,
        bakingTempC: 180,
        yieldServings: 10,
        sellingPrice: 5.0,
        ingredients: [
          RecipeIngredientItem(
            ingredientId: ingredient.id,
            name: ingredient.name,
            quantity: 500, // 500g * £0.01 = £5.00
            unit: 'g',
            unitCost: ingredient.costPerUnit,
          ),
        ],
        instructions: ['Bake at 180°C'],
        notes: '',
        allergens: ['Milk'],
        nutritionalInfo: const NutritionalInfo(calories: 250),
      );

      expect(recipe.totalBatchCost, equals(5.0));
      expect(recipe.costPerServing, equals(0.50));
      expect(recipe.grossProfitMargin, equals(90.0));
    });

    test('Inventory Automated Stock Deduction', () {
      final inventory = InventoryProvider();
      inventory.setIngredients([
        IngredientModel(
          id: 'ing_1',
          name: 'Flour',
          category: 'Flour',
          currentStock: 10000,
          unit: 'g',
          purchasePrice: 5.0,
          purchaseQuantity: 5000,
          supplierName: 'Mill',
          lowStockThreshold: 2000,
        ),
      ]);

      expect(inventory.ingredients.first.currentStock, equals(10000));

      inventory.deductRecipeStock({'ing_1': 1500});

      expect(inventory.ingredients.first.currentStock, equals(8500));
    });

    test('Order Totals and VAT calculation', () {
      final order = OrderModel(
        id: 'ord_1',
        invoiceNumber: 'INV-2026-001',
        customerId: 'cust_1',
        customerName: 'Alice',
        customerPhone: '',
        customerAddress: '',
        customerPostcode: 'SW1A 1AA',
        items: [
          OrderItem(recipeId: 'rec_1', recipeName: 'Cake', quantity: 2, unitPrice: 20.0), // subtotal 40
        ],
        status: OrderStatus.pending,
        fulfillment: FulfillmentType.collection,
        paymentStatus: PaymentStatus.unpaid,
        vatRate: 0.20, // 20% VAT
        createdAt: DateTime.now(),
        targetDate: DateTime.now(),
      );

      expect(order.subtotal, equals(40.0));
      expect(order.vatAmount, equals(8.0));
      expect(order.totalAmount, equals(48.0));
    });
  });
}
