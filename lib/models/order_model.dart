enum OrderStatus { pending, baking, ready, completed, cancelled }

enum FulfillmentType { collection, delivery }

enum PaymentStatus { paid, unpaid, partiallyPaid }

extension OrderStatusExtension on OrderStatus {
  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.baking:
        return 'Baking';
      case OrderStatus.ready:
        return 'Ready for Collection/Delivery';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  static OrderStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'baking':
        return OrderStatus.baking;
      case 'ready':
        return OrderStatus.ready;
      case 'completed':
        return OrderStatus.completed;
      case 'cancelled':
        return OrderStatus.cancelled;
      case 'pending':
      default:
        return OrderStatus.pending;
    }
  }
}

class OrderItem {
  final String recipeId;
  final String recipeName;
  final int quantity;
  final double unitPrice;

  OrderItem({
    required this.recipeId,
    required this.recipeName,
    required this.quantity,
    required this.unitPrice,
  });

  double get lineTotal => quantity * unitPrice;

  Map<String, dynamic> toMap() => {
    'recipeId': recipeId,
    'recipeName': recipeName,
    'quantity': quantity,
    'unitPrice': unitPrice,
  };

  factory OrderItem.fromMap(Map<String, dynamic> map) => OrderItem(
    recipeId: map['recipeId'] ?? '',
    recipeName: map['recipeName'] ?? '',
    quantity: map['quantity'] ?? 1,
    unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
  );
}

class OrderModel {
  final String id;
  final String invoiceNumber;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final String customerPostcode;
  final double? latitude;
  final double? longitude;
  final String deliveryDriverName;
  final String deliveryDriverPhone;
  final List<OrderItem> items;
  final OrderStatus status;
  final FulfillmentType fulfillment;
  final PaymentStatus paymentStatus;
  final double vatRate; // e.g. 0.20
  final DateTime createdAt;
  final DateTime targetDate;
  final String notes;

  OrderModel({
    required this.id,
    required this.invoiceNumber,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    required this.customerPostcode,
    this.latitude,
    this.longitude,
    this.deliveryDriverName = '',
    this.deliveryDriverPhone = '',
    required this.items,
    required this.status,
    required this.fulfillment,
    required this.paymentStatus,
    this.vatRate = 0.20,
    required this.createdAt,
    required this.targetDate,
    this.notes = '',
  });

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.lineTotal);
  double get vatAmount => subtotal * vatRate;
  double get totalAmount => subtotal + vatAmount;

  OrderModel copyWith({
    String? id,
    String? invoiceNumber,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? customerAddress,
    String? customerPostcode,
    double? latitude,
    double? longitude,
    String? deliveryDriverName,
    String? deliveryDriverPhone,
    List<OrderItem>? items,
    OrderStatus? status,
    FulfillmentType? fulfillment,
    PaymentStatus? paymentStatus,
    double? vatRate,
    DateTime? createdAt,
    DateTime? targetDate,
    String? notes,
  }) {
    return OrderModel(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerAddress: customerAddress ?? this.customerAddress,
      customerPostcode: customerPostcode ?? this.customerPostcode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      deliveryDriverName: deliveryDriverName ?? this.deliveryDriverName,
      deliveryDriverPhone: deliveryDriverPhone ?? this.deliveryDriverPhone,
      items: items ?? this.items,
      status: status ?? this.status,
      fulfillment: fulfillment ?? this.fulfillment,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      vatRate: vatRate ?? this.vatRate,
      createdAt: createdAt ?? this.createdAt,
      targetDate: targetDate ?? this.targetDate,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'invoiceNumber': invoiceNumber,
    'customerId': customerId,
    'customerName': customerName,
    'customerPhone': customerPhone,
    'customerAddress': customerAddress,
    'customerPostcode': customerPostcode,
    'latitude': latitude,
    'longitude': longitude,
    'deliveryDriverName': deliveryDriverName,
    'deliveryDriverPhone': deliveryDriverPhone,
    'items': items.map((i) => i.toMap()).toList(),
    'status': status.name,
    'fulfillment': fulfillment.name,
    'paymentStatus': paymentStatus.name,
    'vatRate': vatRate,
    'createdAt': createdAt.toIso8601String(),
    'targetDate': targetDate.toIso8601String(),
    'notes': notes,
  };

  factory OrderModel.fromMap(Map<String, dynamic> map) => OrderModel(
    id: map['id'] ?? '',
    invoiceNumber: map['invoiceNumber'] ?? 'INV-0001',
    customerId: map['customerId'] ?? '',
    customerName: map['customerName'] ?? 'Guest Customer',
    customerPhone: map['customerPhone'] ?? '',
    customerAddress: map['customerAddress'] ?? '',
    customerPostcode: map['customerPostcode'] ?? '',
    latitude: (map['latitude'] as num?)?.toDouble(),
    longitude: (map['longitude'] as num?)?.toDouble(),
    deliveryDriverName: map['deliveryDriverName'] ?? '',
    deliveryDriverPhone: map['deliveryDriverPhone'] ?? '',
    items:
        (map['items'] as List<dynamic>?)
            ?.map((i) => OrderItem.fromMap(Map<String, dynamic>.from(i)))
            .toList() ??
        [],
    status: OrderStatusExtension.fromString(map['status'] ?? 'pending'),
    fulfillment: map['fulfillment'] == 'delivery'
        ? FulfillmentType.delivery
        : FulfillmentType.collection,
    paymentStatus: map['paymentStatus'] == 'paid'
        ? PaymentStatus.paid
        : (map['paymentStatus'] == 'partiallyPaid' ||
                  map['paymentStatus'] == 'partially_paid'
              ? PaymentStatus.partiallyPaid
              : PaymentStatus.unpaid),
    vatRate: (map['vatRate'] as num?)?.toDouble() ?? 0.20,
    createdAt: map['createdAt'] != null
        ? DateTime.parse(map['createdAt'])
        : DateTime.now(),
    targetDate: map['targetDate'] != null
        ? DateTime.parse(map['targetDate'])
        : DateTime.now().add(const Duration(days: 1)),
    notes: map['notes'] ?? '',
  );
}
