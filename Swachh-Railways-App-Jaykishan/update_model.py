import sys
import re

file_path = 'lib/model/run_instance_model.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace workerId with janitorId
content = content.replace('workerId', 'janitorId')
content = content.replace('workerName', 'janitorName')

# Replace tasks with janitorTasks and attendantTasks
old_tasks = '''  final List<String>? tasks;

  CoachAssignment({
    required this.coachPosition,
    required this.coachType,
    this.janitorId,
    this.janitorName,
    this.attendantId,
    this.attendantName,
    this.tasks,
  });

  factory CoachAssignment.fromJson(Map<String, dynamic> json) {
    return CoachAssignment(
      coachPosition: json['coachPosition'] as int? ?? 0,
      coachType: json['coachType'] as String? ?? '',
      janitorId: json['janitorId'] as String?,
      janitorName: json['janitorName'] as String?,
      attendantId: json['attendantId'] as String?,
      attendantName: json['attendantName'] as String?,
      tasks: (json['tasks'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'coachPosition': coachPosition,
      'coachType': coachType,
      if (janitorId != null && janitorId!.isNotEmpty) 'janitorId': janitorId,
      if (janitorName != null && janitorName!.isNotEmpty) 'janitorName': janitorName,
      if (attendantId != null && attendantId!.isNotEmpty) 'attendantId': attendantId,
      if (attendantName != null && attendantName!.isNotEmpty) 'attendantName': attendantName,
      if (tasks != null) 'tasks': tasks,
    };
  }

  CoachAssignment copyWith({
    int? coachPosition,
    String? coachType,
    String? janitorId,
    String? janitorName,
    String? attendantId,
    String? attendantName,
    List<String>? tasks,
  }) {
    return CoachAssignment(
      coachPosition: coachPosition ?? this.coachPosition,
      coachType: coachType ?? this.coachType,
      janitorId: janitorId ?? this.janitorId,
      janitorName: janitorName ?? this.janitorName,
      attendantId: attendantId ?? this.attendantId,
      attendantName: attendantName ?? this.attendantName,
      tasks: tasks ?? this.tasks,
    );
  }'''

new_tasks = '''  final List<String>? janitorTasks;
  final List<String>? attendantTasks;

  CoachAssignment({
    required this.coachPosition,
    required this.coachType,
    this.janitorId,
    this.janitorName,
    this.attendantId,
    this.attendantName,
    this.janitorTasks,
    this.attendantTasks,
  });

  factory CoachAssignment.fromJson(Map<String, dynamic> json) {
    return CoachAssignment(
      coachPosition: json['coachPosition'] as int? ?? 0,
      coachType: json['coachType'] as String? ?? '',
      janitorId: json['janitorId'] as String?,
      janitorName: json['janitorName'] as String?,
      attendantId: json['attendantId'] as String?,
      attendantName: json['attendantName'] as String?,
      janitorTasks: (json['janitorTasks'] as List<dynamic>?)?.map((e) => e as String).toList(),
      attendantTasks: (json['attendantTasks'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'coachPosition': coachPosition,
      'coachType': coachType,
      if (janitorId != null && janitorId!.isNotEmpty) 'janitorId': janitorId,
      if (janitorName != null && janitorName!.isNotEmpty) 'janitorName': janitorName,
      if (attendantId != null && attendantId!.isNotEmpty) 'attendantId': attendantId,
      if (attendantName != null && attendantName!.isNotEmpty) 'attendantName': attendantName,
      if (janitorTasks != null) 'janitorTasks': janitorTasks,
      if (attendantTasks != null) 'attendantTasks': attendantTasks,
    };
  }

  CoachAssignment copyWith({
    int? coachPosition,
    String? coachType,
    String? janitorId,
    String? janitorName,
    String? attendantId,
    String? attendantName,
    List<String>? janitorTasks,
    List<String>? attendantTasks,
  }) {
    return CoachAssignment(
      coachPosition: coachPosition ?? this.coachPosition,
      coachType: coachType ?? this.coachType,
      janitorId: janitorId ?? this.janitorId,
      janitorName: janitorName ?? this.janitorName,
      attendantId: attendantId ?? this.attendantId,
      attendantName: attendantName ?? this.attendantName,
      janitorTasks: janitorTasks ?? this.janitorTasks,
      attendantTasks: attendantTasks ?? this.attendantTasks,
    );
  }'''

content = content.replace(old_tasks, new_tasks)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
