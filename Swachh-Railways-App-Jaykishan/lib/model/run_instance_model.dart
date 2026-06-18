class RunInstanceModel {
  final String? id;
  final String? runInstanceId;
  final String instanceId;
  final String? trainNo;
  final String? trainName;
  final String? inboundTrainNo;
  final String? outboundTrainNo;
  final String? parentTrainId;
  final List<CoachAssignment> coaches;
  final DateTime? createdAt;
  final String? createdBy;
  final String? createdByName;
  final DateTime? updatedAt;
  final String? updatedBy;
  final String? updatedByName;
  final DateTime? departureDate;
  final String status;

  RunInstanceModel({
    this.id,
    this.runInstanceId,
    required this.instanceId,
    this.trainNo,
    this.trainName,
    this.inboundTrainNo,
    this.outboundTrainNo,
    this.parentTrainId,
    required this.coaches,
    this.createdAt,
    this.createdBy,
    this.createdByName,
    this.updatedAt,
    this.updatedBy,
    this.updatedByName,
    this.departureDate,
    this.status = 'Active',
  });

  factory RunInstanceModel.fromJson(Map<String, dynamic> json) {
    return RunInstanceModel(
      id: json['id'] as String?,
      runInstanceId: json['runInstanceId'] as String?,
      instanceId: json['instanceId'] as String? ?? '',
      trainNo: json['trainNo'] as String?,
      trainName: json['trainName'] as String?,
      inboundTrainNo: json['inboundTrainNo'] as String?,
      outboundTrainNo: json['outboundTrainNo'] as String?,
      departureDate: json['departureDate'] != null
          ? DateTime.tryParse(json['departureDate'] as String)
          : null,
      parentTrainId: json['parentTrainId'] as String?,
      coaches: (json['coaches'] as List<dynamic>?)
              ?.map((coach) => CoachAssignment.fromJson(coach as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      createdBy: json['createdBy'] as String?,
      createdByName: json['createdByName'] as String?,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      updatedBy: json['updatedBy'] as String?,
      updatedByName: json['updatedByName'] as String?,
      status: json['status'] as String? ?? 'Active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (runInstanceId != null) 'runInstanceId': runInstanceId,
      'instanceId': instanceId,
      if (departureDate != null)
        'departureDate': '${departureDate!.year}-'
            '${departureDate!.month.toString().padLeft(2, '0')}-'
            '${departureDate!.day.toString().padLeft(2, '0')}',
      if (trainNo != null) 'trainNo': trainNo,
      if (trainName != null) 'trainName': trainName,
      if (inboundTrainNo != null) 'inboundTrainNo': inboundTrainNo,
      if (outboundTrainNo != null) 'outboundTrainNo': outboundTrainNo,
      if (parentTrainId != null) 'parentTrainId': parentTrainId,
      'coaches': coaches.map((coach) => coach.toJson()).toList(),
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (createdBy != null) 'createdBy': createdBy,
      if (createdByName != null) 'createdByName': createdByName,
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      if (updatedBy != null) 'updatedBy': updatedBy,
      if (updatedByName != null) 'updatedByName': updatedByName,
      'status': status,
    };
  }

  RunInstanceModel copyWith({
    String? id,
    String? runInstanceId,
    String? instanceId,
    DateTime? departureDate,
    String? trainNo,
    String? trainName,
    String? inboundTrainNo,
    String? outboundTrainNo,
    String? parentTrainId,
    List<CoachAssignment>? coaches,
    DateTime? createdAt,
    String? createdBy,
    String? createdByName,
    DateTime? updatedAt,
    String? updatedBy,
    String? updatedByName,
    String? status,
  }) {
    return RunInstanceModel(
      id: id ?? this.id,
      runInstanceId: runInstanceId ?? this.runInstanceId,
      instanceId: instanceId ?? this.instanceId,
      trainNo: trainNo ?? this.trainNo,
      departureDate: departureDate ?? this.departureDate,
      trainName: trainName ?? this.trainName,
      inboundTrainNo: inboundTrainNo ?? this.inboundTrainNo,
      outboundTrainNo: outboundTrainNo ?? this.outboundTrainNo,
      parentTrainId: parentTrainId ?? this.parentTrainId,
      coaches: coaches ?? this.coaches,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedByName: updatedByName ?? this.updatedByName,
      status: status ?? this.status,
    );
  }
}

class CoachAssignment {
  final int coachPosition;
  final String coachType;
  final String? workerId;
  final String? workerName;
  final String? attendantId;
  final String? attendantName;
  final List<String>? tasks;

  CoachAssignment({
    required this.coachPosition,
    required this.coachType,
    this.workerId,
    this.workerName,
    this.attendantId,
    this.attendantName,
    this.tasks,
  });

  factory CoachAssignment.fromJson(Map<String, dynamic> json) {
    return CoachAssignment(
      coachPosition: json['coachPosition'] as int? ?? 0,
      coachType: json['coachType'] as String? ?? '',
      workerId: json['workerId'] as String?,
      workerName: json['workerName'] as String?,
      attendantId: json['attendantId'] as String?,
      attendantName: json['attendantName'] as String?,
      tasks: (json['tasks'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'coachPosition': coachPosition,
      'coachType': coachType,
      if (workerId != null && workerId!.isNotEmpty) 'workerId': workerId,
      if (workerName != null && workerName!.isNotEmpty) 'workerName': workerName,
      if (attendantId != null && attendantId!.isNotEmpty) 'attendantId': attendantId,
      if (attendantName != null && attendantName!.isNotEmpty) 'attendantName': attendantName,
      if (tasks != null) 'tasks': tasks,
    };
  }

  CoachAssignment copyWith({
    int? coachPosition,
    String? coachType,
    String? workerId,
    String? workerName,
    String? attendantId,
    String? attendantName,
    List<String>? tasks,
  }) {
    return CoachAssignment(
      coachPosition: coachPosition ?? this.coachPosition,
      coachType: coachType ?? this.coachType,
      workerId: workerId ?? this.workerId,
      workerName: workerName ?? this.workerName,
      attendantId: attendantId ?? this.attendantId,
      attendantName: attendantName ?? this.attendantName,
      tasks: tasks ?? this.tasks,
    );
  }
}
