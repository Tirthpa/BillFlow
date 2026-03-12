class BusinessModel {
  final String uid;
  final String businessName;
  final String email;
  final String phone;
  final String address;
  final String gstNumber;
  final String? logoUrl;
  // SaaS Payment Details
  final String? bankName;
  final String? accountNumber;
  final String? ifscCode;
  final String? upiId;

  BusinessModel({
    required this.uid,
    required this.businessName,
    required this.email,
    required this.phone,
    required this.address,
    required this.gstNumber,
    this.logoUrl,
    this.bankName,
    this.accountNumber,
    this.ifscCode,
    this.upiId,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'businessName': businessName,
      'email': email,
      'phone': phone,
      'address': address,
      'gstNumber': gstNumber,
      'logoUrl': logoUrl,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'ifscCode': ifscCode,
      'upiId': upiId,
    };
  }

  factory BusinessModel.fromMap(Map<String, dynamic> map) {
    return BusinessModel(
      uid: map['uid'] ?? '',
      businessName: map['businessName'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      gstNumber: map['gstNumber'] ?? '',
      logoUrl: map['logoUrl'],
      bankName: map['bankName'],
      accountNumber: map['accountNumber'],
      ifscCode: map['ifscCode'],
      upiId: map['upiId'],
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BusinessModel && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}
