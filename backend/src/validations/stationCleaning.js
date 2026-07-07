import { z } from 'zod';

export const createStationAreaSchema = z.object({
  stationId: z.string().min(1, 'stationId required'),
  name: z.string().min(2, 'name must be at least 2 characters').max(100, 'name must be under 100 characters'),
  order: z.number().int().min(0).max(999).optional(),
  description: z.string().max(500, 'description must be under 500 characters').optional(),
});

export const createStationZoneSchema = z.object({
  stationId: z.string().min(1),
  areaId: z.string().min(1),
  name: z.string().min(1).max(100),
  description: z.string().max(500).optional(),
});

export const createScheduleSchema = z.object({
  stationId: z.string().min(1),
  frequency: z.enum(['daily', 'weekly', 'monthly', 'custom']).optional(),
  shift: z.enum(['Morning', 'Afternoon', 'Night']).optional(),
  daysOfWeek: z.array(z.string()).optional(),
});

export const createStationRunSchema = z.object({
  stationId: z.string().min(1),
  stationName: z.string().min(1),
  date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'date must be YYYY-MM-DD format'),
  shift: z.string().min(1),
});

export const submitStationTaskSchema = z.object({
  runInstanceId: z.string().min(1),
  platformNumber: z.string().min(1),
});

export const createStationCleaningFormSchema = z.object({
  stationId: z.string().min(1),
  division: z.string().min(1),
});
