// class TrainInstanceModel {
//   final String id;
//   final String trainId;
//   final String trainNo;
//   final String trainName;
//   final String downTrainNo;
//   final String upTrainNo;
//   final int instanceNumber;
//   final DateTime startDate;
//   final DateTime endDate;
//   final String status; // Pending, Active, Closed, Completed
//   final int cycleLength;
//   final List<CoachAssignment> coachAssignments;
//   final List<String> runningDays;
//   final String createdBy;
//   final DateTime createdAt;
//   final String? modifiedBy;
//   final DateTime? modifiedAt;
//   final Map<String, dynamic>? metadata;
//
//   TrainInstanceModel({
//     required this.id,
//     required this.trainId,
//     required this.trainNo,
//     required this.trainName,
//     required this.downTrainNo,
//     required this.upTrainNo,
//     required this.instanceNumber,
//     required this.startDate,
//     required this.endDate,
//     required this.status,
//     required this.cycleLength,
//     required this.coachAssignments,
//     required this.runningDays,
//     required this.createdBy,
//     required this.createdAt,
//     this.modifiedBy,
//     this.modifiedAt,
//     this.metadata,
//   });
//
//   factory TrainInstanceModel.fromJson(Map<String, dynamic> json) {
//     return TrainInstanceModel(
//       id: json['id'] ?? '',
//       trainId: json['trainId'] ?? '',
//       trainNo: json['trainNo'] ?? '',
//       trainName: json['trainName'] ?? '',
//       downTrainNo: json['downTrainNo'] ?? '',
//       upTrainNo: json['upTrainNo'] ?? '',
//       instanceNumber: json['instanceNumber'] ?? 1,
//       startDate: DateTime.parse(json['startDate'] ?? DateTime.now().toString()),
//       endDate: DateTime.parse(json['endDate'] ?? DateTime.now().toString()),
//       status: json['status'] ?? 'Pending',
//       cycleLength: json['cycleLength'] ?? 1,
//       coachAssignments: (json['coachAssignments'] as List?)
//               ?.map((c) => CoachAssignment.fromJson(c))
//               .toList() ??
//           [],
//       runningDays: List<String>.from(json['runningDays'] ?? []),
//       createdBy: json['createdBy'] ?? '',
//       createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toString()),
//       modifiedBy: json['modifiedBy'],
//       modifiedAt: json['modifiedAt'] != null
//           ? DateTime.parse(json['modifiedAt'])
//           : null,
//       metadata: json['metadata'],
//     );
//   }
//
//   Map<String, dynamic> toJson() => {
//     'id': id,
//     'trainId': trainId,
//     'trainNo': trainNo,
//     'trainName': trainName,
//     'downTrainNo': downTrainNo,
//     'upTrainNo': upTrainNo,
//     'instanceNumber': instanceNumber,
//     'startDate': startDate.toIso8601String(),
//     'endDate': endDate.toIso8601String(),
//     'status': status,
//     'cycleLength': cycleLength,
//     'coachAssignments': coachAssignments.map((c) => c.toJson()).toList(),
//     'runningDays': runningDays,
//     'createdBy': createdBy,
//     'createdAt': createdAt.toIso8601String(),
//     'modifiedBy': modifiedBy,
//     'modifiedAt': modifiedAt?.toIso8601String(),
//     'metadata': metadata,
//   };
// }
//
// class CoachAssignment {
//   final String id;
//   final String coachId;
//   final int position;
//   final String displayNo;
//   final String coachType;
//   final String? assignedJanitorId;
//   final String? assignedWorkerName;
//   final String? roleTag;
//   final String status;
//   final DateTime? assignedDate;
//   final String? notes;
//
//   CoachAssignment({
//     required this.id,
//     required this.coachId,
//     required this.position,
//     required this.displayNo,
//     required this.coachType,
//     this.assignedJanitorId,
//     this.assignedWorkerName,
//     this.roleTag,
//     required this.status,
//     this.assignedDate,
//     this.notes,
//   });
//
//   factory CoachAssignment.fromJson(Map<String, dynamic> json) {
//     return CoachAssignment(
//       id: json['id'] ?? '',
//       coachId: json['coachId'] ?? '',
//       position: json['position'] ?? 0,
//       displayNo: json['displayNo'] ?? '',
//       coachType: json['coachType'] ?? 'General',
//       assignedJanitorId: json['assignedJanitorId'],
//       assignedWorkerName: json['assignedWorkerName'],
//       roleTag: json['roleTag'],
//       status: json['status'] ?? 'Unassigned',
//       assignedDate: json['assignedDate'] != null
//           ? DateTime.parse(json['assignedDate'])
//           : null,
//       notes: json['notes'],
//     );
//   }
//
//   Map<String, dynamic> toJson() => {
//     'id': id,
//     'coachId': coachId,
//     'position': position,
//     'displayNo': displayNo,
//     'coachType': coachType,
//     'assignedJanitorId': assignedJanitorId,
//     'assignedWorkerName': assignedWorkerName,
//     'roleTag': roleTag,
//     'status': status,
//     'assignedDate': assignedDate?.toIso8601String(),
//     'notes': notes,
//   };
// }
//
// class WorkerAssignmentLog {
//   final String id;
//   final String instanceId;
//   final String coachId;
//   final String workerId;
//   final String workerName;
//   final String workerDesignation;
//   final DateTime assignedDate;
//   final DateTime? unassignedDate;
//   final String assignmentReason;
//   final String status;
//   final String? supervisorNotes;
//   final Map<String, dynamic>? completionDetails;
//
//   WorkerAssignmentLog({
//     required this.id,
//     required this.instanceId,
//     required this.coachId,
//     required this.janitorId,
//     required this.janitorName,
//     required this.workerDesignation,
//     required this.assignedDate,
//     this.unassignedDate,
//     required this.assignmentReason,
//     required this.status,
//     this.supervisorNotes,
//     this.completionDetails,
//   });
//
//   factory WorkerAssignmentLog.fromJson(Map<String, dynamic> json) {
//     return WorkerAssignmentLog(
//       id: json['id'] ?? '',
//       instanceId: json['instanceId'] ?? '',
//       coachId: json['coachId'] ?? '',
//       janitorId: json['janitorId'] ?? '',
//       janitorName: json['janitorName'] ?? '',
//       workerDesignation: json['workerDesignation'] ?? '',
//       assignedDate: DateTime.parse(json['assignedDate'] ?? DateTime.now().toString()),
//       unassignedDate: json['unassignedDate'] != null
//           ? DateTime.parse(json['unassignedDate'])
//           : null,
//       assignmentReason: json['assignmentReason'] ?? '',
//       status: json['status'] ?? 'Active',
//       supervisorNotes: json['supervisorNotes'],
//       completionDetails: json['completionDetails'],
//     );
//   }
//
//   Map<String, dynamic> toJson() => {
//     'id': id,
//     'instanceId': instanceId,
//     'coachId': coachId,
//     'workerId': workerId,
//     'workerName': workerName,
//     'workerDesignation': workerDesignation,
//     'assignedDate': assignedDate.toIso8601String(),
//     'unassignedDate': unassignedDate?.toIso8601String(),
//     'assignmentReason': assignmentReason,
//     'status': status,
//     'supervisorNotes': supervisorNotes,
//     'completionDetails': completionDetails,
//   };
// }
//
// class OBHSReport {
//   final String id;
//   final String instanceId;
//   final String trainName;
//   final String trainNo;
//   final int instanceNumber;
//   final DateTime reportDate;
//   final String reportType;
//   final String? specificCoach;
//   final List<ReportEntry> entries;
//   final String generatedBy;
//   final DateTime generatedAt;
//   final String status;
//   final String? excelFilePath;
//
//   OBHSReport({
//     required this.id,
//     required this.instanceId,
//     required this.trainName,
//     required this.trainNo,
//     required this.instanceNumber,
//     required this.reportDate,
//     required this.reportType,
//     this.specificCoach,
//     required this.entries,
//     required this.generatedBy,
//     required this.generatedAt,
//     required this.status,
//     this.excelFilePath,
//   });
//
//   factory OBHSReport.fromJson(Map<String, dynamic> json) {
//     return OBHSReport(
//       id: json['id'] ?? '',
//       instanceId: json['instanceId'] ?? '',
//       trainName: json['trainName'] ?? '',
//       trainNo: json['trainNo'] ?? '',
//       instanceNumber: json['instanceNumber'] ?? 0,
//       reportDate: DateTime.parse(json['reportDate'] ?? DateTime.now().toString()),
//       reportType: json['reportType'] ?? 'Instance',
//       specificCoach: json['specificCoach'],
//       entries: (json['entries'] as List?)
//               ?.map((e) => ReportEntry.fromJson(e))
//               .toList() ??
//           [],
//       generatedBy: json['generatedBy'] ?? '',
//       generatedAt: DateTime.parse(json['generatedAt'] ?? DateTime.now().toString()),
//       status: json['status'] ?? 'Draft',
//       excelFilePath: json['excelFilePath'],
//     );
//   }
//
//   Map<String, dynamic> toJson() => {
//     'id': id,
//     'instanceId': instanceId,
//     'trainName': trainName,
//     'trainNo': trainNo,
//     'instanceNumber': instanceNumber,
//     'reportDate': reportDate.toIso8601String(),
//     'reportType': reportType,
//     'specificCoach': specificCoach,
//     'entries': entries.map((e) => e.toJson()).toList(),
//     'generatedBy': generatedBy,
//     'generatedAt': generatedAt.toIso8601String(),
//     'status': status,
//     'excelFilePath': excelFilePath,
//   };
// }
//
// class ReportEntry {
//   final String coachId;
//   final String coachNo;
//   final String coachType;
//   final int position;
//   final String? assignedWorker;
//   final String? workerDesignation;
//   final String status;
//   final String? issueDescription;
//   final List<String>? issuePhotos;
//   final String? supervisorNotes;
//   final DateTime? completedAt;
//   final Map<String, dynamic>? additionalData;
//
//   ReportEntry({
//     required this.coachId,
//     required this.coachNo,
//     required this.coachType,
//     required this.position,
//     this.assignedWorker,
//     this.workerDesignation,
//     required this.status,
//     this.issueDescription,
//     this.issuePhotos,
//     this.supervisorNotes,
//     this.completedAt,
//     this.additionalData,
//   });
//
//   factory ReportEntry.fromJson(Map<String, dynamic> json) {
//     return ReportEntry(
//       coachId: json['coachId'] ?? '',
//       coachNo: json['coachNo'] ?? '',
//       coachType: json['coachType'] ?? '',
//       position: json['position'] ?? 0,
//       assignedWorker: json['assignedWorker'],
//       workerDesignation: json['workerDesignation'],
//       status: json['status'] ?? 'Pending',
//       issueDescription: json['issueDescription'],
//       issuePhotos: List<String>.from(json['issuePhotos'] ?? []),
//       supervisorNotes: json['supervisorNotes'],
//       completedAt: json['completedAt'] != null
//           ? DateTime.parse(json['completedAt'])
//           : null,
//       additionalData: json['additionalData'],
//     );
//   }
//
//   Map<String, dynamic> toJson() => {
//     'coachId': coachId,
//     'coachNo': coachNo,
//     'coachType': coachType,
//     'position': position,
//     'assignedWorker': assignedWorker,
//     'workerDesignation': workerDesignation,
//     'status': status,
//     'issueDescription': issueDescription,
//     'issuePhotos': issuePhotos,
//     'supervisorNotes': supervisorNotes,
//     'completedAt': completedAt?.toIso8601String(),
//     'additionalData': additionalData,
//   };
// }
//
// class OBHSService {
//   static List<TrainInstanceModel> generateInstances({
//     required String trainId,
//     required String trainNo,
//     required String trainName,
//     required String outboundTrainNo,
//     required String inboundTrainNo,
//     required int cycleLength,
//     required List<String> runningDays,
//     required List<CoachAssignment> coaches,
//     required String userId,
//   }) {
//     List<TrainInstanceModel> instances = [];
//     DateTime startDate = DateTime.now();
//
//     for (int i = 1; i <= cycleLength; i++) {
//       final instanceStartDate = startDate.add(Duration(days: i - 1));
//       final instanceEndDate = instanceStartDate.add(const Duration(days: 1));
//
//       // Calculate down and up train numbers with instance suffix
//       final downTrainNo = '$outboundTrainNo-D$i';
//       final upTrainNo = '$inboundTrainNo-U$i';
//
//       instances.add(
//         TrainInstanceModel(
//           id: 'INST-${trainNo}-${i.toString().padLeft(3, '0')}',
//           trainId: trainId,
//           trainNo: trainNo,
//           trainName: trainName,
//           downTrainNo: downTrainNo,
//           upTrainNo: upTrainNo,
//           instanceNumber: i,
//           startDate: instanceStartDate,
//           endDate: instanceEndDate,
//           status: i == 1 ? 'Active' : 'Pending',
//           cycleLength: cycleLength,
//           coachAssignments: coaches,
//           runningDays: runningDays,
//           createdBy: userId,
//           createdAt: DateTime.now(),
//           metadata: {
//             'cycleDay': i,
//             'totalCycleDays': cycleLength,
//             'cyclePercentage': ((i / cycleLength) * 100).toStringAsFixed(2),
//           },
//         ),
//       );
//     }
//
//     return instances;
//   }
//
//   static Future<TrainInstanceModel?> getInstanceByNumber({
//     required String trainNo,
//     required int instanceNumber,
//   }) async {
//     try {
//       return null;
//     } catch (e) {
//       print('Error fetching instance: $e');
//       return null;
//     }
//   }
//
//   static Future<bool> updateCoachAssignment({
//     required String instanceId,
//     required String coachId,
//     required String? workerId,
//     required String? workerName,
//     required String? roleTag,
//   }) async {
//     try {
//       return true;
//     } catch (e) {
//       print('Error updating coach assignment: $e');
//       return false;
//     }
//   }
//
//   static Future<List<CoachAssignment>> getInstanceAssignments(
//       String instanceId) async {
//     try {
//       return [];
//     } catch (e) {
//       print('Error fetching assignments: $e');
//       return [];
//     }
//   }
//
//   static Future<bool> logWorkerAssignment({
//     required String instanceId,
//     required String coachId,
//     required String workerId,
//     required String workerName,
//     required String workerDesignation,
//     required String assignmentReason,
//   }) async {
//     try {
//       final log = WorkerAssignmentLog(
//         id: 'LOG-${DateTime.now().millisecondsSinceEpoch}',
//         instanceId: instanceId,
//         coachId: coachId,
//         janitorId: workerId,
//         janitorName: workerName,
//         workerDesignation: workerDesignation,
//         assignedDate: DateTime.now(),
//         assignmentReason: assignmentReason,
//         status: 'Active',
//       );
//
//       // TODO: Save log to backend
//       return true;
//     } catch (e) {
//       print('Error logging assignment: $e');
//       return false;
//     }
//   }
//
//   static Future<OBHSReport?> generateReport({
//     required String instanceId,
//     required String reportType,
//     String? specificCoach,
//     required String userId,
//   }) async {
//     try {
//       final report = OBHSReport(
//         id: 'REP-${DateTime.now().millisecondsSinceEpoch}',
//         instanceId: instanceId,
//         trainName: '',
//         trainNo: '',
//         instanceNumber: 0,
//         reportDate: DateTime.now(),
//         reportType: reportType,
//         specificCoach: specificCoach,
//         entries: [],
//         generatedBy: userId,
//         generatedAt: DateTime.now(),
//         status: 'Draft',
//       );
//
//       return report;
//     } catch (e) {
//       print('Error generating report: $e');
//       return null;
//     }
//   }
//
//   static Future<List<WorkerAssignmentLog>> getCoachAssignmentHistory(
//       String coachId) async {
//     try {
//       return [];
//     } catch (e) {
//       print('Error fetching assignment history: $e');
//       return [];
//     }
//   }
//
//   static Future<bool> closeInstance(String instanceId) async {
//     try {
//       return true;
//     } catch (e) {
//       print('Error closing instance: $e');
//       return false;
//     }
//   }
// }
