class RailwaySupervisor {
  final String uid;
  final String fullName;
  final String division;
  final String depot;

  RailwaySupervisor({
    required this.uid,
    required this.fullName,
    required this.division,
    required this.depot,
  });

  factory RailwaySupervisor.fromJson(Map<String, dynamic> json) {
    return RailwaySupervisor(
      uid: json['uid'],
      fullName: json['fullName'],
      division: json['division'],
      depot: json['depot'],
    );
  }
}
