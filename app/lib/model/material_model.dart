class MaterialItem {
  final String? uid;
  final String materialName;
  final String materialType;
  final String unit;
  final String? stationId;
  final double openingBalance;
  final double currentStock;
  final double reorderLevel;
  final double unitPrice;
  final double monthlyRequirement;
  final double issuedQuantity;
  final double usedQuantity;
  final String remarks;
  final String status;

  MaterialItem({
    this.uid,
    required this.materialName,
    required this.materialType,
    required this.unit,
    this.stationId,
    this.openingBalance = 0,
    this.currentStock = 0,
    this.reorderLevel = 0,
    this.unitPrice = 0,
    this.monthlyRequirement = 0,
    this.issuedQuantity = 0,
    this.usedQuantity = 0,
    this.remarks = '',
    this.status = 'active',
  });

  factory MaterialItem.fromJson(Map<String, dynamic> json) => MaterialItem(
    uid: json['uid'],
    materialName: json['materialName'] ?? '',
    materialType: json['materialType'] ?? '',
    unit: json['unit'] ?? '',
    stationId: json['stationId'],
    openingBalance: (json['openingBalance'] ?? 0).toDouble(),
    currentStock: (json['currentStock'] ?? 0).toDouble(),
    reorderLevel: (json['reorderLevel'] ?? 0).toDouble(),
    unitPrice: (json['unitPrice'] ?? 0).toDouble(),
    monthlyRequirement: (json['monthlyRequirement'] ?? 0).toDouble(),
    issuedQuantity: (json['issuedQuantity'] ?? 0).toDouble(),
    usedQuantity: (json['usedQuantity'] ?? 0).toDouble(),
    remarks: json['remarks'] ?? '',
    status: json['status'] ?? 'active',
  );

  Map<String, dynamic> toJson() => {
    if (uid != null) 'uid': uid,
    'materialName': materialName,
    'materialType': materialType,
    'unit': unit,
    if (stationId != null) 'stationId': stationId,
    'openingBalance': openingBalance,
    'currentStock': currentStock,
    'reorderLevel': reorderLevel,
    'unitPrice': unitPrice,
    'monthlyRequirement': monthlyRequirement,
    'issuedQuantity': issuedQuantity,
    'usedQuantity': usedQuantity,
    'remarks': remarks,
    'status': status,
  };
}

class MaterialTransaction {
  final String? uid;
  final String materialId;
  final String materialName;
  final String materialType;
  final String unit;
  final String transactionType;
  final double quantity;
  final double stockBefore;
  final double stockAfter;
  final String? issuedTo;
  final String? receivedFrom;
  final String? stationId;
  final String remarks;
  final String createdAt;

  MaterialTransaction({
    this.uid,
    required this.materialId,
    required this.materialName,
    required this.materialType,
    required this.unit,
    required this.transactionType,
    required this.quantity,
    required this.stockBefore,
    required this.stockAfter,
    this.issuedTo,
    this.receivedFrom,
    this.stationId,
    this.remarks = '',
    required this.createdAt,
  });

  factory MaterialTransaction.fromJson(Map<String, dynamic> json) => MaterialTransaction(
    uid: json['uid'],
    materialId: json['materialId'] ?? '',
    materialName: json['materialName'] ?? '',
    materialType: json['materialType'] ?? '',
    unit: json['unit'] ?? '',
    transactionType: json['transactionType'] ?? '',
    quantity: (json['quantity'] ?? 0).toDouble(),
    stockBefore: (json['stockBefore'] ?? 0).toDouble(),
    stockAfter: (json['stockAfter'] ?? 0).toDouble(),
    issuedTo: json['issuedTo'],
    receivedFrom: json['receivedFrom'],
    stationId: json['stationId'],
    remarks: json['remarks'] ?? '',
    createdAt: json['createdAt'] ?? '',
  );
}

class StockAlert {
  final String id;
  final String materialName;
  final String materialType;
  final String unit;
  final double currentStock;
  final double reorderLevel;
  final String? stationId;
  final double shortage;

  StockAlert({
    required this.id,
    required this.materialName,
    required this.materialType,
    required this.unit,
    required this.currentStock,
    required this.reorderLevel,
    this.stationId,
    required this.shortage,
  });

  factory StockAlert.fromJson(Map<String, dynamic> json) => StockAlert(
    id: json['id'] ?? '',
    materialName: json['materialName'] ?? '',
    materialType: json['materialType'] ?? '',
    unit: json['unit'] ?? '',
    currentStock: (json['currentStock'] ?? 0).toDouble(),
    reorderLevel: (json['reorderLevel'] ?? 0).toDouble(),
    stationId: json['stationId'],
    shortage: (json['shortage'] ?? 0).toDouble(),
  );
}
