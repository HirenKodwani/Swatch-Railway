class SafetyCheckModel {
  final String id;
  final String runInstanceId;
  final DateTime scheduledTime;
  final String fireExtinguisherStatus;
  final String fsdsStatus;
  final String cctvStatus;
  final String emergencyEquipmentStatus;
  final List<String> photos;
  final List<String> deficiencyReports;
  final String status;
  final String? remarks;
  final DateTime? completedAt;

  SafetyCheckModel({
    required this.id,
    required this.runInstanceId,
    required this.scheduledTime,
    this.fireExtinguisherStatus = 'ok',
    this.fsdsStatus = 'ok',
    this.cctvStatus = 'ok',
    this.emergencyEquipmentStatus = 'ok',
    this.photos = const [],
    this.deficiencyReports = const [],
    this.status = 'PENDING',
    this.remarks,
    this.completedAt,
  });

  factory SafetyCheckModel.fromJson(Map<String, dynamic> json) {
    return SafetyCheckModel(
      id: json['id'] as String? ?? '',
      runInstanceId: json['runInstanceId'] as String? ?? '',
      scheduledTime: json['scheduledTime'] != null
          ? DateTime.parse(json['scheduledTime'] as String)
          : DateTime.now(),
      fireExtinguisherStatus:
          json['fireExtinguisherStatus'] as String? ?? 'ok',
      fsdsStatus: json['fsdsStatus'] as String? ?? 'ok',
      cctvStatus: json['cctvStatus'] as String? ?? 'ok',
      emergencyEquipmentStatus:
          json['emergencyEquipmentStatus'] as String? ?? 'ok',
      photos: (json['photos'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      deficiencyReports: (json['deficiencyReports'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      status: json['status'] as String? ?? 'PENDING',
      remarks: json['remarks'] as String?,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'runInstanceId': runInstanceId,
      'scheduledTime': scheduledTime.toIso8601String(),
      'fireExtinguisherStatus': fireExtinguisherStatus,
      'fsdsStatus': fsdsStatus,
      'cctvStatus': cctvStatus,
      'emergencyEquipmentStatus': emergencyEquipmentStatus,
      'photos': photos,
      'deficiencyReports': deficiencyReports,
      'status': status,
      if (remarks != null) 'remarks': remarks,
      if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
    };
  }

  SafetyCheckModel copyWith({
    String? id,
    String? runInstanceId,
    DateTime? scheduledTime,
    String? fireExtinguisherStatus,
    String? fsdsStatus,
    String? cctvStatus,
    String? emergencyEquipmentStatus,
    List<String>? photos,
    List<String>? deficiencyReports,
    String? status,
    String? remarks,
    DateTime? completedAt,
  }) {
    return SafetyCheckModel(
      id: id ?? this.id,
      runInstanceId: runInstanceId ?? this.runInstanceId,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      fireExtinguisherStatus:
          fireExtinguisherStatus ?? this.fireExtinguisherStatus,
      fsdsStatus: fsdsStatus ?? this.fsdsStatus,
      cctvStatus: cctvStatus ?? this.cctvStatus,
      emergencyEquipmentStatus:
          emergencyEquipmentStatus ?? this.emergencyEquipmentStatus,
      photos: photos ?? this.photos,
      deficiencyReports: deficiencyReports ?? this.deficiencyReports,
      status: status ?? this.status,
      remarks: remarks ?? this.remarks,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
