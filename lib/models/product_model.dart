class ProductModel {
  final String id;
  final String businessId;
  final String name;
  final double price;
  final double gstRate;
  final String unit;

  ProductModel({
    required this.id,
    required this.businessId,
    required this.name,
    required this.price,
    required this.gstRate,
    required this.unit,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'businessId': businessId,
      'name': name,
      'price': price,
      'gstRate': gstRate,
      'unit': unit,
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] ?? '',
      businessId: map['businessId'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      gstRate: (map['gstRate'] ?? 0).toDouble(),
      unit: map['unit'] ?? 'Pcs',
    );
  }

  ProductModel copyWith({
    String? id,
    String? businessId,
    String? name,
    double? price,
    double? gstRate,
    String? unit,
  }) {
    return ProductModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      price: price ?? this.price,
      gstRate: gstRate ?? this.gstRate,
      unit: unit ?? this.unit,
    );
  }
}
