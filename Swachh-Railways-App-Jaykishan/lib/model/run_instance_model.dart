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
  final int delayMinutes;
  final List<JourneyTimelineEntry> journeyTimeline;

  static const Map<String, String> stateLabels = {
    'PLANNED': 'Planned',
    'ALLOCATED': 'Workers Allocated',
    'READY': 'Ready for Departure',
    'ACTIVE': 'Journey Active',
    'DELAYED': 'Delayed',
    'ARRIVED': 'Arrived at Destination',
    'CLOSED': 'Journey Closed',
    'Active': 'Journey Active',
    'Completed': 'Completed',
  };

  static const List<String> validStates = [
    'PLANNED', 'ALLOCATED', 'READY', 'ACTIVE', 'DELAYED', 'ARRIVED', 'CLOSED'
  ];

  static const Map<String, List<String>> validTransitions = {
    'PLANNED': ['ALLOCATED'],
    'ALLOCATED': ['READY'],
    'READY': ['ACTIVE'],
    'ACTIVE': ['DELAYED', 'ARRIVED'],
    'DELAYED': ['ACTIVE', 'ARRIVED'],
    'ARRIVED': ['CLOSED'],
    'CLOSED': [],
  };

  bool canTransitionTo(String targetState) {
    return validTransitions[status]?.contains(targetState) ?? false;
  }

  String get stateLabel => stateLabels[status] ?? status;

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
    this.status = 'PLANNED',
    this.scheduledDeparture,
    this.actualDeparture,
    this.actualArrival,
    this.journeyStartTime,
    this.journeyEndTime,
    this.delayMinutes = 0,
    this.journeyTimeline = const [],
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
      status: json['status'] as String? ?? 'PLANNED',
      scheduledDeparture: json['scheduledDeparture'] as String?,
      actualDeparture: json['actualDeparture'] as String?,
      actualArrival: json['actualArrival'] as String?,
      journeyStartTime: json['journeyStartTime'] as String?,
      journeyEndTime: json['journeyEndTime'] as String?,
      delayMinutes: json['delayMinutes'] as int? ?? 0,
      journeyTimeline: (json['journeyTimeline'] as List<dynamic>?)
              ?.map((e) => JourneyTimelineEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
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
      'delayMinutes': delayMinutes,
      'journeyTimeline': journeyTimeline.map((e) => e.toJson()).toList(),
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
    int? delayMinutes,
    List<JourneyTimelineEntry>? journeyTimeline,
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
      delayMinutes: delayMinutes ?? this.delayMinutes,
      journeyTimeline: journeyTimeline ?? this.journeyTimeline,
    );
  }
}

class JourneyTimelineEntry {
  final String? fromState;
  final String toState;
  final String timestamp;
  final String? actorId;
  final String? actorName;
  final String? actorRole;
  final String? remarks;

  JourneyTimelineEntry({
    this.fromState,
    required this.toState,
    required this.timestamp,
    this.actorId,
    this.actorName,
    this.actorRole,
    this.remarks,
  });

  factory JourneyTimelineEntry.fromJson(Map<String, dynamic> json) {
    return JourneyTimelineEntry(
      fromState: json['fromState'] as String?,
      toState: json['toState'] as String? ?? json['state'] as String? ?? '',
      timestamp: json['timestamp'] as String? ?? DateTime.now().toIso8601String(),
      actorId: json['actorId'] as String?,
      actorName: json['actorName'] as String?,
      actorRole: json['actorRole'] as String?,
      remarks: json['remarks'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (fromState != null) 'fromState': fromState,
      'toState': toState,
      'timestamp': timestamp,
      if (actorId != null) 'actorId': actorId,
      if (actorName != null) 'actorName': actorName,
      if (actorRole != null) 'actorRole': actorRole,
      if (remarks != null) 'remarks': remarks,
    };
  }

  DateTime get dateTime => DateTime.parse(timestamp);

  String get formattedTime {
    final dt = dateTime;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String get formattedDate {
    final dt = dateTime;
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class CoachAssignment {
  final int coachPosition;
  final String coachType;
  final String? workerId;
  final String? workerName;
  final String? workerRole;
  final String? attendantId;
  final String? attendantName;
  final List<String>? tasks;

  CoachAssignment({
    required this.coachPosition,
    required this.coachType,
    this.workerId,
    this.workerName,
    this.workerRole,
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
      workerRole: json['workerRole'] as String?,
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
      if (workerRole != null && workerRole!.isNotEmpty) 'workerRole': workerRole,
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
    String? workerRole,
    String? attendantId,
    String? attendantName,
    List<String>? tasks,
  }) {
    return CoachAssignment(
      coachPosition: coachPosition ?? this.coachPosition,
      coachType: coachType ?? this.coachType,
      workerId: workerId ?? this.workerId,
      workerName: workerName ?? this.workerName,
      workerRole: workerRole ?? this.workerRole,
      attendantId: attendantId ?? this.attendantId,
      attendantName: attendantName ?? this.attendantName,
      tasks: tasks ?? this.tasks,
    );
  }
}
