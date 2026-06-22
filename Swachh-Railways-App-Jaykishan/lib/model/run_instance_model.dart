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
  final String? scheduledDeparture;
  final String? actualDeparture;
  final String? actualArrival;
  final String? journeyStartTime;
  final String? journeyEndTime;
  final String? division;
  final String? zone;
  final String? depot;

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
    this.scheduledDeparture,
    this.actualDeparture,
    this.actualArrival,
    this.journeyStartTime,
    this.journeyEndTime,
    this.division,
    this.zone,
    this.depot,
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
      scheduledDeparture: json['scheduledDeparture'] as String?,
      actualDeparture: json['actualDeparture'] as String?,
      actualArrival: json['actualArrival'] as String?,
      journeyStartTime: json['journeyStartTime'] as String?,
      journeyEndTime: json['journeyEndTime'] as String?,
      division: json['division'] as String?,
      zone: json['zone'] as String?,
      depot: json['depot'] as String?,
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
      if (scheduledDeparture != null) 'scheduledDeparture': scheduledDeparture,
      if (actualDeparture != null) 'actualDeparture': actualDeparture,
      if (actualArrival != null) 'actualArrival': actualArrival,
      if (journeyStartTime != null) 'journeyStartTime': journeyStartTime,
      if (journeyEndTime != null) 'journeyEndTime': journeyEndTime,
      if (division != null) 'division': division,
      if (zone != null) 'zone': zone,
      if (depot != null) 'depot': depot,
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
    String? scheduledDeparture,
    String? actualDeparture,
    String? actualArrival,
    String? journeyStartTime,
    String? journeyEndTime,
    String? division,
    String? zone,
    String? depot,
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
      scheduledDeparture: scheduledDeparture ?? this.scheduledDeparture,
      actualDeparture: actualDeparture ?? this.actualDeparture,
      actualArrival: actualArrival ?? this.actualArrival,
      journeyStartTime: journeyStartTime ?? this.journeyStartTime,
      journeyEndTime: journeyEndTime ?? this.journeyEndTime,
      division: division ?? this.division,
      zone: zone ?? this.zone,
      depot: depot ?? this.depot,
    );
  }
}

class CoachAssignment {
  final int coachPosition;
  final String coachType;
  final String? janitorId;
  final String? janitorName;
  final String? attendantId;
  final String? attendantName;
  final List<String>? janitorTasks;
  final List<String>? attendantTasks;

  CoachAssignment({
    required this.coachPosition,
    required this.coachType,
    this.janitorId,
    this.janitorName,
    this.attendantId,
    this.attendantName,
    this.janitorTasks,
    this.attendantTasks,
  });

  factory CoachAssignment.fromJson(Map<String, dynamic> json) {
    return CoachAssignment(
      coachPosition: json['coachPosition'] as int? ?? 0,
      coachType: json['coachType'] as String? ?? '',
      janitorId: (json['janitorId'] ?? json['workerId']) as String?,
      janitorName: (json['janitorName'] ?? json['workerName']) as String?,
      attendantId: json['attendantId'] as String?,
      attendantName: json['attendantName'] as String?,
      janitorTasks: (json['janitorTasks'] as List<dynamic>?)?.map((e) => e as String).toList(),
      attendantTasks: (json['attendantTasks'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    final effectiveWorkerId = janitorId;
    final effectiveWorkerName = janitorName;
    final effectiveWorkerRole = (attendantId != null && attendantId!.isNotEmpty) ? 'attendant' : 'janitor';
    return {
      'coachPosition': coachPosition,
      'coachType': coachType,
      if (janitorId != null && janitorId!.isNotEmpty) 'janitorId': janitorId,
      if (janitorName != null && janitorName!.isNotEmpty) 'janitorName': janitorName,
      if (attendantId != null && attendantId!.isNotEmpty) 'attendantId': attendantId,
      if (attendantName != null && attendantName!.isNotEmpty) 'attendantName': attendantName,
      if (janitorTasks != null) 'janitorTasks': janitorTasks,
      if (attendantTasks != null) 'attendantTasks': attendantTasks,
      // Also send workerId/workerName/workerRole for backend compatibility
      if (effectiveWorkerId != null && effectiveWorkerId.isNotEmpty) 'workerId': effectiveWorkerId,
      if (effectiveWorkerName != null && effectiveWorkerName.isNotEmpty) 'workerName': effectiveWorkerName,
      'workerRole': effectiveWorkerRole,
    };
  }

  CoachAssignment copyWith({
    int? coachPosition,
    String? coachType,
    String? janitorId,
    String? janitorName,
    String? attendantId,
    String? attendantName,
    List<String>? janitorTasks,
    List<String>? attendantTasks,
  }) {
    return CoachAssignment(
      coachPosition: coachPosition ?? this.coachPosition,
      coachType: coachType ?? this.coachType,
      janitorId: janitorId ?? this.janitorId,
      janitorName: janitorName ?? this.janitorName,
      attendantId: attendantId ?? this.attendantId,
      attendantName: attendantName ?? this.attendantName,
      janitorTasks: janitorTasks ?? this.janitorTasks,
      attendantTasks: attendantTasks ?? this.attendantTasks,
    );
  }
}
