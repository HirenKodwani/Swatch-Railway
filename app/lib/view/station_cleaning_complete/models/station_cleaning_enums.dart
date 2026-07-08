enum UserRole {
  superAdmin, admin, stationMaster, railwaySupervisor,
  contractorAdmin, contractorSupervisor, platformMaster, worker
}

enum ComplaintStatus { reported, assigned, inProgress, resolved, closed, reopened, rejected, escalated }

enum DailyActivityStatus { pending, inProgress, completed, partiallyCompleted, rejected, resubmitted, approved }

enum PlanStatus { draft, submitted, approved, rejected, returned }

enum InspectionStatus { scheduled, inProgress, completed, approved, rejected }

enum FeedbackCategory {
  toiletCleanliness, platformCleanliness, waitingRoomCleanliness,
  garbageDustbin, smellOdour, waterBoothCleanliness, staffBehaviour, other
}

enum AttendanceMode { biometric, manual, api, autoFlag }
enum AttendanceStatus { present, late, absent, onLeave }

enum PestTreatmentType { rodentControl, pestControl, termiteControl, disinfection, other }
