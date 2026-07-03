import { z } from 'zod';

export const loginSchema = z.object({
  email: z.string().email('Invalid email format').max(255, 'Email too long'),
  password: z.string().min(6, 'Password must be at least 6 characters').max(128, 'Password too long')
});

export const createUserSchema = z.object({
  email: z.string().email('Invalid email format').max(255, 'Email too long'),
  password: z.string().min(6, 'Password must be at least 6 characters').max(128, 'Password too long'),
  fullName: z.string().min(2, 'Full name must be at least 2 characters').max(100, 'Name too long'),
  mobile: z.string().regex(/^\d{10}$/, 'Mobile must be 10 digits').optional().nullable(),
  role: z.string().min(2, 'Role is required').max(50, 'Role too long'),
  zone: z.string().max(100, 'Zone too long').optional().nullable(),
  division: z.string().max(100, 'Division too long').optional().nullable(),
  depot: z.string().max(100, 'Depot too long').optional().nullable(),
  entityId: z.string().max(100, 'Entity ID too long').optional().nullable()
});

export const bulkCreateUsersSchema = z.object({
  users: z.array(z.object({
    email: z.string().email('Invalid email format').max(255, 'Email too long'),
    password: z.string().min(6, 'Password must be at least 6 characters').max(128, 'Password too long'),
    fullName: z.string().min(2, 'Full name must be at least 2 characters').max(100, 'Name too long'),
    role: z.string().min(2, 'Role is required').max(50, 'Role too long'),
    mobile: z.string().regex(/^\d{10}$/, 'Mobile must be 10 digits').optional().nullable(),
    zone: z.string().max(100, 'Zone too long').optional().nullable(),
    division: z.string().max(100, 'Division too long').optional().nullable(),
    depot: z.string().max(100, 'Depot too long').optional().nullable(),
    entityId: z.string().max(100, 'Entity ID too long').optional().nullable()
  })).min(1, 'At least one user is required').max(100, 'Maximum 100 users per request')
});

export const createStationSchema = z.object({
  stationCode: z.string().min(1, 'Station code is required').max(50, 'Station code too long'),
  stationName: z.string().min(1, 'Station name is required').max(200, 'Station name too long'),
  division: z.string().min(1, 'Division is required').max(100, 'Division too long'),
  zone: z.string().max(100, 'Zone too long').optional().nullable(),
  address: z.string().max(500, 'Address too long').optional().nullable(),
  latitude: z.number().min(-90).max(90).optional().nullable(),
  longitude: z.number().min(-180).max(180).optional().nullable(),
  active: z.boolean().optional()
});

export const createContractSchema = z.object({
  contractNumber: z.string().min(1, 'Contract number is required').max(100, 'Contract number too long'),
  entityId: z.string().min(1, 'Entity ID is required').max(100, 'Entity ID too long'),
  entityName: z.string().min(1, 'Entity name is required').max(200, 'Entity name too long'),
  zone: z.string().min(1, 'Zone is required').max(100, 'Zone too long'),
  division: z.string().min(1, 'Division is required').max(100, 'Division too long'),
  startDate: z.string().min(1, 'Start date is required').max(20, 'Invalid date format'),
  endDate: z.string().min(1, 'End date is required').max(20, 'Invalid date format'),
  contractValue: z.number().positive('Contract value must be positive'),
  status: z.string().max(50).optional()
});

export const createPlatformSchema = z.object({
  stationId: z.string().min(1, 'Station ID is required').max(100),
  platformNumber: z.string().min(1, 'Platform number is required').max(50),
  platformName: z.string().max(200).optional().nullable(),
  length: z.number().positive().max(10000).optional().nullable(),
  width: z.number().positive().max(1000).optional().nullable()
});

export const createAreaSchema = z.object({
  stationId: z.string().min(1, 'Station ID is required').max(100),
  platformId: z.string().min(1, 'Platform ID is required').max(100),
  areaName: z.string().min(1, 'Area name is required').max(200),
  areaType: z.string().max(100).optional().nullable(),
  areaSqft: z.number().positive().max(1000000).optional().nullable(),
  surfaceType: z.string().max(100).optional().nullable(),
  section: z.string().max(50).optional().nullable(),
  sectionName: z.string().max(200).optional().nullable()
});

export const createShiftSchema = z.object({
  stationId: z.string().min(1, 'Station ID is required').max(100),
  shiftType: z.string().min(1, 'Shift type is required').max(50),
  startTime: z.string().regex(/^\d{2}:\d{2}$/, 'Start time must be HH:MM format'),
  endTime: z.string().regex(/^\d{2}:\d{2}$/, 'End time must be HH:MM format')
});

export const createGeofenceSchema = z.object({
  stationId: z.string().min(1, 'Station ID is required').max(100),
  name: z.string().min(1, 'Name is required').max(200),
  centerLatitude: z.number().min(-90).max(90, 'Latitude must be between -90 and 90'),
  centerLongitude: z.number().min(-180).max(180, 'Longitude must be between -180 and 180'),
  radiusMeters: z.number().positive('Radius must be positive'),
  type: z.string().optional().nullable(),
  platformId: z.string().optional().nullable()
});

export const markAttendanceSchema = z.object({
  runInstanceId: z.string().min(1, 'Run instance ID is required'),
  attendanceType: z.enum(['start', 'mid', 'end'], 'Attendance type must be start, mid, or end'),
  imageUrl: z.string().url('Image URL must be a valid URL'),
  latitude: z.number().min(-90).max(90).optional().nullable(),
  longitude: z.number().min(-180).max(180).optional().nullable(),
  deviceTimestamp: z.string().min(1, 'Device timestamp is required'),
  mobileNumber: z.string().optional().nullable(),
  deviceId: z.string().optional().nullable(),
  geofenceOverride: z.boolean().optional()
});

export const billingConfigSchema = z.object({
  contractId: z.string().min(1, 'Contract ID is required'),
  deductionRate: z.number().min(0).max(100, 'Deduction rate must be 0-100').optional(),
  performanceWeight: z.number().min(0).max(100, 'Weight must be 0-100').optional(),
  attendanceWeight: z.number().min(0).max(100, 'Weight must be 0-100').optional(),
  taskWeight: z.number().min(0).max(100, 'Weight must be 0-100').optional(),
  feedbackWeight: z.number().min(0).max(100, 'Weight must be 0-100').optional(),
  bonusRate: z.number().min(0).max(100, 'Bonus rate must be 0-100').optional()
});

export const createDeploymentSchema = z.object({
  workerId: z.string().min(1, 'Worker ID is required'),
  stationId: z.string().min(1, 'Station ID is required'),
  taskId: z.string().min(1, 'Task ID is required'),
  shiftId: z.string().min(1, 'Shift ID is required'),
  platformId: z.string().optional().nullable(),
  areaId: z.string().optional().nullable(),
  supervisorId: z.string().optional().nullable(),
  startDate: z.string().optional().nullable(),
  endDate: z.string().optional().nullable()
});

export const createMachineSchema = z.object({
  machineName: z.string().min(1, 'Machine name is required'),
  machineType: z.string().min(1, 'Machine type is required'),
  serialNumber: z.string().min(1, 'Serial number is required'),
  stationId: z.string().min(1, 'Station ID is required'),
  location: z.string().optional().nullable(),
  workingStatus: z.enum(['working', 'under_maintenance', 'broken', 'retired']).optional(),
  maintenanceSchedule: z.string().optional().nullable(),
  hourlyRate: z.number().min(0).optional().nullable(),
  dailyRate: z.number().min(0).optional().nullable(),
  remarks: z.string().optional().nullable()
});

export const createMaterialSchema = z.object({
  materialName: z.string().min(1, 'Material name is required'),
  materialType: z.string().min(1, 'Material type is required'),
  unit: z.string().min(1, 'Unit is required'),
  stationId: z.string().optional().nullable(),
  openingBalance: z.number().min(0).optional(),
  reorderLevel: z.number().min(0).optional(),
  unitPrice: z.number().min(0).optional().nullable()
});

export const paginationSchema = z.object({
  page: z.string().optional(),
  limit: z.string().optional(),
  cursor: z.string().optional()
});
