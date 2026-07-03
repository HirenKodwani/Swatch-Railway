class Frequency {
  final String? uid;
  final String frequencyName;
  final String frequencyType;
  final int timesPerDay;
  final int daysBetween;
  final String description;
  final String status;

  Frequency({
    this.uid,
    required this.frequencyName,
    this.frequencyType = 'other',
    this.timesPerDay = 0,
    this.daysBetween = 0,
    this.description = '',
    this.status = 'active',
  });

  factory Frequency.fromJson(Map<String, dynamic> json) => Frequency(
    uid: json['uid'],
    frequencyName: json['frequencyName'] ?? '',
    frequencyType: json['frequencyType'] ?? 'other',
    timesPerDay: json['timesPerDay'] ?? 0,
    daysBetween: json['daysBetween'] ?? 0,
    description: json['description'] ?? '',
    status: json['status'] ?? 'active',
  );

  Map<String, dynamic> toJson() => {
    if (uid != null) 'uid': uid,
    'frequencyName': frequencyName,
    'frequencyType': frequencyType,
    'timesPerDay': timesPerDay,
    'daysBetween': daysBetween,
    'description': description,
    'status': status,
  };
}
