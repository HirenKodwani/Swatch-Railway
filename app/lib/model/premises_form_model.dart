import 'dart:convert';

import 'package:flutter/material.dart';

class FormResponse {
  final int count;
  final List<FormData> forms;

  FormResponse({
    required this.count,
    required this.forms,
  });

  factory FormResponse.fromJson(Map<String, dynamic> json) {
    return FormResponse(
      count: json['count'],
      forms: (json['forms'] as List)
          .map((e) => FormData.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'count': count,
    'forms': forms.map((e) => e.toJson()).toList(),
  };

  static FormResponse fromJsonString(String str) =>
      FormResponse.fromJson(json.decode(str));
  String toJsonString() => json.encode(toJson());
}

class FormData {
  final String uid;
  final String location;
  final dynamic area;
  final DateTime formDateTime;
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
  final CreatedAt createdAt;
  final String? timeWorkStarted;
  final String? timeWorkCompleted;
  final RatingDetails? ratingDetails;
  final DateTime? ratedAt;
  final String? railwayRemarks;
  final Signature? railwaySignature;
  final String? rejectionComments;
  final DateTime? rejectAt;
  final DateTime? resubmittedAt;
  final String? contractorRemarks;
  final Signature? resubmitSign;

  FormData({
    required this.uid,
    required this.location,
    required this.area,
    required this.formDateTime,
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
    this.timeWorkStarted,
    this.timeWorkCompleted,
    this.rejectionComments,
    this.rejectAt,
    this.ratingDetails,
    this.ratedAt,
    this.resubmittedAt,
    this.railwayRemarks,
    this.railwaySignature,
    this.contractorRemarks,
    this.resubmitSign,
  });

  factory FormData.fromJson(Map<String, dynamic> json) {
    return FormData(
      uid: json['uid'] ?? '',
      area: json['area'] ?? 'NA',
      location: json['location'] ?? '',
      formDateTime: DateTime.parse(json['formDateTime']),
      manpower: (json['manpower'] as List)
          .map((e) => Manpower.fromJson(e))
          .toList(),
      submittedTo: SubmittedTo.fromJson(json['submittedTo']),
      signature: Signature.fromJson(json['signature']),
      status: json['status'] ?? '',
      submittedById: json['submittedById'] ?? '',
      submittedByName: json['submittedByName'] ?? '',
      submittedByZone: json['submittedByZone'] ?? '',
      submittedByDivision: json['submittedByDivision'] ?? '',
      submittedByDepot: json['submittedByDepot'], // nullable OK
      submittedByEntityId: json['submittedByEntityId'] ?? '',
      submittedByEntityName: json['submittedByEntityName'] ?? '',
      createdAt: CreatedAt.fromJson(json['createdAt']),
      rejectionComments: json['rejectionComments'],
      timeWorkStarted: json['timeWorkStarted'],
      timeWorkCompleted: json['timeWorkCompleted'],
      ratingDetails: json['ratingDetails'] != null
          ? RatingDetails.fromJson(json['ratingDetails'])
          : null,
      ratedAt: json['ratedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
          json['ratedAt']['_seconds'] * 1000)
          : null,
      rejectAt: json['rejectedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
          json['rejectedAt']['_seconds'] * 1000)
          : null,
      resubmittedAt: json['resubmittedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
          json['resubmittedAt']['_seconds'] * 1000)
          : null,
      railwayRemarks: json['railwayRemarks'],
      railwaySignature: json['railwaySignature'] != null
          ? Signature.fromJson(json['railwaySignature'])
          : null,
      contractorRemarks: json['contractorRemarks'],
      resubmitSign: json['resubmitSignature'] != null
          ? Signature.fromJson(json['resubmitSignature'])
          : (json['resubmitSign'] != null
              ? Signature.fromJson(json['resubmitSign'])
              : null),
    );
  }


  Map<String, dynamic> toJson() => {
    'uid': uid,
    'area': area,
    'location': location,
    'formDateTime': formDateTime.toIso8601String(),
    'manpower': manpower.map((e) => e.toJson()).toList(),
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
    'timeWorkStarted': timeWorkStarted,
    'timeWorkCompleted': timeWorkCompleted,
    'ratingDetails': ratingDetails?.toJson(),
    'ratedAt': ratedAt?.toIso8601String(),
    'resubmittedAt': resubmittedAt?.toIso8601String(),
    'rejectedAt': rejectAt?.toIso8601String(),
    'rejectionComments': rejectionComments,
    'railwayRemarks': railwayRemarks,
    'railwaySignature': railwaySignature?.toJson(),
    'contractorRemarks': contractorRemarks,
    'resubmitSign': resubmitSign?.toJson(),
  };

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

}

class RatingDetails {
  final List<ScoreItem> housekeepingItems;
  final List<ScoreItem> pitLineItems;
  final List<ScoreItem> disposalItems;
  final ScorecardSummary summary;

  RatingDetails({
    required this.housekeepingItems,
    required this.pitLineItems,
    required this.disposalItems,
    required this.summary,
  });

  factory RatingDetails.fromJson(Map<String, dynamic> json) {
    return RatingDetails(
      housekeepingItems: (json['housekeepingItems'] as List)
          .map((e) => ScoreItem.fromJson(e))
          .toList(),
      pitLineItems: (json['pitLineItems'] as List)
          .map((e) => ScoreItem.fromJson(e))
          .toList(),
      disposalItems: (json['disposalItems'] as List)
          .map((e) => ScoreItem.fromJson(e))
          .toList(),
      summary: ScorecardSummary.fromJson(json['summary']),
    );
  }

  Map<String, dynamic> toJson() => {
    'housekeepingItems': housekeepingItems.map((e) => e.toJson()).toList(),
    'pitLineItems': pitLineItems.map((e) => e.toJson()).toList(),
    'disposalItems': disposalItems.map((e) => e.toJson()).toList(),
    'summary': summary.toJson(),
  };
}



class ScoreItem {
  final int sr;
  final String itemDescription;
  final int score1;
  final int score2;
  final double avg;

  ScoreItem({
    required this.sr,
    required this.itemDescription,
    required this.score1,
    required this.score2,
    required this.avg,
  });

  factory ScoreItem.fromJson(Map<String, dynamic> json) {
    return ScoreItem(
      sr: json['sr'],
      itemDescription: json['itemDescription'],
      score1: json['score1'],
      score2: json['score2'],
      avg: (json['avg'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'sr': sr,
    'itemDescription': itemDescription,
    'score1': score1,
    'score2': score2,
    'avg': avg,
  };
}

class ScorecardSummary {
  final double housekeepingAvg;
  final double pitLineAvg;
  final double disposalAvg;
  final double overallAverage;

  ScorecardSummary({
    required this.housekeepingAvg,
    required this.pitLineAvg,
    required this.disposalAvg,
    required this.overallAverage,
  });

  factory ScorecardSummary.fromJson(Map<String, dynamic> json) {
    return ScorecardSummary(
      housekeepingAvg: _parsePercentage(json['housekeepingAveragePct']),
      pitLineAvg: _parsePercentage(json['pitLineAveragePct']),
      disposalAvg: _parsePercentage(json['garbageDisposalAveragePct']),
      overallAverage: _parsePercentage(json['overallAveragePct']),
    );
  }


  static double _parsePercentage(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      String cleaned = value.replaceAll('%', '').trim();
      return double.tryParse(cleaned) ?? 0.0;
    }
    return 0.0;
  }

  Map<String, dynamic> toJson() => {
    'housekeepingAveragePct': '$housekeepingAvg%',
    'pitLineAveragePct': '$pitLineAvg%',
    'garbageDisposalAveragePct': '$disposalAvg%',
    'overallAveragePct': '$overallAverage%',
  };
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
      name: json['name'],
      designation: json['designation'],
      remark: json['remark'],
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'designation': designation,
    'remark': remark,
  };
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
      railwayEmployeeId: json['railwayEmployeeId'],
      railwayEmployeeName: json['railwayEmployeeName'],
      division: json['division'],
      depot: json['depot'],
    );
  }

  Map<String, dynamic> toJson() => {
    'railwayEmployeeId': railwayEmployeeId,
    'railwayEmployeeName': railwayEmployeeName,
    'division': division,
    'depot': depot,
  };
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
      name: json['name'],
      date: json['date'],
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'date': date,
  };
}

class CreatedAt {
  final int seconds;
  final int nanoseconds;

  CreatedAt({
    required this.seconds,
    required this.nanoseconds,
  });

  factory CreatedAt.fromJson(Map<String, dynamic> json) {
    return CreatedAt(
      seconds: json['_seconds'],
      nanoseconds: json['_nanoseconds'],
    );
  }

  Map<String, dynamic> toJson() => {
    '_seconds': seconds,
    '_nanoseconds': nanoseconds,
  };
}