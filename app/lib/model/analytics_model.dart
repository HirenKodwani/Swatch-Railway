class JanitorPerformanceModel {
  final String workerId;
  final String workerName;
  final int tasksCompleted;
  final int tasksMissed;
  final int tasksOverdue;
  final double averageRating;
  final double completionPercentage;
  final double coachCleanlinessScore;

  JanitorPerformanceModel({
    required this.workerId,
    required this.workerName,
    this.tasksCompleted = 0,
    this.tasksMissed = 0,
    this.tasksOverdue = 0,
    this.averageRating = 0.0,
    this.completionPercentage = 0.0,
    this.coachCleanlinessScore = 0.0,
  });

  factory JanitorPerformanceModel.fromJson(Map<String, dynamic> json) {
    return JanitorPerformanceModel(
      workerId: json['workerId'] as String? ?? '',
      workerName: json['workerName'] as String? ?? '',
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
