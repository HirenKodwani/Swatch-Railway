class ContractModel {
  String uid;
  String? contractNumber;
  String? contractName;
  String? entityId;
  String? entityName;
  String? zone;
  String? division;
  String? depot;
  String? startDate;
  String? endDate;
  String? workCategories;
  String? remarks;
  String? status;

  String? repName;
  String? repDesignation;
  String? repMobile;
  String? repEmail;
  String? repIdProofType;
  String? repIdProofNumber;

  bool? isActive;

  DateTime? createdAt;
  String? createdBy;
  String? createdByName;
  DateTime? updatedAt;
  String? updatedBy;
  String? updatedByName;

  ContractModel({
    required this.uid,
    this.contractNumber,
    this.contractName,
    this.entityId,
    this.entityName,
    this.zone,
    this.division,
    this.depot,
    this.startDate,
    this.endDate,
    this.workCategories,
    this.remarks,
    this.status,
    this.repName,
    this.repDesignation,
    this.repMobile,
    this.repEmail,
    this.repIdProofType,
    this.repIdProofNumber,
    this.isActive,
    this.createdAt,
    this.createdBy,
    this.createdByName,
    this.updatedAt,
    this.updatedBy,
    this.updatedByName,
  });

  factory ContractModel.fromJson(Map<String, dynamic> json) {
    DateTime? _parseTimestamp(dynamic ts) {
      if (ts == null) return null;

      if (ts is Map<String, dynamic> && ts['_seconds'] != null) {
        return DateTime.fromMillisecondsSinceEpoch(ts['_seconds'] * 1000);
      }

      if (ts is String) {
        try {
          return DateTime.parse(ts);
        } catch (e) {
          return null;
        }
      }

      return null;
    }

    final rep = json['representative'] is Map ? json['representative'] as Map<String, dynamic> : {};

    final statusValue = (json['status'] ?? '').toString().toLowerCase();
    final bool isActiveValue = statusValue == 'active';

    return ContractModel(
      uid: json['uid'] ?? '',
      contractNumber: json['contractNumber'],
      contractName: json['contractName'],
      entityId: json['entityId'],
      entityName: json['entityName'],
      zone: json['zone'],
      division: json['division'],
      depot: json['depot'],
      startDate: json['startDate'],
      endDate: json['endDate'],
      workCategories: json['workCategories'],
      remarks: json['remarks'],
      status: json['status'],

      repName: json['repName'] ?? rep['name'],
      repDesignation: json['repDesignation'] ?? rep['designation'],
      repMobile: json['repMobile'] ?? rep['mobile'],
      repEmail: json['repEmail'] ?? rep['email'],
      repIdProofType: json['repIdProofType'] ?? rep['idProofType'],
      repIdProofNumber: json['repIdProofNumber'] ?? rep['idProofNumber'],

      isActive: isActiveValue,

      createdAt: _parseTimestamp(json['createdAt']),
      createdBy: json['createdBy'],
      createdByName: json['createdByName'],
      updatedAt: _parseTimestamp(json['updatedAt']),
      updatedBy: json['updatedBy'],
      updatedByName: json['updatedByName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'contractNumber': contractNumber,
      'contractName': contractName,
      'entityId': entityId,
      'entityName': entityName,
      'zone': zone,
      'division': division,
      'depot': depot,
      'startDate': startDate,
      'endDate': endDate,
      'workCategories': workCategories,
      'remarks': remarks,
      'status': status,

      'repName': repName,
      'repDesignation': repDesignation,
      'repMobile': repMobile,
      'repEmail': repEmail,
      'repIdProofType': repIdProofType,
      'repIdProofNumber': repIdProofNumber,

      'isActive': isActive,

      'createdAt': createdAt?.toIso8601String(),
      'createdBy': createdBy,
      'createdByName': createdByName,
      'updatedAt': updatedAt?.toIso8601String(),
      'updatedBy': updatedBy,
      'updatedByName': updatedByName,
    };
  }
}

class Contract {
  String uid;
  String? contractNo;
  String? contractName;
  String entity;
  String zone;
  String division;
  String? depot;
  List<String> workCategories;
  String status;
  String? remarks;
  DateTime? startDate;
  DateTime? endDate;
  bool isActive;

  Contract({
    required this.uid,
    this.contractNo,
    this.contractName,
    required this.entity,
    required this.zone,
    required this.division,
    this.depot,
    this.workCategories = const [],
    this.status = 'Active',
    this.remarks,
    this.startDate,
    this.endDate,
    this.isActive = true,
  });
}