class TaskDetailModel {
  final String detailId;
  final String headerId;
  final String runInstanceId;
  final String coachNo;
  final String workerId;
  final String taskType;
  final String scheduledTime;
  final String? toiletStatus;
  final String? washBasinStatus;
  final String? dustbinStatus;
  final String? consumableStatus;
  final String? beforePhoto;
  final String? afterPhoto;
  final double? gpsLatitude;
  final double? gpsLongitude;
  final String? employeeId;
  final String? deviceId;
  final String? mobileNumber;
  final Map<String, dynamic>? checklist;
  final String status;
  final String? remarks;
  final DateTime? completionTime;
  final DateTime? createdAt;

  TaskDetailModel({
    required this.detailId,
    required this.headerId,
    required this.runInstanceId,
    required this.coachNo,
    required this.workerId,
    required this.taskType,
    required this.scheduledTime,
    this.toiletStatus,
    this.washBasinStatus,
    this.dustbinStatus,
    this.consumableStatus,
    this.beforePhoto,
    this.afterPhoto,
    this.gpsLatitude,
    this.gpsLongitude,
    this.employeeId,
    this.deviceId,
    this.mobileNumber,
    this.checklist,
    this.status = 'PLANNED',
    this.remarks,
    this.completionTime,
    this.createdAt,
  });

  factory TaskDetailModel.fromJson(Map<String, dynamic> json) {
    return TaskDetailModel(
      detailId: json['detailId'] as String? ?? '',
      headerId: json['headerId'] as String? ?? '',
      runInstanceId: json['runInstanceId'] as String? ?? '',
      coachNo: json['coachNo'] as String? ?? '',
      workerId: json['workerId'] as String? ?? '',
      taskType: json['taskType'] as String? ?? '',
      scheduledTime: json['scheduledTime'] as String? ?? '',
      toiletStatus: json['toiletStatus'] as String?,
      washBasinStatus: json['washBasinStatus'] as String?,
      dustbinStatus: json['dustbinStatus'] as String?,
      consumableStatus: json['consumableStatus'] as String?,
      beforePhoto: json['beforePhoto'] as String?,
      afterPhoto: json['afterPhoto'] as String?,
      gpsLatitude: (json['gpsLatitude'] as num?)?.toDouble(),
      gpsLongitude: (json['gpsLongitude'] as num?)?.toDouble(),
      employeeId: json['employeeId'] as String?,
      deviceId: json['deviceId'] as String?,
      mobileNumber: json['mobileNumber'] as String?,
      checklist: json['checklist'] as Map<String, dynamic>?,
      status: json['status'] as String? ?? 'PLANNED',
      remarks: json['remarks'] as String?,
      completionTime: json['completionTime'] != null
          ? DateTime.tryParse(json['completionTime'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'detailId': detailId,
      'headerId': headerId,
      'runInstanceId': runInstanceId,
      'coachNo': coachNo,
      'workerId': workerId,
      'taskType': taskType,
      'scheduledTime': scheduledTime,
      if (toiletStatus != null) 'toiletStatus': toiletStatus,
      if (washBasinStatus != null) 'washBasinStatus': washBasinStatus,
      if (dustbinStatus != null) 'dustbinStatus': dustbinStatus,
      if (consumableStatus != null) 'consumableStatus': consumableStatus,
      if (beforePhoto != null) 'beforePhoto': beforePhoto,
      if (afterPhoto != null) 'afterPhoto': afterPhoto,
      if (gpsLatitude != null) 'gpsLatitude': gpsLatitude,
      if (gpsLongitude != null) 'gpsLongitude': gpsLongitude,
      if (employeeId != null) 'employeeId': employeeId,
      if (deviceId != null) 'deviceId': deviceId,
      if (mobileNumber != null) 'mobileNumber': mobileNumber,
      if (checklist != null) 'checklist': checklist,
      'status': status,
      if (remarks != null) 'remarks': remarks,
      if (completionTime != null)
        'completionTime': completionTime!.toIso8601String(),
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  TaskDetailModel copyWith({
    String? detailId,
    String? headerId,
    String? runInstanceId,
    String? coachNo,
    String? workerId,
    String? taskType,
    String? scheduledTime,
    String? toiletStatus,
    String? washBasinStatus,
    String? dustbinStatus,
    String? consumableStatus,
    String? beforePhoto,
    String? afterPhoto,
    double? gpsLatitude,
    double? gpsLongitude,
    String? employeeId,
    String? deviceId,
    String? mobileNumber,
    Map<String, dynamic>? checklist,
    String? status,
    String? remarks,
    DateTime? completionTime,
    DateTime? createdAt,
  }) {
    return TaskDetailModel(
      detailId: detailId ?? this.detailId,
      headerId: headerId ?? this.headerId,
      runInstanceId: runInstanceId ?? this.runInstanceId,
      coachNo: coachNo ?? this.coachNo,
      workerId: workerId ?? this.workerId,
      taskType: taskType ?? this.taskType,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      toiletStatus: toiletStatus ?? this.toiletStatus,
      washBasinStatus: washBasinStatus ?? this.washBasinStatus,
      dustbinStatus: dustbinStatus ?? this.dustbinStatus,
      consumableStatus: consumableStatus ?? this.consumableStatus,
      beforePhoto: beforePhoto ?? this.beforePhoto,
      afterPhoto: afterPhoto ?? this.afterPhoto,
      gpsLatitude: gpsLatitude ?? this.gpsLatitude,
      gpsLongitude: gpsLongitude ?? this.gpsLongitude,
      employeeId: employeeId ?? this.employeeId,
      deviceId: deviceId ?? this.deviceId,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      checklist: checklist ?? this.checklist,
      status: status ?? this.status,
      remarks: remarks ?? this.remarks,
      completionTime: completionTime ?? this.completionTime,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
