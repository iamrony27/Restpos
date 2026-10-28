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
    this.name = '',
    this.tagline = '',
    this.legalName = '',
    this.address = '',
    this.phone = '',
    this.email = '',
    this.gstin = '',
    this.fssai = '',
    this.upiId = '',
    this.currencySymbol = '₹',
    this.isGstEnabled = true,
    this.gstRatePercent = 5.0,
    this.isRoundOffEnabled = true,
    this.isSetupCompleted = false,
    this.isTaxInclusive = true,
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
      name: map['name'] as String? ?? '',
      tagline: map['tagline'] as String? ?? '',
      legalName: map['legalName'] as String? ?? '',
      address: map['address'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String? ?? '',
      gstin: map['gstin'] as String? ?? '',
      fssai: map['fssai'] as String? ?? '',
      upiId: map['upiId'] as String? ?? '',
      currencySymbol: map['currencySymbol'] as String? ?? '₹',
      isGstEnabled: map['isGstEnabled'] as bool? ?? true,
      gstRatePercent: (map['gstRatePercent'] as num?)?.toDouble() ?? 5.0,
      isRoundOffEnabled: map['isRoundOffEnabled'] as bool? ?? true,
      isSetupCompleted: map['isSetupCompleted'] as bool? ?? false,
      isTaxInclusive: map['isTaxInclusive'] as bool? ?? true,
      defaultTaxBps: map['defaultTaxBps'] as int? ?? 500,
    );
  }
}
