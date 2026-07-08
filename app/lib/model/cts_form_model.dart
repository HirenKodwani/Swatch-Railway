import 'dart:convert';
import 'package:flutter/material.dart';

class CTSFormsResponse {
  final int count;
  final List<CTSForm> forms;

  CTSFormsResponse({
    required this.count,
    required this.forms,
  });

  factory CTSFormsResponse.fromJson(Map<String, dynamic> json) {
    return CTSFormsResponse(
      count: json['count'] ?? 0,
      forms: (json['forms'] as List?)
          ?.map((form) => CTSForm.fromJson(form))
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'count': count,
      'forms': forms.map((form) => form.toJson()).toList(),
    };
  }
}

class CTSForm {
  final String id;
  final String uid;
  final String formId;
  final String station;
  final String agreementNo;
  final String agreementDate;
  final String contractorName;
  final String jobDate;
  final String trainId;
  final String trainNumber;
  final String trainName;
  final String formDateTime;
  final String actArrival;
  final String actDeparture;
  final String workStart;
  final String workEnd;
  final String platform;
  final String allowedWindow;
  final String lateYN;
  final int coachesInRake;
  final int coachesAttended;
  final List<AttendanceStaff> attendanceStaff;
  final bool garbageDisposed;
  final String nominatedLocation;
  final int occupiedToilets;
  final String notes;
  final CTSSubmittedTo submittedTo;
  final CTSSignature signature;
  final String? status;
  final String? submittedById;
  final String? submittedByName;
  final String? submittedByZone;
  final String? submittedByDivision;
  final String? submittedByDepot;
  final String? submittedByEntityId;
  final String? submittedByEntityName;
  final Timestamp? createdAt;
  final Timestamp? ratedAt;
  final CTSRatingDetails? ratingDetails;
  final Map<String, dynamic>? draft;
  final bool? scoringInProgress;
  final String? railwayRemarks;
  final String? contractorRemarks;
  final String? rejectionComments;
  final DateTime? rejectAt;
  final DateTime? resubmittedAt;
  final CTSSignature? resubmitSign;

  CTSForm({
    required this.id,
    required this.uid,
    required this.formId,
    required this.station,
    required this.agreementNo,
    required this.agreementDate,
    required this.contractorName,
    required this.jobDate,
    required this.trainId,
    required this.trainNumber,
    required this.trainName,
    required this.formDateTime,
    required this.actArrival,
    required this.actDeparture,
    required this.workStart,
    required this.workEnd,
    required this.platform,
    required this.allowedWindow,
    required this.lateYN,
    required this.coachesInRake,
    required this.coachesAttended,
    required this.attendanceStaff,
    required this.garbageDisposed,
    required this.nominatedLocation,
    required this.occupiedToilets,
    required this.notes,
    required this.submittedTo,
    required this.signature,
    this.status,
    this.submittedById,
    this.submittedByName,
    this.submittedByZone,
    this.submittedByDivision,
    this.submittedByDepot,
    this.submittedByEntityId,
    this.submittedByEntityName,
    this.createdAt,
    this.ratedAt,
    this.ratingDetails,
    this.draft,
    this.scoringInProgress,
    this.railwayRemarks,
    this.contractorRemarks,
    this.rejectionComments,
    this.rejectAt,
    this.resubmittedAt,
    this.resubmitSign,
  });

  factory CTSForm.fromJson(Map<String, dynamic> json) {
    try {
      return CTSForm(
        id: json['id'] ?? json['uid'] ?? '',
        uid: json['uid'] ?? '',
        formId: json['formId'] ?? json['uid'] ?? '',
        station: json['station'] ?? '',
        agreementNo: json['agreementNo'] ?? '',
        agreementDate: json['agreementDate'] ?? '',
        contractorName: json['contractorName'] ?? '',
        jobDate: json['jobDate'] ?? '',
        trainId: json['trainId'] ?? '',
        trainNumber: json['trainNumber'] ?? '',
        trainName: json['trainName'] ?? '',
        formDateTime: json['formDateTime'] ?? '',
        actArrival: json['actArrival'] ?? '',
        actDeparture: json['actDeparture'] ?? '',
        workStart: json['workStart'] ?? '',
        workEnd: json['workEnd'] ?? '',
        platform: json['platform'] ?? '',
        allowedWindow: json['allowedWindow'] ?? '',
        lateYN: json['lateYN'] ?? '',
        coachesInRake: json['coachesInRake'] ?? 0,
        coachesAttended: json['coachesAttended'] ?? 0,
        attendanceStaff: (json['attendanceStaff'] as List?)
            ?.map((staff) => AttendanceStaff.fromJson(staff))
            .toList() ??
            [],
        garbageDisposed: json['garbageDisposed'] ?? false,
        nominatedLocation: json['nominatedLocation'] ?? 'NA',
        occupiedToilets: json['occupiedToilets'] ?? 0,
        notes: json['notes'] ?? '',
        submittedTo: CTSSubmittedTo.fromJson(json['submittedTo'] ?? {}),
        signature: CTSSignature.fromJson(json['signature'] ?? {}),
        status: json['status'] ?? 'PENDING',
        submittedById: json['submittedById'],
        submittedByName: json['submittedByName'],
        submittedByZone: json['submittedByZone'],
        submittedByDivision: json['submittedByDivision'],
        submittedByDepot: json['submittedByDepot'],
        submittedByEntityId: json['submittedByEntityId'],
        submittedByEntityName: json['submittedByEntityName'],
        createdAt: json['createdAt'] != null
            ? Timestamp.fromJson(json['createdAt'])
            : null,
        ratedAt: json['ratedAt'] != null
            ? Timestamp.fromJson(json['ratedAt'])
            : null,
        ratingDetails: json['ratingDetails'] != null
            ? CTSRatingDetails.fromJson(json['ratingDetails'])
            : null,
        draft: json['draft'] != null ? Map<String, dynamic>.from(json['draft']) : null,
        scoringInProgress: json['scoringInProgress'] ?? false,
        railwayRemarks: json['railwayRemarks'],
        contractorRemarks: json['contractorRemarks'],
        rejectionComments: json['rejectionComments'],
        rejectAt: json['rejectedAt'] != null
            ? Timestamp.fromJson(json['rejectedAt']).toDateTime()
            : null,
        resubmittedAt: json['resubmittedAt'] != null
            ? Timestamp.fromJson(json['resubmittedAt']).toDateTime()
            : null,
        resubmitSign: json['resubmitSignature'] != null
            ? CTSSignature.fromJson(json['resubmitSignature'])
            : (json['resubmitSign'] != null
                ? CTSSignature.fromJson(json['resubmitSign'])
                : null),
      );
    } catch (e, stack) {
      debugPrint('Error parsing CTSForm.fromJson');
      debugPrint('JSON data: ${jsonEncode(json)}');
      debugPrint('Error: $e');
      debugPrint('StackTrace: $stack');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uid': uid,
      'formId': formId,
      'station': station,
      'agreementNo': agreementNo,
      'agreementDate': agreementDate,
      'contractorName': contractorName,
      'jobDate': jobDate,
      'trainId': trainId,
      'trainNumber': trainNumber,
      'trainName': trainName,
      'formDateTime': formDateTime,
      'actArrival': actArrival,
      'actDeparture': actDeparture,
      'workStart': workStart,
      'workEnd': workEnd,
      'platform': platform,
      'allowedWindow': allowedWindow,
      'lateYN': lateYN,
      'coachesInRake': coachesInRake,
      'coachesAttended': coachesAttended,
      'attendanceStaff': attendanceStaff.map((staff) => staff.toJson()).toList(),
      'garbageDisposed': garbageDisposed,
      'nominatedLocation': nominatedLocation,
      'occupiedToilets': occupiedToilets,
      'notes': notes,
      'submittedTo': submittedTo.toJson(),
      'signature': signature.toJson(),
      'status': status,
      'submittedById': submittedById,
      'submittedByName': submittedByName,
      'submittedByZone': submittedByZone,
      'submittedByDivision': submittedByDivision,
      'submittedByDepot': submittedByDepot,
      'submittedByEntityId': submittedByEntityId,
      'submittedByEntityName': submittedByEntityName,
      'createdAt': createdAt?.toJson(),
      'ratedAt': ratedAt?.toJson(),
      'ratingDetails': ratingDetails?.toJson(),
      'draft': draft,
      'scoringInProgress': scoringInProgress,
      'railwayRemarks': railwayRemarks,
      'contractorRemarks': contractorRemarks,
      'rejectionComments': rejectionComments,
      'rejectedAt': rejectAt?.toIso8601String(),
      'resubmittedAt': resubmittedAt?.toIso8601String(),
      'resubmitSign': resubmitSign?.toJson(),
    };
  }

  String getFormattedDateTime() {
    try {
      final dateTime = DateTime.parse(formDateTime).toLocal();
      return dateTime.toString().substring(0, 16);
    } catch (e) {
      return formDateTime;
    }
  }

  Map<String, dynamic> getStatusInfo() {
    switch (status?.toUpperCase() ?? 'PENDING') {
      case 'PENDING':
        return {
          'text': 'Pending Review',
          'color': const Color(0xFFFFF3CD),
          'textColor': const Color(0xFF856404),
          'icon': Icons.pending_actions,
        };
      case 'APPROVED':
        return {
          'text': 'Approved',
          'color': const Color(0xFFD4EDDA),
          'textColor': const Color(0xFF155724),
          'icon': Icons.check_circle,
        };
      case 'REJECTED':
        return {
          'text': 'Rejected',
          'color': const Color(0xFFF8D7DA),
          'textColor': const Color(0xFF721C24),
          'icon': Icons.cancel,
        };
      case 'SCORING':
        return {
          'text': 'Scoring in Progress',
          'color': const Color(0xFFD1ECF1),
          'textColor': const Color(0xFF0C5460),
          'icon': Icons.hourglass_bottom,
        };
      case 'SCORED':
        return {
          'text': 'Scored (Awaiting Acceptance)',
          'color': const Color(0xFFEDEAFF),
          'textColor': const Color(0xFF6B4EFF),
          'icon': Icons.assignment_turned_in,
        };
      case 'CLOSED':
        return {
          'text': 'Closed (Accepted)',
          'color': const Color(0xFFD4EDDA),
          'textColor': const Color(0xFF1D4C1F),
          'icon': Icons.verified,
        };
      case 'AUTO-APPROVED':
      case 'AUTO_APPROVED':
        return {
          'text': 'Auto-Approved',
          'color': const Color(0xFFD4EDDA),
          'textColor': const Color(0xFF155724),
          'icon': Icons.check_circle_outline,
        };
      case 'LOCKED':
        return {
          'text': 'Locked',
          'color': const Color(0xFFE2E3E5),
          'textColor': const Color(0xFF383D41),
          'icon': Icons.lock,
        };
      default:
        return {
          'text': status ?? 'Pending',
          'color': const Color(0xFFE2E3E5),
          'textColor': const Color(0xFF383D41),
          'icon': Icons.info,
        };
    }
  }

  bool hasScoringDetails() => ratingDetails != null;

  int getTotalPenalty() => ratingDetails?.totalPenalty ?? 0;
}

class AttendanceStaff {
  final String name;
  final String staffId;
  final String role;
  final String remarks;

  AttendanceStaff({
    required this.name,
    required this.staffId,
    required this.role,
    required this.remarks,
  });

  factory AttendanceStaff.fromJson(Map<String, dynamic> json) {
    return AttendanceStaff(
      name: json['name'] ?? '',
      staffId: json['staffId'] ?? '',
      role: json['role'] ?? '',
      remarks: json['remarks'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'staffId': staffId,
      'role': role,
      'remarks': remarks,
    };
  }
}

class CTSSubmittedTo {
  final String railwayEmployeeId;
  final String? railwayEmployeeName;
  final String? division;
  final String? depot;

  CTSSubmittedTo({
    required this.railwayEmployeeId,
    this.railwayEmployeeName,
    this.division,
    this.depot,
  });

  factory CTSSubmittedTo.fromJson(Map<String, dynamic> json) {
    return CTSSubmittedTo(
      railwayEmployeeId: json['railwayEmployeeId'] ?? '',
      railwayEmployeeName: json['railwayEmployeeName'],
      division: json['division'],
      depot: json['depot'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'railwayEmployeeId': railwayEmployeeId,
      'railwayEmployeeName': railwayEmployeeName,
      'division': division,
      'depot': depot,
    };
  }
}

class CTSSignature {
  final String name;
  final String date;

  CTSSignature({
    required this.name,
    required this.date,
  });

  factory CTSSignature.fromJson(Map<String, dynamic> json) {
    return CTSSignature(
      name: json['name'] ?? '',
      date: json['date'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'date': date,
    };
  }
}

class CTSRatingDetails {
  final CTSInspectionHeader inspectionHeader;
  final List<CTSCoachEvaluation> coachEvaluationTable;
  final List<String> machinesUsed;
  final List<CTSChemical> chemicals;
  final int totalPenalty;
  final CTSScoringFinals summary;

  CTSRatingDetails({
    required this.inspectionHeader,
    required this.coachEvaluationTable,
    required this.machinesUsed,
    required this.chemicals,
    required this.totalPenalty,
    required this.summary,
  });

  factory CTSRatingDetails.fromJson(Map<String, dynamic> json) {
    return CTSRatingDetails(
      inspectionHeader: CTSInspectionHeader.fromJson(json['inspectionHeader'] ?? {}),
      coachEvaluationTable: (json['coachEvaluationTable'] as List?)
          ?.map((e) => CTSCoachEvaluation.fromJson(e))
          .toList() ??
          [],
      machinesUsed: (json['machinesUsed'] as List?)
          ?.map((e) => e.toString())
          .toList() ??
          [],
      chemicals: (json['chemicals'] as List?)
          ?.map((e) => CTSChemical.fromJson(e))
          .toList() ??
          [],
      totalPenalty: json['totalPenalty'] ?? 0,
      summary: CTSScoringFinals.fromJson(json['summary'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'inspectionHeader': inspectionHeader.toJson(),
      'coachEvaluationTable': coachEvaluationTable.map((e) => e.toJson()).toList(),
      'machinesUsed': machinesUsed,
      'chemicals': chemicals.map((e) => e.toJson()).toList(),
      'totalPenalty': totalPenalty,
      'summary': summary.toJson(),
    };
  }
}

class CTSInspectionHeader {
  final String workStart;
  final String workEnd;
  final String inspectorType;
  final int totalCoaches;
  final int coachesAttended;
  final int samplingPercentage;

  CTSInspectionHeader({
    required this.workStart,
    required this.workEnd,
    required this.inspectorType,
    required this.totalCoaches,
    required this.coachesAttended,
    required this.samplingPercentage,
  });

  factory CTSInspectionHeader.fromJson(Map<String, dynamic> json) {
    return CTSInspectionHeader(
      workStart: json['workStart'] ?? '',
      workEnd: json['workEnd'] ?? '',
      inspectorType: json['inspectorType'] ?? '',
      totalCoaches: json['totalCoaches'] ?? 0,
      coachesAttended: json['coachesAttended'] ?? 0,
      samplingPercentage: json['samplingPercentage'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'workStart': workStart,
      'workEnd': workEnd,
      'inspectorType': inspectorType,
      'totalCoaches': totalCoaches,
      'coachesAttended': coachesAttended,
      'samplingPercentage': samplingPercentage,
    };
  }
}

class CTSChemical {
  final String name;
  final String brand;
  final String quantity;

  CTSChemical({
    required this.name,
    required this.brand,
    required this.quantity,
  });

  factory CTSChemical.fromJson(Map<String, dynamic> json) {
    return CTSChemical(
      name: json['name'] ?? '',
      brand: json['brand'] ?? '',
      quantity: json['quantity'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'brand': brand,
      'quantity': quantity,
    };
  }
}

class CTSCoachEvaluation {
  final String coachPosition;
  final String coachNo;
  final int jetCleaningScore;
  final int basinCleaningScore;
  final int disposalScore;
  final String remarks;
  final int totalScore;
  final String grade;

  CTSCoachEvaluation({
    required this.coachPosition,
    required this.coachNo,
    required this.jetCleaningScore,
    required this.basinCleaningScore,
    required this.disposalScore,
    required this.remarks,
    required this.totalScore,
    required this.grade,
  });

  factory CTSCoachEvaluation.fromJson(Map<String, dynamic> json) {
    return CTSCoachEvaluation(
      coachPosition: json['coachPosition'] ?? '',
      coachNo: json['coachNo'] ?? '',
      jetCleaningScore: json['jetCleaningScore'] ?? 0,
      basinCleaningScore: json['basinCleaningScore'] ?? 0,
      disposalScore: json['disposalScore'] ?? 0,
      remarks: json['remarks'] ?? '',
      totalScore: json['totalScore'] ?? 0,
      grade: json['grade'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'coachPosition': coachPosition,
      'coachNo': coachNo,
      'jetCleaningScore': jetCleaningScore,
      'basinCleaningScore': basinCleaningScore,
      'disposalScore': disposalScore,
      'remarks': remarks,
      'totalScore': totalScore,
      'grade': grade,
    };
  }
}

class CTSScoringFinals {
  final double averageScore;
  final String overallGrade;

  CTSScoringFinals({
    required this.averageScore,
    required this.overallGrade,
  });

  factory CTSScoringFinals.fromJson(Map<String, dynamic> json) {
    return CTSScoringFinals(
      averageScore: (json['averageScore'] is num)
          ? (json['averageScore'] as num).toDouble()
          : double.tryParse(json['averageScore']?.toString() ?? '0') ?? 0.0,
      overallGrade: json['overallGrade'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'averageScore': averageScore,
      'overallGrade': overallGrade,
    };
  }
}

class Timestamp {
  final int seconds;
  final int nanoseconds;

  Timestamp({
    required this.seconds,
    required this.nanoseconds,
  });

  factory Timestamp.fromJson(Map<String, dynamic> json) {
    try {
      return Timestamp(
        seconds: json['_seconds'],
        nanoseconds: json['_nanoseconds'],
      );
    } catch (e) {
      debugPrint("Timestamp JSON caused error: ${jsonEncode(json)}");
      debugPrint("Error: $e");
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      '_seconds': seconds,
      '_nanoseconds': nanoseconds,
    };
  }

  DateTime toDateTime() {
    return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
  }

  String toFormattedString() {
    final dateTime = toDateTime();
    return '${dateTime.day} ${_getMonthName(dateTime.month)} ${dateTime.year.toString().substring(2)} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }
}
