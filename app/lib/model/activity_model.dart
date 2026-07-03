class Activity {
  final String? uid;
  final String activityName;
  final String activityType;
  final String description;
  final String unit;
  final String defaultFrequency;
  final String status;

  Activity({
    this.uid,
    required this.activityName,
    this.activityType = 'other',
    this.description = '',
    this.unit = '',
    this.defaultFrequency = '',
    this.status = 'active',
  });

  factory Activity.fromJson(Map<String, dynamic> json) => Activity(
    uid: json['uid'],
    activityName: json['activityName'] ?? '',
    activityType: json['activityType'] ?? 'other',
    description: json['description'] ?? '',
    unit: json['unit'] ?? '',
    defaultFrequency: json['defaultFrequency'] ?? '',
    status: json['status'] ?? 'active',
  );

  Map<String, dynamic> toJson() => {
    if (uid != null) 'uid': uid,
    'activityName': activityName,
    'activityType': activityType,
    'description': description,
    'unit': unit,
    'defaultFrequency': defaultFrequency,
    'status': status,
  };
}
