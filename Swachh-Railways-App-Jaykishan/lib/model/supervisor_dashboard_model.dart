class SupervisorDashboardModel {
  final int activeRuns;
  final int totalWorkers;
  final int pendingTasks;
  final int overdueTasks;
  final double averageCompletionRate;
  final List<Map<String, dynamic>> runSummaries;

  SupervisorDashboardModel({
    this.activeRuns = 0,
    this.totalWorkers = 0,
    this.pendingTasks = 0,
    this.overdueTasks = 0,
    this.averageCompletionRate = 0.0,
    this.runSummaries = const [],
  });

  factory SupervisorDashboardModel.fromJson(Map<String, dynamic> json) {
    return SupervisorDashboardModel(
      activeRuns: (json['activeRuns'] as num?)?.toInt() ?? 0,
      totalWorkers: (json['totalWorkers'] as num?)?.toInt() ?? 0,
      pendingTasks: (json['pendingTasks'] as num?)?.toInt() ?? 0,
      overdueTasks: (json['overdueTasks'] as num?)?.toInt() ?? 0,
      averageCompletionRate: (json['averageCompletionRate'] as num?)?.toDouble() ?? 0.0,
      runSummaries: (json['runSummaries'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'activeRuns': activeRuns,
      'totalWorkers': totalWorkers,
      'pendingTasks': pendingTasks,
      'overdueTasks': overdueTasks,
      'averageCompletionRate': averageCompletionRate,
      'runSummaries': runSummaries,
    };
  }
}
