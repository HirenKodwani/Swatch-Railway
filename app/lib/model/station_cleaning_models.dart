import 'station_models.dart';

enum AttendanceStatus { present, absent, late, halfDay, onLeave }
enum CaptureMode { biometric, manual, api, autoFlag }
enum DailyActivityStatus { pending, inProgress, completed, partiallyCompleted, rejected, resubmitted, approved }
enum DeficiencyStatus { open, closed, railwayVerified }

class StationAttendance {
  final String attendanceId;
  final String stationId;
  final String stationName;
  final String workerId;
  final String workerName;
  final String date;
  final String shift;
  final AttendanceStatus status;
  final CaptureMode captureMode;
  final bool isManual;
  final bool isLate;
  final String photoUrl;
  final String reason;
  final String markedBy;
  final String markedByName;
  final DateTime markedAt;

  StationAttendance({
    required this.attendanceId,
    required this.stationId,
    required this.stationName,
    required this.workerId,
    required this.workerName,
    required this.date,
    required this.shift,
    required this.status,
    required this.captureMode,
    required this.isManual,
    required this.isLate,
    required this.photoUrl,
    required this.reason,
    required this.markedBy,
    required this.markedByName,
    required this.markedAt,
  });

  factory StationAttendance.fromJson(Map<String, dynamic> json) => StationAttendance(
    attendanceId: json['attendanceId'] ?? '',
    stationId: json['stationId'] ?? '',
    stationName: json['stationName'] ?? '',
    workerId: json['workerId'] ?? '',
    workerName: json['workerName'] ?? '',
    date: json['date'] ?? '',
    shift: json['shift'] ?? '',
    status: AttendanceStatus.values.firstWhere(
      (e) => e.name == _toCamelCase(json['status'] ?? 'present'),
      orElse: () => AttendanceStatus.present,
    ),
    captureMode: CaptureMode.values.firstWhere(
      (e) => e.name == _toCamelCase(json['captureMode'] ?? 'manual'),
      orElse: () => CaptureMode.manual,
    ),
    isManual: json['isManual'] ?? true,
    isLate: json['isLate'] ?? false,
    photoUrl: json['photoUrl'] ?? '',
    reason: json['reason'] ?? '',
    markedBy: json['markedBy'] ?? '',
    markedByName: json['markedByName'] ?? '',
    markedAt: json['markedAt'] != null ? DateTime.parse(json['markedAt']) : DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'attendanceId': attendanceId,
    'stationId': stationId,
    'stationName': stationName,
    'workerId': workerId,
    'workerName': workerName,
    'date': date,
    'shift': shift,
    'status': status.name,
    'captureMode': captureMode.name,
    'isManual': isManual,
    'isLate': isLate,
    'photoUrl': photoUrl,
    'reason': reason,
    'markedBy': markedBy,
    'markedByName': markedByName,
    'markedAt': markedAt.toIso8601String(),
  };
}

class DailyActivityRecord {
  final String uid;
  final String stationId;
  final String stationName;
  final String areaId;
  final String areaName;
  final String activityId;
  final String activityName;
  final String date;
  final String shift;
  final String scheduledFrequency;
  final DailyActivityStatus status;
  final String beforePhotoUrl;
  final String afterPhotoUrl;
  final String remarks;
  final String submittedBy;
  final String submittedByName;
  final DateTime? submittedAt;
  final String? verifiedBy;
  final String? verifiedByName;
  final DateTime? verifiedAt;
  final String? rejectionReason;
  final String? resubmissionRemarks;

  DailyActivityRecord({
    required this.uid,
    required this.stationId,
    required this.stationName,
    required this.areaId,
    required this.areaName,
    required this.activityId,
    required this.activityName,
    required this.date,
    required this.shift,
    required this.scheduledFrequency,
    required this.status,
    required this.beforePhotoUrl,
    required this.afterPhotoUrl,
    required this.remarks,
    required this.submittedBy,
    required this.submittedByName,
    this.submittedAt,
    this.verifiedBy,
    this.verifiedByName,
    this.verifiedAt,
    this.rejectionReason,
    this.resubmissionRemarks,
  });

  factory DailyActivityRecord.fromJson(Map<String, dynamic> json) => DailyActivityRecord(
    uid: json['uid'] ?? '',
    stationId: json['stationId'] ?? '',
    stationName: json['stationName'] ?? '',
    areaId: json['areaId'] ?? '',
    areaName: json['areaName'] ?? '',
    activityId: json['activityId'] ?? '',
    activityName: json['activityName'] ?? '',
    date: json['date'] ?? '',
    shift: json['shift'] ?? '',
    scheduledFrequency: json['scheduledFrequency'] ?? '',
    status: DailyActivityStatus.values.firstWhere(
      (e) => e.name == _toCamelCase(json['status'] ?? 'pending'),
      orElse: () => DailyActivityStatus.pending,
    ),
    beforePhotoUrl: json['beforePhotoUrl'] ?? '',
    afterPhotoUrl: json['afterPhotoUrl'] ?? '',
    remarks: json['remarks'] ?? '',
    submittedBy: json['submittedBy'] ?? '',
    submittedByName: json['submittedByName'] ?? '',
    submittedAt: json['submittedAt'] != null ? DateTime.parse(json['submittedAt']) : null,
    verifiedBy: json['verifiedBy'],
    verifiedByName: json['verifiedByName'],
    verifiedAt: json['verifiedAt'] != null ? DateTime.parse(json['verifiedAt']) : null,
    rejectionReason: json['rejectionReason'],
    resubmissionRemarks: json['resubmissionRemarks'],
  );

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'stationId': stationId,
    'stationName': stationName,
    'areaId': areaId,
    'areaName': areaName,
    'activityId': activityId,
    'activityName': activityName,
    'date': date,
    'shift': shift,
    'scheduledFrequency': scheduledFrequency,
    'status': status.name,
    'beforePhotoUrl': beforePhotoUrl,
    'afterPhotoUrl': afterPhotoUrl,
    'remarks': remarks,
    'submittedBy': submittedBy,
    'submittedByName': submittedByName,
    if (submittedAt != null) 'submittedAt': submittedAt!.toIso8601String(),
    if (verifiedBy != null) 'verifiedBy': verifiedBy,
    if (verifiedByName != null) 'verifiedByName': verifiedByName,
    if (verifiedAt != null) 'verifiedAt': verifiedAt!.toIso8601String(),
    if (rejectionReason != null) 'rejectionReason': rejectionReason,
    if (resubmissionRemarks != null) 'resubmissionRemarks': resubmissionRemarks,
  };
}

class StationBillingPack {
  final String uid;
  final String contractId;
  final String stationId;
  final String stationName;
  final int month;
  final int year;
  final String contractNumber;
  final String contractorName;
  final int monthlyContractValue;
  final Map<String, dynamic> attendanceSummary;
  final Map<String, dynamic> activitySummary;
  final Map<String, dynamic> scorecardSummary;
  final Map<String, dynamic> complaintSummary;
  final Map<String, dynamic> feedbackSummary;
  final Map<String, dynamic> machineSummary;
  final Map<String, dynamic> penalties;
  final int billableAmount;
  final String status;
  final Map<String, dynamic> complianceChecklist;
  final String generatedBy;
  final String generatedByName;
  final DateTime generatedAt;

  StationBillingPack({
    required this.uid,
    required this.contractId,
    required this.stationId,
    required this.stationName,
    required this.month,
    required this.year,
    required this.contractNumber,
    required this.contractorName,
    required this.monthlyContractValue,
    required this.attendanceSummary,
    required this.activitySummary,
    required this.scorecardSummary,
    required this.complaintSummary,
    required this.feedbackSummary,
    required this.machineSummary,
    required this.penalties,
    required this.billableAmount,
    required this.status,
    required this.complianceChecklist,
    required this.generatedBy,
    required this.generatedByName,
    required this.generatedAt,
  });

  factory StationBillingPack.fromJson(Map<String, dynamic> json) => StationBillingPack(
    uid: json['uid'] ?? '',
    contractId: json['contractId'] ?? '',
    stationId: json['stationId'] ?? '',
    stationName: json['stationName'] ?? '',
    month: json['month'] ?? 1,
    year: json['year'] ?? 2026,
    contractNumber: json['contractNumber'] ?? '',
    contractorName: json['contractorName'] ?? '',
    monthlyContractValue: json['monthlyContractValue'] ?? 0,
    attendanceSummary: json['attendanceSummary'] ?? {},
    activitySummary: json['activitySummary'] ?? {},
    scorecardSummary: json['scorecardSummary'] ?? {},
    complaintSummary: json['complaintSummary'] ?? {},
    feedbackSummary: json['feedbackSummary'] ?? {},
    machineSummary: json['machineSummary'] ?? {},
    penalties: json['penalties'] ?? {},
    billableAmount: json['billableAmount'] ?? 0,
    status: json['status'] ?? 'DRAFT',
    complianceChecklist: json['complianceChecklist'] ?? {},
    generatedBy: json['generatedBy'] ?? '',
    generatedByName: json['generatedByName'] ?? '',
    generatedAt: json['generatedAt'] != null ? DateTime.parse(json['generatedAt']) : DateTime.now(),
  );
}

class StationInspection {
  final String uid;
  final String stationId;
  final String stationName;
  final String? platformId;
  final String? areaId;
  final String inspectionType;
  final String scheduledDate;
  final String inspectorId;
  final String inspectorName;
  final String status;
  final Map<String, dynamic> ratings;
  final int? overallScore;
  final String? grade;
  final String remarks;
  final List<String> photos;
  final List<Deficiency> deficiencies;

  StationInspection({
    required this.uid,
    required this.stationId,
    required this.stationName,
    this.platformId,
    this.areaId,
    required this.inspectionType,
    required this.scheduledDate,
    required this.inspectorId,
    required this.inspectorName,
    required this.status,
    required this.ratings,
    this.overallScore,
    this.grade,
    required this.remarks,
    required this.photos,
    required this.deficiencies,
  });

  factory StationInspection.fromJson(Map<String, dynamic> json) => StationInspection(
    uid: json['uid'] ?? '',
    stationId: json['stationId'] ?? '',
    stationName: json['stationName'] ?? '',
    platformId: json['platformId'],
    areaId: json['areaId'],
    inspectionType: json['inspectionType'] ?? 'daily',
    scheduledDate: json['scheduledDate'] ?? '',
    inspectorId: json['inspectorId'] ?? '',
    inspectorName: json['inspectorName'] ?? '',
    status: json['status'] ?? '',
    ratings: json['ratings'] ?? {},
    overallScore: json['overallScore'],
    grade: json['grade'],
    remarks: json['remarks'] ?? '',
    photos: List<String>.from(json['photos'] ?? []),
    deficiencies: (json['deficiencies'] as List?)?.map((e) => Deficiency.fromJson(e)).toList() ?? [],
  );
}

class Deficiency {
  final String defId;
  final String area;
  final String description;
  final String severity;
  final String? assignedTo;
  final String assignedToName;
  final DeficiencyStatus closureStatus;
  final String? closureProof;
  final String? closureRemarks;
  final DateTime? closedAt;
  final String? closedBy;

  Deficiency({
    required this.defId,
    required this.area,
    required this.description,
    required this.severity,
    this.assignedTo,
    required this.assignedToName,
    required this.closureStatus,
    this.closureProof,
    this.closureRemarks,
    this.closedAt,
    this.closedBy,
  });

  factory Deficiency.fromJson(Map<String, dynamic> json) => Deficiency(
    defId: json['defId'] ?? '',
    area: json['area'] ?? '',
    description: json['description'] ?? '',
    severity: json['severity'] ?? 'medium',
    assignedTo: json['assignedTo'],
    assignedToName: json['assignedToName'] ?? '',
    closureStatus: DeficiencyStatus.values.firstWhere(
      (e) => e.name == _toCamelCase(json['closureStatus'] ?? 'open'),
      orElse: () => DeficiencyStatus.open,
    ),
    closureProof: json['closureProof'],
    closureRemarks: json['closureRemarks'],
    closedAt: json['closedAt'] != null ? DateTime.parse(json['closedAt']) : null,
    closedBy: json['closedBy'],
  );
}

String _toCamelCase(String text) {
  final parts = text.split('_');
  if (parts.isEmpty) return '';
  final buffer = StringBuffer(parts[0].toLowerCase());
  for (var i = 1; i < parts.length; i++) {
    if (parts[i].isEmpty) continue;
    buffer.write(parts[i][0].toUpperCase());
    buffer.write(parts[i].substring(1).toLowerCase());
  }
  return buffer.toString();
}
