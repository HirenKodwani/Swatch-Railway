class GarbageTaskModel {
  final String id;
  final String runInstanceId;
  final String coachNo;
  final String scheduledTime;
  final bool isPreTerminal;
  final String status;
  final String? beforePhoto;
  final String? afterPhoto;
  final double? gpsLatitude;
  final double? gpsLongitude;
  final DateTime? completedAt;

  GarbageTaskModel({
    required this.id,
    required this.runInstanceId,
    required this.coachNo,
    required this.scheduledTime,
    this.isPreTerminal = false,
    this.status = 'PENDING',
    this.beforePhoto,
    this.afterPhoto,
    this.gpsLatitude,
    this.gpsLongitude,
    this.completedAt,
  });

  factory GarbageTaskModel.fromJson(Map<String, dynamic> json) {
    return GarbageTaskModel(
      id: json['id'] as String? ?? '',
      runInstanceId: json['runInstanceId'] as String? ?? '',
      coachNo: json['coachNo'] as String? ?? '',
      scheduledTime: json['scheduledTime'] as String? ?? '',
      isPreTerminal: json['isPreTerminal'] as bool? ?? false,
      status: json['status'] as String? ?? 'PENDING',
      beforePhoto: json['beforePhoto'] as String?,
      afterPhoto: json['afterPhoto'] as String?,
      gpsLatitude: (json['gpsLatitude'] as num?)?.toDouble(),
      gpsLongitude: (json['gpsLongitude'] as num?)?.toDouble(),
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'runInstanceId': runInstanceId,
      'coachNo': coachNo,
      'scheduledTime': scheduledTime,
      'isPreTerminal': isPreTerminal,
      'status': status,
      if (beforePhoto != null) 'beforePhoto': beforePhoto,
      if (afterPhoto != null) 'afterPhoto': afterPhoto,
      if (gpsLatitude != null) 'gpsLatitude': gpsLatitude,
      if (gpsLongitude != null) 'gpsLongitude': gpsLongitude,
      if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
    };
  }

  GarbageTaskModel copyWith({
    String? id,
    String? runInstanceId,
    String? coachNo,
    String? scheduledTime,
    bool? isPreTerminal,
    String? status,
    String? beforePhoto,
    String? afterPhoto,
    double? gpsLatitude,
    double? gpsLongitude,
    DateTime? completedAt,
  }) {
    return GarbageTaskModel(
      id: id ?? this.id,
      runInstanceId: runInstanceId ?? this.runInstanceId,
      coachNo: coachNo ?? this.coachNo,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      isPreTerminal: isPreTerminal ?? this.isPreTerminal,
      status: status ?? this.status,
      beforePhoto: beforePhoto ?? this.beforePhoto,
      afterPhoto: afterPhoto ?? this.afterPhoto,
      gpsLatitude: gpsLatitude ?? this.gpsLatitude,
      gpsLongitude: gpsLongitude ?? this.gpsLongitude,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
