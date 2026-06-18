class JanitorPerformanceModel {
  final String janitorId;
  final String janitorName;
  final int tasksCompleted;
  final int tasksMissed;
  final int tasksOverdue;
  final int totalTasks;
  final double averageRating;
  final double completionPercentage;
  final double coachCleanlinessScore;

  JanitorPerformanceModel({
    this.janitorId = '',
    this.janitorName = '',
    this.tasksCompleted = 0,
    this.tasksMissed = 0,
    this.tasksOverdue = 0,
    this.totalTasks = 0,
    this.averageRating = 0.0,
    this.completionPercentage = 0.0,
    this.coachCleanlinessScore = 0.0,
  });

  factory JanitorPerformanceModel.fromJson(Map<String, dynamic> json) {
    return JanitorPerformanceModel(
      janitorId: json['janitorId'] as String? ?? '',
      janitorName: json['janitorName'] as String? ?? '',
      tasksCompleted: (json['tasksCompleted'] as num?)?.toInt() ?? 0,
      tasksMissed: (json['tasksMissed'] as num?)?.toInt() ?? 0,
      tasksOverdue: (json['tasksOverdue'] as num?)?.toInt() ?? 0,
      totalTasks: (json['totalTasks'] as num?)?.toInt() ?? 0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      completionPercentage: (json['completionPercentage'] as num?)?.toDouble() ?? 0.0,
      coachCleanlinessScore: (json['coachCleanlinessScore'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'janitorId': janitorId,
      'janitorName': janitorName,
      'tasksCompleted': tasksCompleted,
      'tasksMissed': tasksMissed,
      'tasksOverdue': tasksOverdue,
      'totalTasks': totalTasks,
      'averageRating': averageRating,
      'completionPercentage': completionPercentage,
      'coachCleanlinessScore': coachCleanlinessScore,
    };
  }
}
