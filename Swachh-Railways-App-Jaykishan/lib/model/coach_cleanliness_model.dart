class CoachCleanlinessModel {
  final String coachNo;
  final String coachType;
  final double cleanlinessScore;
  final int tasksCompleted;
  final int totalTasks;
  final double completionPercentage;
  final double averageRating;

  CoachCleanlinessModel({
    this.coachNo = '',
    this.coachType = '',
    this.cleanlinessScore = 0.0,
    this.tasksCompleted = 0,
    this.totalTasks = 0,
    this.completionPercentage = 0.0,
    this.averageRating = 0.0,
  });

  factory CoachCleanlinessModel.fromJson(Map<String, dynamic> json) {
    return CoachCleanlinessModel(
      coachNo: json['coachNo'] as String? ?? '',
      coachType: json['coachType'] as String? ?? '',
      cleanlinessScore: (json['cleanlinessScore'] as num?)?.toDouble() ?? 0.0,
      tasksCompleted: (json['tasksCompleted'] as num?)?.toInt() ?? 0,
      totalTasks: (json['totalTasks'] as num?)?.toInt() ?? 0,
      completionPercentage: (json['completionPercentage'] as num?)?.toDouble() ?? 0.0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'coachNo': coachNo,
      'coachType': coachType,
      'cleanlinessScore': cleanlinessScore,
      'tasksCompleted': tasksCompleted,
      'totalTasks': totalTasks,
      'completionPercentage': completionPercentage,
      'averageRating': averageRating,
    };
  }
}
