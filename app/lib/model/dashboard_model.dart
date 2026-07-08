class SupervisorDashboardModel {
  final int activeTrains;
  final int activeWorkers;
  final int missedTasks;
  final int overdueTasks;
  final int escalatedTasks;
  final int openComplaints;
  final double averageRating;
  final int waterIssues;
  final int safetyIssues;
  final DateTime lastUpdated;

  SupervisorDashboardModel({
    this.activeTrains = 0,
    this.activeWorkers = 0,
    this.missedTasks = 0,
    this.overdueTasks = 0,
    this.escalatedTasks = 0,
    this.openComplaints = 0,
    this.averageRating = 0.0,
    this.waterIssues = 0,
    this.safetyIssues = 0,
    required this.lastUpdated,
  });

  factory SupervisorDashboardModel.fromJson(Map<String, dynamic> json) {
    return SupervisorDashboardModel(
      activeTrains: json['activeTrains'] as int? ?? 0,
      activeWorkers: json['activeWorkers'] as int? ?? 0,
      missedTasks: json['missedTasks'] as int? ?? 0,
      overdueTasks: json['overdueTasks'] as int? ?? 0,
      escalatedTasks: json['escalatedTasks'] as int? ?? 0,
      openComplaints: json['openComplaints'] as int? ?? 0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      waterIssues: json['waterIssues'] as int? ?? 0,
      safetyIssues: json['safetyIssues'] as int? ?? 0,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'activeTrains': activeTrains,
      'activeWorkers': activeWorkers,
      'missedTasks': missedTasks,
      'overdueTasks': overdueTasks,
      'escalatedTasks': escalatedTasks,
      'openComplaints': openComplaints,
      'averageRating': averageRating,
      'waterIssues': waterIssues,
      'safetyIssues': safetyIssues,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}
