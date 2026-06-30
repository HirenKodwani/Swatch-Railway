class TaskHeaderModel {
  final String headerId;
  final String runInstanceId;
  final String taskType;
  final String scheduledTime;
  final String status;
  final List<String> childTaskIds;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TaskHeaderModel({
    required this.headerId,
    required this.runInstanceId,
    required this.taskType,
    required this.scheduledTime,
    this.status = 'PLANNED',
    this.childTaskIds = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory TaskHeaderModel.fromJson(Map<String, dynamic> json) {
    return TaskHeaderModel(
      headerId: json['headerId'] as String? ?? '',
      runInstanceId: json['runInstanceId'] as String? ?? '',
      taskType: json['taskType'] as String? ?? '',
      scheduledTime: json['scheduledTime'] as String? ?? '',
      status: json['status'] as String? ?? 'PLANNED',
      childTaskIds: (json['childTaskIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'headerId': headerId,
      'runInstanceId': runInstanceId,
      'taskType': taskType,
      'scheduledTime': scheduledTime,
      'status': status,
      'childTaskIds': childTaskIds,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  TaskHeaderModel copyWith({
    String? headerId,
    String? runInstanceId,
    String? taskType,
    String? scheduledTime,
    String? status,
    List<String>? childTaskIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskHeaderModel(
      headerId: headerId ?? this.headerId,
      runInstanceId: runInstanceId ?? this.runInstanceId,
      taskType: taskType ?? this.taskType,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      status: status ?? this.status,
      childTaskIds: childTaskIds ?? this.childTaskIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
