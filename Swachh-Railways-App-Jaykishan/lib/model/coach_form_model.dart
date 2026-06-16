import 'dart:convert';

import 'package:flutter/material.dart';

class CoachFormsResponse {
  final int count;
  final List<CoachForm> forms;

  CoachFormsResponse({
    required this.count,
    required this.forms,
  });

  factory CoachFormsResponse.fromJson(Map<String, dynamic> json) {
    return CoachFormsResponse(
      count: json['count'] ?? 0,
      forms: (json['forms'] as List?)
          ?.map((form) => CoachForm.fromJson(form))
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

class CoachForm {
  final String uid;
  final String trainName;
  final String trainNumber;
  final String formDateTime;
  final int coachCount;
  final List<String> machinesUsed;
  final Chemicals chemicals;
  final List<Manpower> manpower;
  final SubmittedTo submittedTo;
  final Signature signature;
  final String status;
  final String submittedById;
  final String submittedByName;
  final String submittedByZone;
  final String submittedByDivision;
  final String? submittedByDepot;
  final String submittedByEntityId;
  final String submittedByEntityName;
  final Timestamp createdAt;
  final Timestamp? ratedAt;
  final RatingDetails? ratingDetails;
  final Map<String, dynamic>? draft;
  final bool scoringInProgress;
  final String? railwayRemarks;
  final String? contractorRemarks;
  final String? rejectionComments;
  final DateTime? rejectAt;
  final DateTime? resubmittedAt;
  final Signature? resubmitSign;

  CoachForm({
    required this.uid,
    required this.trainName,
    required this.trainNumber,
    required this.formDateTime,
    required this.coachCount,
    required this.machinesUsed,
    required this.chemicals,
    required this.manpower,
    required this.submittedTo,
    required this.signature,
    required this.status,
    required this.submittedById,
    required this.submittedByName,
    required this.submittedByZone,
    required this.submittedByDivision,
    this.submittedByDepot,
    required this.submittedByEntityId,
    required this.submittedByEntityName,
    required this.createdAt,
    this.ratedAt,
    this.ratingDetails,
    this.draft,
    this.scoringInProgress = false,
    this.railwayRemarks,
    this.contractorRemarks,
    this.rejectionComments,
    this.rejectAt,
    this.resubmittedAt,
    this.resubmitSign,
  });

  factory CoachForm.fromJson(Map<String, dynamic> json) {
    try {
      return CoachForm(
        uid: json['uid'] ?? '',
        trainNumber: json['trainNumber'] ?? '',
        trainName: json['trainName'] ?? '',
        formDateTime: json['formDateTime'] ?? '',
        coachCount: json['coachCount'] ?? 0,
        machinesUsed: (json['machinesUsed'] as List?)?.cast<String>() ?? [],
        chemicals: Chemicals.fromJson(json['chemicals'] ?? {}),
        manpower: (json['manpower'] as List?)
            ?.map((mp) => Manpower.fromJson(mp))
            .toList() ??
            [],
        submittedTo: SubmittedTo.fromJson(json['submittedTo'] ?? {}),
        signature: Signature.fromJson(json['signature'] ?? {}),
        status: json['status'] ?? 'PENDING',
        submittedById: json['submittedById'] ?? '',
        submittedByName: json['submittedByName'] ?? '',
        submittedByZone: json['submittedByZone'] ?? '',
        submittedByDivision: json['submittedByDivision'] ?? '',
        submittedByDepot: json['submittedByDepot'],
        submittedByEntityId: json['submittedByEntityId'] ?? '',
        submittedByEntityName: json['submittedByEntityName'] ?? '',
        createdAt: Timestamp.fromJson(json['createdAt'] ?? {}),
        ratedAt: json['ratedAt'] != null
            ? Timestamp.fromJson(json['ratedAt'])
            : null,
        ratingDetails: json['ratingDetails'] != null
            ? RatingDetails.fromJson(json['ratingDetails'])
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
            ? Signature.fromJson(json['resubmitSignature'])
            : (json['resubmitSign'] != null
                ? Signature.fromJson(json['resubmitSign'])
                : null),
      );
    } catch (e, stack) {
      debugPrint('Error parsing CoachForm.fromJson');
      debugPrint('JSON data: ${jsonEncode(json)}');
      debugPrint('Error: $e');
      debugPrint('StackTrace: $stack');
      rethrow;
    }
  }


  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'trainName': trainName,
      'trainNumber': trainNumber,
      'formDateTime': formDateTime,
      'coachCount': coachCount,
      'machinesUsed': machinesUsed,
      'chemicals': chemicals.toJson(),
      'manpower': manpower.map((mp) => mp.toJson()).toList(),
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
      'createdAt': createdAt.toJson(),
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
    switch (status.toUpperCase()) {
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
          'text': status,
          'color': const Color(0xFFE2E3E5),
          'textColor': const Color(0xFF383D41),
          'icon': Icons.info,
        };
    }
  }
  

  bool hasScoringDetails() => ratingDetails != null;


  int getTotalPenalty() => ratingDetails?.totalPenalty ?? 0;
}


class RatingDetails {
  final String workType;
  final String acwpStatus;
  final List<CoachEvaluation> coachEvaluationTable;
  final int totalPenalty;
  final ScoringFinals summary;

  RatingDetails({
    required this.workType,
    required this.acwpStatus,
    required this.coachEvaluationTable,
    required this.totalPenalty,
    required this.summary,
  });

  factory RatingDetails.fromJson(Map<String, dynamic> json) {
    return RatingDetails(
      workType: json['workType'] ?? '',
      acwpStatus: json['acwpStatus'] ?? '',
      coachEvaluationTable: (json['coachEvaluationTable'] as List?)
          ?.map((e) => CoachEvaluation.fromJson(e))
          .toList() ??
          [],
      totalPenalty: json['totalPenalty'] ?? 0,
      summary: ScoringFinals.fromJson(json['summary'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'workType': workType,
      'acwpStatus': acwpStatus,
      'coachEvaluationTable': coachEvaluationTable.map((e) => e.toJson()).toList(),
      'totalPenalty': totalPenalty,
      'summary': summary.toJson(),
    };
  }
}


class CoachEvaluation {
  final String coachNumber;
  final String internalCleaning;
  final String externalCleaning;
  final String intensiveCleaning;
  final String toiletries;
  final String doorsLocking;
  final String watering;
  final int penalty;

  CoachEvaluation({
    required this.coachNumber,
    required this.internalCleaning,
    required this.externalCleaning,
    required this.intensiveCleaning,
    required this.toiletries,
    required this.doorsLocking,
    required this.watering,
    required this.penalty,
  });

  factory CoachEvaluation.fromJson(Map<String, dynamic> json) {
    return CoachEvaluation(
      coachNumber: json['coachNumber'] ?? '',
      internalCleaning: json['internalCleaning'] ?? 'NA',
      externalCleaning: json['externalCleaning'] ?? 'NA',
      intensiveCleaning: json['intensiveCleaning'] ?? 'NA',
      toiletries: json['toiletries'] ?? 'NA',
      doorsLocking: json['doorsLocking'] ?? 'Yes',
      watering: json['watering'] ?? 'Yes',
      penalty: json['penalty'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'coachNumber': coachNumber,
      'internalCleaning': internalCleaning,
      'externalCleaning': externalCleaning,
      'intensiveCleaning': intensiveCleaning,
      'toiletries': toiletries,
      'doorsLocking': doorsLocking,
      'watering': watering,
      'penalty': penalty,
    };
  }
}


class ScoringFinals {
  final Map<String, int> internal;
  final Map<String, int> external;
  final Map<String, int> intensive;
  final Map<String, int> toiletries;
  final Map<String, int> watering;
  final Map<String, int> doorsLocking;
  final int totalCoaches;

  ScoringFinals({
    required this.internal,
    required this.external,
    required this.intensive,
    required this.toiletries,
    required this.watering,
    required this.doorsLocking,
    required this.totalCoaches,
  });

  factory ScoringFinals.fromJson(Map<String, dynamic> json) {
    Map<String, int> _safeMap(dynamic raw) {
      if (raw is Map) {
        return raw.map((key, value) {
          return MapEntry(
            key.toString(),
            value is int
                ? value
                : int.tryParse(value?.toString() ?? '0') ?? 0,
          );
        });
      }
      return {};
    }

    return ScoringFinals(
      internal: _safeMap(json['internal']),
      external: _safeMap(json['external']),
      intensive: _safeMap(json['intensive']),
      toiletries: _safeMap(json['toiletries']),
      watering: _safeMap(json['watering']),
      doorsLocking: _safeMap(json['doorsLocking']),
      totalCoaches: json['totalCoaches'] is int
          ? json['totalCoaches']
          : int.tryParse(json['totalCoaches']?.toString() ?? '0') ?? 0,
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'internal': internal,
      'external': external,
      'intensive': intensive,
      'toiletries': toiletries,
      'watering': watering,
      'doorsLocking': doorsLocking,
      'totalCoaches': totalCoaches,
    };
  }
}



class Chemicals {
  final num spiral;
  final num r3;
  final num r7R2;
  final num r5;
  final num r1R6;
  final num triadIii;
  final num sumaInox;

  Chemicals({
    required this.spiral,
    required this.r3,
    required this.r7R2,
    required this.r5,
    required this.r1R6,
    required this.triadIii,
    required this.sumaInox,
  });

  factory Chemicals.fromJson(Map<String, dynamic> json) {
    return Chemicals(
      spiral: json['spiral'] ?? 0,
      r3: json['r3'] ?? 0,
      r7R2: json['r7_r2'] ?? 0,
      r5: json['r5'] ?? 0,
      r1R6: json['r1_r6'] ?? 0,
      triadIii: json['triad_iii'] ?? 0,
      sumaInox: json['suma_inox'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'spiral': spiral,
      'r3': r3,
      'r7_r2': r7R2,
      'r5': r5,
      'r1_r6': r1R6,
      'triad_iii': triadIii,
      'suma_inox': sumaInox,
    };
  }
}

class Manpower {
  final String name;
  final String designation;
  final String remark;

  Manpower({
    required this.name,
    required this.designation,
    required this.remark,
  });

  factory Manpower.fromJson(Map<String, dynamic> json) {
    return Manpower(
      name: json['name'] ?? '',
      designation: json['designation'] ?? '',
      remark: json['remark'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'designation': designation,
      'remark': remark,
    };
  }
}

class SubmittedTo {
  final String railwayEmployeeId;
  final String railwayEmployeeName;
  final String division;
  final String? depot;

  SubmittedTo({
    required this.railwayEmployeeId,
    required this.railwayEmployeeName,
    required this.division,
    this.depot,
  });

  factory SubmittedTo.fromJson(Map<String, dynamic> json) {
    return SubmittedTo(
      railwayEmployeeId: json['railwayEmployeeId'] ?? '',
      railwayEmployeeName: json['railwayEmployeeName'] ?? '',
      division: json['division'] ?? '',
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

class Signature {
  final String name;
  final String date;

  Signature({
    required this.name,
    required this.date,
  });

  factory Signature.fromJson(Map<String, dynamic> json) {
    return Signature(
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