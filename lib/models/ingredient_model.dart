class IngredientModel {
  final String id;
  final String name;
  final String category;
  final double currentStock;
  final String unit; // g, kg, ml, l, pcs, oz, tbsp, tsp
  final double purchasePrice; // e.g., £5.50
  final double purchaseQuantity; // e.g. 1000 (g)
  final String supplierName;
  final String? supplierContact;
  final double lowStockThreshold;

  IngredientModel({
    required this.id,
    required this.name,
    required this.category,
    required this.currentStock,
    required this.unit,
    required this.purchasePrice,
    required this.purchaseQuantity,
    required this.supplierName,
    this.supplierContact,
    required this.lowStockThreshold,
  });

  /// Calculate unit cost per 1 item or 1 gram/ml
  double get costPerUnit => purchaseQuantity > 0 ? purchasePrice / purchaseQuantity : 0.0;

  bool get isLowStock => currentStock <= lowStockThreshold;

  IngredientModel copyWith({
    String? id,
    String? name,
    String? category,
    double? currentStock,
    String? unit,
    double? purchasePrice,
    double? purchaseQuantity,
    String? supplierName,
    String? supplierContact,
    double? lowStockThreshold,
  }) {
    return IngredientModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      currentStock: currentStock ?? this.currentStock,
      unit: unit ?? this.unit,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      purchaseQuantity: purchaseQuantity ?? this.purchaseQuantity,
      supplierName: supplierName ?? this.supplierName,
      supplierContact: supplierContact ?? this.supplierContact,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'category': category,
        'currentStock': currentStock,
        'unit': unit,
        'purchasePrice': purchasePrice,
        'purchaseQuantity': purchaseQuantity,
        'supplierName': supplierName,
        'supplierContact': supplierContact,
        'lowStockThreshold': lowStockThreshold,
      };

  factory IngredientModel.fromMap(Map<String, dynamic> map) => IngredientModel(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        category: map['category'] ?? 'General',
        currentStock: (map['currentStock'] as num?)?.toDouble() ?? 0.0,
        unit: map['unit'] ?? 'g',
        purchasePrice: (map['purchasePrice'] as num?)?.toDouble() ?? 0.0,
        purchaseQuantity: (map['purchaseQuantity'] as num?)?.toDouble() ?? 1.0,
        supplierName: map['supplierName'] ?? 'Default Bakery Wholesaler',
        supplierContact: map['supplierContact'],
        lowStockThreshold: (map['lowStockThreshold'] as num?)?.toDouble() ?? 500.0,
      );
}
