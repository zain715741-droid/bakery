class CustomerModel {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String address;
  final String postcode; // UK Postcode format e.g. SW1A 1AA
  final String notes;
  final List<String> favoriteRecipeIds;
  final int totalOrders;
  final double totalSpent;

  CustomerModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    required this.postcode,
    this.notes = '',
    this.favoriteRecipeIds = const [],
    this.totalOrders = 0,
    this.totalSpent = 0.0,
  });

  CustomerModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? postcode,
    String? notes,
    List<String>? favoriteRecipeIds,
    int? totalOrders,
    double? totalSpent,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      postcode: postcode ?? this.postcode,
      notes: notes ?? this.notes,
      favoriteRecipeIds: favoriteRecipeIds ?? this.favoriteRecipeIds,
      totalOrders: totalOrders ?? this.totalOrders,
      totalSpent: totalSpent ?? this.totalSpent,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'address': address,
        'postcode': postcode,
        'notes': notes,
        'favoriteRecipeIds': favoriteRecipeIds,
        'totalOrders': totalOrders,
        'totalSpent': totalSpent,
      };

  factory CustomerModel.fromMap(Map<String, dynamic> map) => CustomerModel(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        phone: map['phone'] ?? '',
        email: map['email'] ?? '',
        address: map['address'] ?? '',
        postcode: map['postcode'] ?? '',
        notes: map['notes'] ?? '',
        favoriteRecipeIds: (map['favoriteRecipeIds'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        totalOrders: map['totalOrders'] ?? 0,
        totalSpent: (map['totalSpent'] as num?)?.toDouble() ?? 0.0,
      );
}
