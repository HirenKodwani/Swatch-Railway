class JanitorPerformanceModel {
  final String janitorId;
  final String janitorName;
  final int tasksCompleted;
  final int tasksMissed;
  final int tasksOverdue;
  final double averageRating;
  final double completionPercentage;
  final double coachCleanlinessScore;

  JanitorPerformanceModel({
    required this.janitorId,
    required this.janitorName,
    this.tasksCompleted = 0,
    this.tasksMissed = 0,
    this.tasksOverdue = 0,
    this.averageRating = 0.0,
    this.completionPercentage = 0.0,
    this.coachCleanlinessScore = 0.0,
  });

  factory JanitorPerformanceModel.fromJson(Map<String, dynamic> json) {
    return JanitorPerformanceModel(
      janitorId: json['janitorId'] as String? ?? '',
      janitorName: json['janitorName'] as String? ?? '',
      tasksCompleted: json['tasksCompleted'] as int? ?? 0,
      tasksMissed: json['tasksMissed'] as int? ?? 0,
      tasksOverdue: json['tasksOverdue'] as int? ?? 0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      completionPercentage:
          (json['completionPercentage'] as num?)?.toDouble() ?? 0.0,
      coachCleanlinessScore:
          (json['coachCleanlinessScore'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class CoachCleanlinessModel {
  final String coachNo;
  final double cleanlinessScore;
  final int toiletCompletions;
  final int totalToiletTasks;
  final int waterIssues;
  final int garbageIssues;

  CoachCleanlinessModel({
    required this.coachNo,
    this.cleanlinessScore = 0.0,
    this.toiletCompletions = 0,
    this.totalToiletTasks = 0,
    this.waterIssues = 0,
    this.garbageIssues = 0,
  });

  factory CoachCleanlinessModel.fromJson(Map<String, dynamic> json) {
    return CoachCleanlinessModel(
      coachNo: json['coachNo'] as String? ?? '',
      cleanlinessScore:
          (json['cleanlinessScore'] as num?)?.toDouble() ?? 0.0,
      toiletCompletions: json['toiletCompletions'] as int? ?? 0,
      totalToiletTasks: json['totalToiletTasks'] as int? ?? 0,
      waterIssues: json['waterIssues'] as int? ?? 0,
      garbageIssues: json['garbageIssues'] as int? ?? 0,
    );
  }
}
