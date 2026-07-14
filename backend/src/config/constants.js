export const EVIDENCE_TYPES = [
  'Before', 'After', 'Exception', 'Complaint', 'Resolution',
  'Attendance', 'FaceVerification', 'GPSVerification',
  'SupervisorVerification', 'LinenEvidence', 'PassengerComplaintEvidence'
];

export const STORAGE_TIER = {
  ACTIVE: 'active',
  ARCHIVE: 'archive',
  LONG_TERM: 'long_term'
};

export const COLORS = {
  primary: '#0e3a75',
  secondary: '#1c6abf',
  success: '#1e8e3e',
  danger: '#d93025',
  warning: '#f29900',
  text: '#333333',
  lightGray: '#f5f5f5',
  border: '#dddddd',
  white: '#ffffff'
};

export const PENALTY_MAP = { 'A': 0, 'B': 50, 'C': 100, 'D': 200 };

export { ROLE_HIERARCHY } from '../permissions/roles.js';

export const LINEN_TASKS = [
  'Linen distribution',
  'Linen verification',
  'Linen collection',
  'Stock confirmation',
  'Coach handover'
];

export const SUPERVISOR_TASKS = [
  'Safety equipment inspection',
  'Fire extinguisher status',
  'FSDS verification',
  'Water availability',
  'Petty repairs',
  'Coach fittings',
  'Minor plumbing',
  'Minor mechanical issues',
  'Minor electrical issues',
  'Garbage disposal verification',
  'Passenger assistance',
  'General coach verification',
  'Watering coordination',
  'Task escalation',
  'Evidence verification'
];

export const GARBAGE_TIMES = ['07:00', '10:00', '13:00', '16:00', '19:00'];
export const WATER_CHECK_TIMES = ['08:00', '12:00', '16:00', '20:00'];
export const SAFETY_INSPECTION_TIMES = ['10:00', '14:00', '18:00'];
export const PETTY_REPAIR_TIMES = ['10:00', '14:00', '18:00'];
export const BERTH_INSPECTION_TIMES = ['08:00', '18:00'];

export const EVIDENCE_COLLECTIONS = ['evidence_metadata', 'archive_evidence', 'long_term_evidence'];

export const AC_COACH_PREFIXES = ['A', 'B', 'H', 'M', 'C', 'E', 'AC', 'A1', 'B1', 'H1', 'M1', 'C1', 'E1',
  '2AC', '3AC', '1AC', '2A', '3A', '1A', 'EA', 'EC', 'AB', 'HA', 'MA'];

export const ALLOWED_TRAIN_FIELDS = [
  'trainNo', 'trainName', 'origin', 'destination', 'days',
  'zone', 'division', 'depot', 'status', 'TrainApplicableFor',
  'outboundTrainNo', 'inboundTrainNo', 'returnOffset', 'cycleLength',
  'outboundDurationStr', 'inboundDurationStr', 'layoverDestStr', 'layoverOriginStr',
  'journeyStartTime'
];
