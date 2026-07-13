class TrainModel {
  final String? uid;
  final String? trainNo;
  final String? trainName;
  final String? origin;
  final String? destination;
  final List<String> days;
  final String zone;
  final String division;
  final String? depot;
  final String status;
  final List<String> trainApplicableFor;

  final String? outboundTrainNo;
  final String? inboundTrainNo;
  final String? outboundDurationStr;
  final String? inboundDurationStr;
  final String? layoverDestStr;
  final String? layoverOriginStr;
  final String? journeyStartTime;

  final DateTime? createdAt;
  final String? createdBy;
  final String? createdByName;
  final DateTime? updatedAt;
  final String? updatedBy;
  final String? updatedByName;

  TrainModel({
    this.uid,
    this.trainNo,
    this.trainName,
    this.origin,
    this.destination,
    required this.days,
    required this.zone,
    required this.division,
    this.depot,
    required this.status,
    this.trainApplicableFor = const [],

    this.outboundTrainNo,
    this.inboundTrainNo,
    this.outboundDurationStr,
    this.inboundDurationStr,
    this.layoverDestStr,
    this.layoverOriginStr,
    this.journeyStartTime,

    this.createdAt,
    this.createdBy,
    this.createdByName,
    this.updatedAt,
    this.updatedBy,
    this.updatedByName,
  });

  Map<String, dynamic> toJson() {
    return {
      if (trainNo != null && trainNo!.isNotEmpty) 'trainNo': trainNo,
      if (trainName != null && trainName!.isNotEmpty) 'trainName': trainName,
      if (origin != null && origin!.isNotEmpty) 'origin': origin,
      if (destination != null && destination!.isNotEmpty)
        'destination': destination,
      'days': days,
      'zone': zone,
      'division': division,
      if (depot != null && depot!.isNotEmpty) 'depot': depot,
      'status': status,
      'TrainApplicableFor': trainApplicableFor,

      if (outboundTrainNo != null && outboundTrainNo!.isNotEmpty)
        'outboundTrainNo': outboundTrainNo,
      if (inboundTrainNo != null && inboundTrainNo!.isNotEmpty)
        'inboundTrainNo': inboundTrainNo,
      if (outboundDurationStr != null && outboundDurationStr!.isNotEmpty)
        'outboundDurationStr': outboundDurationStr,
      if (inboundDurationStr != null && inboundDurationStr!.isNotEmpty)
        'inboundDurationStr': inboundDurationStr,
      if (layoverDestStr != null && layoverDestStr!.isNotEmpty)
        'layoverDestStr': layoverDestStr,
      if (layoverOriginStr != null && layoverOriginStr!.isNotEmpty)
        'layoverOriginStr': layoverOriginStr,
      if (journeyStartTime != null && journeyStartTime!.isNotEmpty)
        'journeyStartTime': journeyStartTime,
    };
  }

  factory TrainModel.fromJson(Map<String, dynamic> json) {
    return TrainModel(
      uid: json['uid']?.toString(),
      trainNo: json['trainNo']?.toString(),
      trainName: json['trainName']?.toString(),
      origin: json['origin']?.toString(),
      destination: json['destination']?.toString(),
      days:
          (json['days'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          [],
      zone: json['zone']?.toString() ?? '',
      division: json['division']?.toString() ?? '',
      depot: json['depot']?.toString(),
      status: json['status']?.toString() ?? 'active',
      trainApplicableFor:
          (json['TrainApplicableFor'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],

      outboundTrainNo: json['outboundTrainNo']?.toString(),
      inboundTrainNo: json['inboundTrainNo']?.toString(),
      outboundDurationStr: json['outboundDurationStr']?.toString(),
      inboundDurationStr: json['inboundDurationStr']?.toString(),
      layoverDestStr: json['layoverDestStr']?.toString(),
      layoverOriginStr: json['layoverOriginStr']?.toString(),
      journeyStartTime: json['journeyStartTime']?.toString(),

      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      createdBy: json['createdBy']?.toString(),
      createdByName: json['createdByName']?.toString(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      updatedBy: json['updatedBy']?.toString(),
      updatedByName: json['updatedByName']?.toString(),
    );
  }

  TrainModel copyWith({
    String? uid,
    String? trainNo,
    String? trainName,
    String? origin,
    String? destination,
    List<String>? days,
    String? zone,
    String? division,
    String? depot,
    String? status,
    List<String>? trainApplicableFor,

    String? outboundTrainNo,
    String? inboundTrainNo,
    String? outboundDurationStr,
    String? inboundDurationStr,
    String? layoverDestStr,
    String? layoverOriginStr,
    String? journeyStartTime,

    DateTime? createdAt,
    String? createdBy,
    String? createdByName,
    DateTime? updatedAt,
    String? updatedBy,
    String? updatedByName,
  }) {
    return TrainModel(
      uid: uid ?? this.uid,
      trainNo: trainNo ?? this.trainNo,
      trainName: trainName ?? this.trainName,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      days: days ?? this.days,
      zone: zone ?? this.zone,
      division: division ?? this.division,
      depot: depot ?? this.depot,
      status: status ?? this.status,
      trainApplicableFor: trainApplicableFor ?? this.trainApplicableFor,

      outboundTrainNo: outboundTrainNo ?? this.outboundTrainNo,
      inboundTrainNo: inboundTrainNo ?? this.inboundTrainNo,
      outboundDurationStr: outboundDurationStr ?? this.outboundDurationStr,
      inboundDurationStr: inboundDurationStr ?? this.inboundDurationStr,
      layoverDestStr: layoverDestStr ?? this.layoverDestStr,
      layoverOriginStr: layoverOriginStr ?? this.layoverOriginStr,
      journeyStartTime: journeyStartTime ?? this.journeyStartTime,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedByName: updatedByName ?? this.updatedByName,
    );
  }
}
