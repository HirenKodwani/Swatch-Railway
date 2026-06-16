enum FormType { coach, premise }
enum CleaningFormStatus { draft, submitted, approved, scoringInProgress, scored, contractorApproved, autoApproved, locked, rejected }
enum CleaningShift { morning, evening, night }

class CleaningForm {
  String? uid;
  final String formId;
  final FormType formType;
  final String division;
  final String depot;
  final String contractId;
  final String contractNumber;
  final String entityId;
  final String entityName;
  final String submittedBy;
  final String submittedByName;
  CleaningFormStatus status;
  final String cleaningDate;
  final String cleaningShift;
  final String startTime;
  final String endTime;
  final int manpowerCount;
  final int machineCount;
  final String remarks;
  final double latitude;
  final double longitude;
  final String deviceId;
  final String gpsAddress;
  final DateTime createdAt;
  DateTime? updatedAt;
  String? approvedBy;
  String? approvedByName;
  DateTime? approvedAt;
  String? rejectedBy;
  String? rejectedByName;
  DateTime? rejectedAt;
  String? rejectionReason;
  double? score;
  String? grade;
  DateTime? scoringAt;
  String? scoredBy;
  String? scoredByName;
  DateTime? lockedAt;
  DateTime? autoApprovedAt;
  final List<CleaningPhoto> photos;
  final List<CleaningAuditLog> auditLog;
  Map<String, dynamic>? coachDetails;
  Map<String, dynamic>? premiseDetails;
  Map<String, dynamic>? scoringData;

  CleaningForm({
    this.uid,
    required this.formId,
    required this.formType,
    required this.division,
    required this.depot,
    required this.contractId,
    required this.contractNumber,
    required this.entityId,
    required this.entityName,
    required this.submittedBy,
    required this.submittedByName,
    this.status = CleaningFormStatus.draft,
    required this.cleaningDate,
    required this.cleaningShift,
    required this.startTime,
    required this.endTime,
    required this.manpowerCount,
    required this.machineCount,
    this.remarks = '',
    this.latitude = 0,
    this.longitude = 0,
    this.deviceId = '',
    this.gpsAddress = '',
    DateTime? createdAt,
    this.updatedAt,
    this.approvedBy,
    this.approvedByName,
    this.approvedAt,
    this.rejectedBy,
    this.rejectedByName,
    this.rejectedAt,
    this.rejectionReason,
    this.score,
    this.grade,
    this.scoringAt,
    this.scoredBy,
    this.scoredByName,
    this.lockedAt,
    this.autoApprovedAt,
    this.photos = const [],
    this.auditLog = const [],
    this.coachDetails,
    this.premiseDetails,
    this.scoringData,
  }) : createdAt = createdAt ?? DateTime.now();

  String get statusLabel {
    switch (status) {
      case CleaningFormStatus.draft: return 'Draft';
      case CleaningFormStatus.submitted: return 'Submitted';
      case CleaningFormStatus.approved: return 'Approved';
      case CleaningFormStatus.scoringInProgress: return 'Scoring In Progress';
      case CleaningFormStatus.scored: return 'Scored';
      case CleaningFormStatus.contractorApproved: return 'Contractor Approved';
      case CleaningFormStatus.autoApproved: return 'Auto Approved';
      case CleaningFormStatus.locked: return 'Locked';
      case CleaningFormStatus.rejected: return 'Rejected';
    }
  }

  String get formTypeLabel => formType == FormType.coach ? 'Coach Cleaning' : 'Premise Cleaning';

  Map<String, dynamic> toJson() => {
    if (uid != null) 'uid': uid,
    'formId': formId,
    'formType': formType.name,
    'division': division,
    'depot': depot,
    'contractId': contractId,
    'contractNumber': contractNumber,
    'entityId': entityId,
    'entityName': entityName,
    'submittedBy': submittedBy,
    'submittedByName': submittedByName,
    'status': status.name,
    'cleaningDate': cleaningDate,
    'cleaningShift': cleaningShift,
    'startTime': startTime,
    'endTime': endTime,
    'manpowerCount': manpowerCount,
    'machineCount': machineCount,
    'remarks': remarks,
    'latitude': latitude,
    'longitude': longitude,
    'deviceId': deviceId,
    'gpsAddress': gpsAddress,
    'createdAt': createdAt.toIso8601String(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    if (approvedBy != null) 'approvedBy': approvedBy,
    if (approvedByName != null) 'approvedByName': approvedByName,
    if (approvedAt != null) 'approvedAt': approvedAt!.toIso8601String(),
    if (rejectedBy != null) 'rejectedBy': rejectedBy,
    if (rejectedByName != null) 'rejectedByName': rejectedByName,
    if (rejectedAt != null) 'rejectedAt': rejectedAt!.toIso8601String(),
    if (rejectionReason != null) 'rejectionReason': rejectionReason,
    if (score != null) 'score': score,
    if (grade != null) 'grade': grade,
    if (scoringAt != null) 'scoringAt': scoringAt!.toIso8601String(),
    if (scoredBy != null) 'scoredBy': scoredBy,
    if (scoredByName != null) 'scoredByName': scoredByName,
    if (lockedAt != null) 'lockedAt': lockedAt!.toIso8601String(),
    if (autoApprovedAt != null) 'autoApprovedAt': autoApprovedAt!.toIso8601String(),
    'photos': photos.map((p) => p.toJson()).toList(),
    'auditLog': auditLog.map((a) => a.toJson()).toList(),
    if (coachDetails != null) 'coachDetails': coachDetails,
    if (premiseDetails != null) 'premiseDetails': premiseDetails,
    if (scoringData != null) 'scoringData': scoringData,
  };

  factory CleaningForm.fromJson(Map<String, dynamic> json) => CleaningForm(
    uid: json['uid'],
    formId: json['formId'] ?? '',
    formType: FormType.values.firstWhere((e) => e.name == json['formType'], orElse: () => FormType.coach),
    division: json['division'] ?? '',
    depot: json['depot'] ?? '',
    contractId: json['contractId'] ?? '',
    contractNumber: json['contractNumber'] ?? '',
    entityId: json['entityId'] ?? '',
    entityName: json['entityName'] ?? '',
    submittedBy: json['submittedBy'] ?? '',
    submittedByName: json['submittedByName'] ?? '',
    status: CleaningFormStatus.values.firstWhere((e) => e.name == json['status'], orElse: () => CleaningFormStatus.draft),
    cleaningDate: json['cleaningDate'] ?? '',
    cleaningShift: json['cleaningShift'] ?? '',
    startTime: json['startTime'] ?? '',
    endTime: json['endTime'] ?? '',
    manpowerCount: json['manpowerCount'] ?? 0,
    machineCount: json['machineCount'] ?? 0,
    remarks: json['remarks'] ?? '',
    latitude: (json['latitude'] ?? 0).toDouble(),
    longitude: (json['longitude'] ?? 0).toDouble(),
    deviceId: json['deviceId'] ?? '',
    gpsAddress: json['gpsAddress'] ?? '',
    createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    approvedBy: json['approvedBy'],
    approvedByName: json['approvedByName'],
    approvedAt: json['approvedAt'] != null ? DateTime.parse(json['approvedAt']) : null,
    rejectedBy: json['rejectedBy'],
    rejectedByName: json['rejectedByName'],
    rejectedAt: json['rejectedAt'] != null ? DateTime.parse(json['rejectedAt']) : null,
    rejectionReason: json['rejectionReason'],
    score: (json['score'] as num?)?.toDouble(),
    grade: json['grade'],
    scoringAt: json['scoringAt'] != null ? DateTime.parse(json['scoringAt']) : null,
    scoredBy: json['scoredBy'],
    scoredByName: json['scoredByName'],
    lockedAt: json['lockedAt'] != null ? DateTime.parse(json['lockedAt']) : null,
    autoApprovedAt: json['autoApprovedAt'] != null ? DateTime.parse(json['autoApprovedAt']) : null,
    photos: (json['photos'] as List?)?.map((p) => CleaningPhoto.fromJson(p)).toList() ?? [],
    auditLog: (json['auditLog'] as List?)?.map((a) => CleaningAuditLog.fromJson(a)).toList() ?? [],
    coachDetails: json['coachDetails'] as Map<String, dynamic>?,
    premiseDetails: json['premiseDetails'] as Map<String, dynamic>?,
    scoringData: json['scoringData'] as Map<String, dynamic>?,
  );
}

class CleaningPhoto {
  final String url;
  final String type; // 'before', 'after'
  final DateTime timestamp;
  final double latitude;
  final double longitude;

  CleaningPhoto({
    required this.url,
    required this.type,
    DateTime? timestamp,
    this.latitude = 0,
    this.longitude = 0,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'url': url,
    'type': type,
    'timestamp': timestamp.toIso8601String(),
    'latitude': latitude,
    'longitude': longitude,
  };

  factory CleaningPhoto.fromJson(Map<String, dynamic> json) => CleaningPhoto(
    url: json['url'] ?? '',
    type: json['type'] ?? 'before',
    timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now(),
    latitude: (json['latitude'] ?? 0).toDouble(),
    longitude: (json['longitude'] ?? 0).toDouble(),
  );
}

class CleaningAuditLog {
  final String action;
  final String performedBy;
  final String performedByName;
  final DateTime timestamp;
  final String details;
  final Map<String, dynamic>? metadata;

  CleaningAuditLog({
    required this.action,
    required this.performedBy,
    required this.performedByName,
    DateTime? timestamp,
    this.details = '',
    this.metadata,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'action': action,
    'performedBy': performedBy,
    'performedByName': performedByName,
    'timestamp': timestamp.toIso8601String(),
    'details': details,
    if (metadata != null) 'metadata': metadata,
  };

  factory CleaningAuditLog.fromJson(Map<String, dynamic> json) => CleaningAuditLog(
    action: json['action'] ?? '',
    performedBy: json['performedBy'] ?? '',
    performedByName: json['performedByName'] ?? '',
    timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now(),
    details: json['details'] ?? '',
    metadata: json['metadata'] as Map<String, dynamic>?,
  );
}

class CleaningDashboardSummary {
  final int draftForms;
  final int submittedForms;
  final int approvedForms;
  final int rejectedForms;
  final int scoredForms;
  final int lockedForms;
  final int pendingReview;
  final int scoringPending;
  final double averageScore;
  final double totalManpower;
  final double totalMachine;

  CleaningDashboardSummary({
    this.draftForms = 0,
    this.submittedForms = 0,
    this.approvedForms = 0,
    this.rejectedForms = 0,
    this.scoredForms = 0,
    this.lockedForms = 0,
    this.pendingReview = 0,
    this.scoringPending = 0,
    this.averageScore = 0,
    this.totalManpower = 0,
    this.totalMachine = 0,
  });

  factory CleaningDashboardSummary.fromJson(Map<String, dynamic> json) => CleaningDashboardSummary(
    draftForms: json['draftForms'] ?? 0,
    submittedForms: json['submittedForms'] ?? 0,
    approvedForms: json['approvedForms'] ?? 0,
    rejectedForms: json['rejectedForms'] ?? 0,
    scoredForms: json['scoredForms'] ?? 0,
    lockedForms: json['lockedForms'] ?? 0,
    pendingReview: json['pendingReview'] ?? 0,
    scoringPending: json['scoringPending'] ?? 0,
    averageScore: (json['averageScore'] ?? 0).toDouble(),
    totalManpower: (json['totalManpower'] ?? 0).toDouble(),
    totalMachine: (json['totalMachine'] ?? 0).toDouble(),
  );
}

class ScoringCriterion {
  final String name;
  final double maxScore;
  double score;
  final String remarks;

  ScoringCriterion({
    required this.name,
    this.maxScore = 10,
    this.score = 0,
    this.remarks = '',
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'maxScore': maxScore,
    'score': score,
    'remarks': remarks,
  };

  factory ScoringCriterion.fromJson(Map<String, dynamic> json) => ScoringCriterion(
    name: json['name'] ?? '',
    maxScore: (json['maxScore'] ?? 10).toDouble(),
    score: (json['score'] ?? 0).toDouble(),
    remarks: json['remarks'] ?? '',
  );
}

class CleaningScoringData {
  final List<ScoringCriterion> criteria;
  final double totalScore;
  final double maxTotalScore;
  final String remarks;
  final String grade;

  CleaningScoringData({
    this.criteria = const [],
    this.totalScore = 0,
    this.maxTotalScore = 100,
    this.remarks = '',
    this.grade = '',
  });

  Map<String, dynamic> toJson() => {
    'criteria': criteria.map((c) => c.toJson()).toList(),
    'totalScore': totalScore,
    'maxTotalScore': maxTotalScore,
    'remarks': remarks,
    'grade': grade,
  };

  factory CleaningScoringData.fromJson(Map<String, dynamic> json) => CleaningScoringData(
    criteria: (json['criteria'] as List?)?.map((c) => ScoringCriterion.fromJson(c)).toList() ?? [],
    totalScore: (json['totalScore'] ?? 0).toDouble(),
    maxTotalScore: (json['maxTotalScore'] ?? 100).toDouble(),
    remarks: json['remarks'] ?? '',
    grade: json['grade'] ?? '',
  );
}

const Map<String, List<Map<String, dynamic>>> cleaningActivities = {
  'coach': [
    {'category': 'Internal Cleaning', 'items': ['Floor Cleaning', 'Seat Cleaning', 'Berth Cleaning', 'Window Cleaning', 'Dust Removal', 'Fan Cleaning']},
    {'category': 'Toilet Cleaning', 'items': ['Toilet Wash', 'Wash Basin Cleaning', 'Water Availability', 'Odour Control', 'Consumables Availability']},
    {'category': 'External Cleaning', 'items': ['Body Wash', 'Glass Cleaning', 'Stain Removal']},
    {'category': 'Amenities', 'items': ['Water Tank Filled', 'Toiletries Refilled', 'Dustbins Available']},
  ],
  'premise': [
    {'category': 'Housekeeping', 'items': ['Platform Cleaning', 'Office Cleaning', 'Waiting Hall Cleaning', 'Staircase Cleaning', 'Dustbin Cleaning']},
    {'category': 'Pit Line Cleaning', 'items': ['Track Area Cleaning', 'Pit Area Cleaning', 'Waste Removal', 'Water Removal']},
    {'category': 'Garbage Disposal', 'items': ['Collection', 'Segregation', 'Disposal Compliance']},
  ],
};
