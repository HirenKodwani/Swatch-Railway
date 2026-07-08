# Firestore Composite Indexes

Create these in Firebase Console > Firestore > Indexes:

## 1. RunInstance division + createdAt
```
Collection: RunInstance
Fields:
  - division: Ascending
  - createdAt: Descending
```
Used by: `runInstanceService.js:278` (list run instances by division)

## 2. RunInstance status + createdAt
```
Collection: RunInstance
Fields:
  - status: Ascending
  - createdAt: Descending
```
Used by: `obhsService.js:780` (active/scheduled run instances ordered by date)

## 3. notifications userId + createdAt
```
Collection: notifications
Fields:
  - userId: Ascending
  - createdAt: Descending
```
Used by: `notificationService.js:13` (list notifications for a user sorted by recency)
