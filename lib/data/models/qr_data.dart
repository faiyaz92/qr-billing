class QrSignature {
  final String appSignature;
  final String storeSignature;
  final int type;

  QrSignature({required this.appSignature, required this.storeSignature, required this.type});

  Map<String, dynamic> toJson() => {
    'as': appSignature,
    'ss': storeSignature,
    't': type,
  };

  factory QrSignature.fromJson(Map<String, dynamic> json) => QrSignature(
    appSignature: json['as'] ?? json['app_signature'], // Support both compact and full names
    storeSignature: json['ss'] ?? json['store_signature'],
    type: json['t'] ?? json['type'],
  );
}

class QrData {
  final String encryptedSignature;
  final Map<String, dynamic> data;

  QrData({required this.encryptedSignature, required this.data});

  Map<String, dynamic> toJson() => {
    'es': encryptedSignature,
    'd': data,
  };

  factory QrData.fromJson(Map<String, dynamic> json) => QrData(
    encryptedSignature: json['es'] ?? json['encrypted_signature'], // Support both compact and full names
    data: json['d'] ?? json['data'] ?? {},
  );
}