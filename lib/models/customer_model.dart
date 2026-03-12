class CustomerModel {
  final String id;
  final String businessId;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String? gstNumber;

  CustomerModel({
    required this.id,
    required this.businessId,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    this.gstNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'businessId': businessId,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'gstNumber': gstNumber,
    };
  }

  factory CustomerModel.fromMap(Map<String, dynamic> map) {
    return CustomerModel(
      id: map['id'] ?? '',
      businessId: map['businessId'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      gstNumber: map['gstNumber'],
    );
  }

  CustomerModel copyWith({
    String? id,
    String? businessId,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? gstNumber,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      gstNumber: gstNumber ?? this.gstNumber,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CustomerModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
