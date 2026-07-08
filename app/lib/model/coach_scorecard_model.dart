class ScorecardResponse {
  final String scorecardId;
  final String formId;
  final String workType;
  final String acwpStatus;
  final List<CoachEvaluation> evaluations;
  final String submittedBy;
  final DateTime submittedDate;
  final Map<String, int> summary;

  ScorecardResponse({
    required this.scorecardId,
    required this.formId,
    required this.workType,
    required this.acwpStatus,
    required this.evaluations,
    required this.submittedBy,
    required this.submittedDate,
    required this.summary,
  });

  factory ScorecardResponse.fromJson(Map<String, dynamic> json) {
    return ScorecardResponse(
      scorecardId: json['scorecardId'],
      formId: json['formId'],
      workType: json['workType'],
      acwpStatus: json['acwpStatus'],
      evaluations: (json['evaluations'] as List)
          .map((e) => CoachEvaluation.fromJson(e))
          .toList(),
      submittedBy: json['submittedBy'],
      submittedDate: DateTime.parse(json['submittedDate']),
      summary: Map<String, int>.from(json['summary'] ?? {}),
    );
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
      coachNumber: json['coachNumber'],
      internalCleaning: json['internalCleaning'],
      externalCleaning: json['externalCleaning'],
      intensiveCleaning: json['intensiveCleaning'],
      toiletries: json['toiletries'],
      doorsLocking: json['doorsLocking'],
      watering: json['watering'],
      penalty: json['penalty'] ?? 0,
    );
  }
}