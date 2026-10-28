class RestaurantProfile {
  final String name;
  final String tagline;
  final String legalName;
  final String address;
  final String phone;
  final String email;
  final String gstin;
  final String fssai;
  final String upiId; // For Dynamic UPI QR Code, e.g. merchant@upi
  final String currencySymbol;
  final bool isGstEnabled;
  final double gstRatePercent;
  final bool isRoundOffEnabled;
  final bool isSetupCompleted;
  final bool isTaxInclusive; // true = Inclusive of GST, false = Exclusive of GST
  final int defaultTaxBps; // e.g. 500 = 5%

  const RestaurantProfile({
    this.name = 'Spice Garden Restaurant',
    this.tagline = 'Authentic Tandoor & Dining',
    this.legalName = 'Spice Garden Hospitality Pvt Ltd',
    this.address = '123 MG Road, Bengaluru, Karnataka 560001',
    this.phone = '+91 98765 43210',
    this.email = 'contact@spicegarden.in',
    this.gstin = '29ABCDE1234F1Z5',
    this.fssai = '11223344556677',
    this.upiId = 'spicegarden@icici',
    this.currencySymbol = '₹',
    this.isGstEnabled = true,
    this.gstRatePercent = 5.0,
    this.isRoundOffEnabled = true,
    this.isSetupCompleted = true,
    this.isTaxInclusive = false,
    this.defaultTaxBps = 500,
  });

  RestaurantProfile copyWith({
    String? name,
    String? tagline,
    String? legalName,
    String? address,
    String? phone,
    String? email,
    String? gstin,
    String? fssai,
    String? upiId,
    String? currencySymbol,
    bool? isGstEnabled,
    double? gstRatePercent,
    bool? isRoundOffEnabled,
    bool? isSetupCompleted,
    bool? isTaxInclusive,
    int? defaultTaxBps,
  }) {
    return RestaurantProfile(
      name: name ?? this.name,
      tagline: tagline ?? this.tagline,
      legalName: legalName ?? this.legalName,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      gstin: gstin ?? this.gstin,
      fssai: fssai ?? this.fssai,
      upiId: upiId ?? this.upiId,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      isGstEnabled: isGstEnabled ?? this.isGstEnabled,
      gstRatePercent: gstRatePercent ?? this.gstRatePercent,
      isRoundOffEnabled: isRoundOffEnabled ?? this.isRoundOffEnabled,
      isSetupCompleted: isSetupCompleted ?? this.isSetupCompleted,
      isTaxInclusive: isTaxInclusive ?? this.isTaxInclusive,
      defaultTaxBps: defaultTaxBps ?? this.defaultTaxBps,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'tagline': tagline,
      'legalName': legalName,
      'address': address,
      'phone': phone,
      'email': email,
      'gstin': gstin,
      'fssai': fssai,
      'upiId': upiId,
      'currencySymbol': currencySymbol,
      'isGstEnabled': isGstEnabled,
      'gstRatePercent': gstRatePercent,
      'isRoundOffEnabled': isRoundOffEnabled,
      'isSetupCompleted': isSetupCompleted,
      'isTaxInclusive': isTaxInclusive,
      'defaultTaxBps': defaultTaxBps,
    };
  }

  factory RestaurantProfile.fromMap(Map<String, dynamic> map) {
    return RestaurantProfile(
      name: map['name'] as String? ?? 'Spice Garden Restaurant',
      tagline: map['tagline'] as String? ?? 'Authentic Tandoor & Dining',
      legalName: map['legalName'] as String? ?? 'Spice Garden Hospitality Pvt Ltd',
      address: map['address'] as String? ?? '123 MG Road, Bengaluru, Karnataka 560001',
      phone: map['phone'] as String? ?? '+91 98765 43210',
      email: map['email'] as String? ?? 'contact@spicegarden.in',
      gstin: map['gstin'] as String? ?? '29ABCDE1234F1Z5',
      fssai: map['fssai'] as String? ?? '11223344556677',
      upiId: map['upiId'] as String? ?? 'spicegarden@icici',
      currencySymbol: map['currencySymbol'] as String? ?? '₹',
      isGstEnabled: map['isGstEnabled'] as bool? ?? true,
      gstRatePercent: (map['gstRatePercent'] as num?)?.toDouble() ?? 5.0,
      isRoundOffEnabled: map['isRoundOffEnabled'] as bool? ?? true,
      isSetupCompleted: map['isSetupCompleted'] as bool? ?? true,
      isTaxInclusive: map['isTaxInclusive'] as bool? ?? false,
      defaultTaxBps: map['defaultTaxBps'] as int? ?? 500,
    );
  }
}
