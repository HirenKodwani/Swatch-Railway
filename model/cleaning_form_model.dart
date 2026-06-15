class CleaningFormModel {
  final String title;
  final String urgency;
  final String status;
  final String contractor;
  final String trainOrArea;
  final String supervisor;
  final int employees;
  final String submittedDate;
  final String depot;
  final String formId;
  final String assignedTo;
  bool isAccepted;
  bool isScored;
  bool isLocked;
  final bool isCoachCleaning;

  CleaningFormModel({
    required this.title,
    required this.urgency,
    required this.status,
    required this.contractor,
    required this.trainOrArea,
    required this.supervisor,
    required this.employees,
    required this.submittedDate,
    required this.depot,
    required this.formId,
    required this.assignedTo,
    this.isAccepted = false,
    this.isScored = false,
    this.isLocked = false,
    this.isCoachCleaning = false,
  });
}
