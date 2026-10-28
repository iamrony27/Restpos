class RestaurantProfile {
  final String name;
  final String legalName;
  final String address;
  final String phone;
  final String email;
  final String gstin;
  final String fssai;
  final String upiId; // For Dynamic UPI QR Code, e.g. merchant@upi
  final String currencySymbol;
  final int defaultTaxBps; // 500 = 5%

  const RestaurantProfile({
    this.name = 'Spice Garden Restaurant',
    this.legalName = 'Spice Garden Hospitality Pvt Ltd',
    this.address = '123 MG Road, Bengaluru, Karnataka 560001',
    this.phone = '+91 98765 43210',
    this.email = 'contact@spicegarden.in',
    this.gstin = '29ABCDE1234F1Z5',
    this.fssai = '11223344556677',
    this.upiId = 'spicegarden@icici',
    this.currencySymbol = '₹',
    this.defaultTaxBps = 500,
  });

  RestaurantProfile copyWith({
    String? name,
    String? legalName,
    String? address,
    String? phone,
    String? email,
    String? gstin,
    String? fssai,
    String? upiId,
    String? currencySymbol,
    int? defaultTaxBps,
  }) {
    return RestaurantProfile(
      name: name ?? this.name,
      legalName: legalName ?? this.legalName,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      gstin: gstin ?? this.gstin,
      fssai: fssai ?? this.fssai,
      upiId: upiId ?? this.upiId,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      defaultTaxBps: defaultTaxBps ?? this.defaultTaxBps,
    );
  }
}
