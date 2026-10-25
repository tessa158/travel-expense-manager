# Database notes (`travel_expense_manager`)

Tables: `roles`, `users`, `categories`, `trips`, `trip_participants`, `expenses`, `receipts`, `expense_splits`, `settlements`, `notifications`, `audit_logs`, `app_settings`, `sessions`.

Relationships
- users → trips → expenses → receipts (1:1) / expense_splits
- trips → trip_participants → expense_splits, settlements, expenses.paid_by_participant_id
- expenses → categories (RESTRICT: categories are deactivated, never deleted, so history stays intact)
- audit_logs.user_id is SET NULL so logs survive account changes

Rules
- All money columns are `DECIMAL` (amounts 14,2; exchange rate 18,8).
- CHECK constraints: trip dates, non-negative budget, threshold 1-100, supported currencies, positive amounts.
- Passwords are bcrypt hashes in `users.password_hash`; sessions live in `sessions`.
- Receipt files are stored in `backend/uploads` under random names; only metadata is in `receipts`.
- Deleting a trip removes its expenses, participants, splits, settlements, notifications and receipt files (the API deletes in the right order).
