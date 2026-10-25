-- =====================================================================
-- Travel Expense Manager - seed data (run AFTER schema.sql)
-- Part 1: REQUIRED reference data (roles, categories, settings).
-- Part 2: OPTIONAL DEMO DATA - everything marked "(DEMO DATA)" or demo_user is fake
--         and exists only so you can try the app. Delete Part 2 for real use.
-- Safe to run more than once.
-- The administrator account is NOT created here: use "npm run create-admin".
-- =====================================================================
USE travel_expense_manager;

-- ---------- Part 1: required reference data ----------
INSERT IGNORE INTO roles (name) VALUES ('user'), ('admin');

INSERT IGNORE INTO categories (name, color, is_default) VALUES
  ('Food',          '#f59e0b', 1),
  ('Transport',     '#0ea5e9', 1),
  ('Accommodation', '#0b2545', 1),
  ('Shopping',      '#ec4899', 1),
  ('Entertainment', '#8b5cf6', 1),
  ('Other',         '#64748b', 1);

INSERT IGNORE INTO app_settings (setting_key, setting_value, description) VALUES
  ('default_warning_threshold', '80', 'Budget warning percentage used for newly created trips');

-- ---------- Part 2: DEMO DATA (optional) ----------
-- Demo login ->  username: demo_user   password: Demo@12345   (demo account, change or delete for real use)
INSERT INTO users (role_id, username, email, password_hash, full_name)
SELECT (SELECT id FROM roles WHERE name = 'user'), 'demo_user', 'demo.user@example.com',
       '$2b$12$uUsmpIJ2eZ1F0xMlsz6zSefYRyikg.5KAMEzAtS92TAhEBs7XUMYy', 'Demo Traveller'
WHERE NOT EXISTS (SELECT 1 FROM users WHERE username = 'demo_user');

SET @uid := (SELECT id FROM users WHERE username = 'demo_user');

-- Demo trip 1: Goa (INR) with a group split and one USD expense
INSERT INTO trips (user_id, name, destination, start_date, end_date, total_budget, base_currency, description, warning_threshold)
SELECT @uid, 'Goa Getaway (DEMO DATA)', 'Goa, India', CURDATE() - INTERVAL 3 DAY, CURDATE() + INTERVAL 4 DAY,
       40000.00, 'INR', 'Demo trip created by seed.sql. Not real data.', 80
WHERE NOT EXISTS (SELECT 1 FROM trips WHERE user_id = @uid AND name = 'Goa Getaway (DEMO DATA)');

SET @goa := (SELECT id FROM trips WHERE user_id = @uid AND name = 'Goa Getaway (DEMO DATA)');

INSERT IGNORE INTO trip_participants (trip_id, name, email, is_owner) VALUES
  (@goa, 'Demo Traveller', 'demo.user@example.com', 1),
  (@goa, 'Asha (demo)', NULL, 0),
  (@goa, 'Ravi (demo)', NULL, 0);

SET @p_owner := (SELECT id FROM trip_participants WHERE trip_id = @goa AND name = 'Demo Traveller');
SET @p_asha  := (SELECT id FROM trip_participants WHERE trip_id = @goa AND name = 'Asha (demo)');
SET @p_ravi  := (SELECT id FROM trip_participants WHERE trip_id = @goa AND name = 'Ravi (demo)');

SET @has_goa_expenses := (SELECT COUNT(*) FROM expenses WHERE trip_id = @goa);

-- 1. Resort (group, equal split, paid by owner)
INSERT INTO expenses (trip_id, user_id, category_id, title, amount_original, currency_original, exchange_rate, rate_source, amount_converted, expense_date, payment_method, merchant, notes, paid_by_participant_id)
SELECT @goa, @uid, (SELECT id FROM categories WHERE name = 'Accommodation'), 'Beach resort (3 nights)', 18000, 'INR', 1, 'same', 18000, CURDATE() - INTERVAL 3 DAY, 'Card', 'Seaside Resort', 'Demo expense', @p_owner
WHERE @has_goa_expenses = 0;
SET @e := LAST_INSERT_ID();
INSERT INTO expense_splits (expense_id, participant_id, share_amount)
SELECT @e, id, 6000 FROM trip_participants WHERE trip_id = @goa AND @has_goa_expenses = 0;

-- 2. Seafood dinner (group, paid by Asha)
INSERT INTO expenses (trip_id, user_id, category_id, title, amount_original, currency_original, exchange_rate, rate_source, amount_converted, expense_date, payment_method, merchant, notes, paid_by_participant_id)
SELECT @goa, @uid, (SELECT id FROM categories WHERE name = 'Food'), 'Seafood dinner', 2400, 'INR', 1, 'same', 2400, CURDATE() - INTERVAL 2 DAY, 'UPI', 'Fisherman''s Wharf', 'Demo expense', @p_asha
WHERE @has_goa_expenses = 0;
SET @e := LAST_INSERT_ID();
INSERT INTO expense_splits (expense_id, participant_id, share_amount)
SELECT @e, id, 800 FROM trip_participants WHERE trip_id = @goa AND @has_goa_expenses = 0;

-- 3. Scooter rental (group, paid by Ravi)
INSERT INTO expenses (trip_id, user_id, category_id, title, amount_original, currency_original, exchange_rate, rate_source, amount_converted, expense_date, payment_method, merchant, notes, paid_by_participant_id)
SELECT @goa, @uid, (SELECT id FROM categories WHERE name = 'Transport'), 'Scooter rental', 1500, 'INR', 1, 'same', 1500, CURDATE() - INTERVAL 2 DAY, 'Cash', 'Goa Wheels', 'Demo expense', @p_ravi
WHERE @has_goa_expenses = 0;
SET @e := LAST_INSERT_ID();
INSERT INTO expense_splits (expense_id, participant_id, share_amount)
SELECT @e, id, 500 FROM trip_participants WHERE trip_id = @goa AND @has_goa_expenses = 0;

-- 4. Water sports paid in USD with a MANUAL exchange rate (demo rate, not a live rate)
INSERT INTO expenses (trip_id, user_id, category_id, title, amount_original, currency_original, exchange_rate, rate_source, amount_converted, expense_date, payment_method, merchant, notes)
SELECT @goa, @uid, (SELECT id FROM categories WHERE name = 'Entertainment'), 'Water sports package', 60, 'USD', 83.50000000, 'manual', 5010, CURDATE() - INTERVAL 1 DAY, 'Card', 'Blue Wave Adventures', 'Demo expense - rate 83.5 was typed in manually (demo value)'
WHERE @has_goa_expenses = 0;

-- 5-7. Personal expenses
INSERT INTO expenses (trip_id, user_id, category_id, title, amount_original, currency_original, exchange_rate, rate_source, amount_converted, expense_date, payment_method, merchant, notes)
SELECT @goa, @uid, (SELECT id FROM categories WHERE name = 'Shopping'), 'Souvenirs', 1800, 'INR', 1, 'same', 1800, CURDATE() - INTERVAL 1 DAY, 'UPI', 'Anjuna Flea Market', 'Demo expense'
WHERE @has_goa_expenses = 0;
INSERT INTO expenses (trip_id, user_id, category_id, title, amount_original, currency_original, exchange_rate, rate_source, amount_converted, expense_date, payment_method, merchant, notes)
SELECT @goa, @uid, (SELECT id FROM categories WHERE name = 'Transport'), 'Airport taxi', 900, 'INR', 1, 'same', 900, CURDATE() - INTERVAL 3 DAY, 'Cash', 'Prepaid taxi counter', 'Demo expense'
WHERE @has_goa_expenses = 0;
INSERT INTO expenses (trip_id, user_id, category_id, title, amount_original, currency_original, exchange_rate, rate_source, amount_converted, expense_date, payment_method, merchant, notes)
SELECT @goa, @uid, (SELECT id FROM categories WHERE name = 'Food'), 'Cafe hopping', 2500, 'INR', 1, 'same', 2500, CURDATE(), 'UPI', 'Various cafes', 'Demo expense'
WHERE @has_goa_expenses = 0;

-- A demo budget warning (32,110 of 40,000 = 80%)
INSERT INTO notifications (user_id, trip_id, type, message)
SELECT @uid, @goa, 'budget_warning', 'Goa Getaway (DEMO DATA) has used 80% of its budget (INR 32110.00 of INR 40000.00).'
WHERE @has_goa_expenses = 0;

-- Demo trip 2: London (GBP) - shows that every trip keeps its own budget and currency
INSERT INTO trips (user_id, name, destination, start_date, end_date, total_budget, base_currency, description, warning_threshold)
SELECT @uid, 'London Weekend (DEMO DATA)', 'London, UK', CURDATE() + INTERVAL 30 DAY, CURDATE() + INTERVAL 34 DAY,
       1500.00, 'GBP', 'Second demo trip. Not real data.', 75
WHERE NOT EXISTS (SELECT 1 FROM trips WHERE user_id = @uid AND name = 'London Weekend (DEMO DATA)');

SET @london := (SELECT id FROM trips WHERE user_id = @uid AND name = 'London Weekend (DEMO DATA)');
INSERT IGNORE INTO trip_participants (trip_id, name, email, is_owner) VALUES (@london, 'Demo Traveller', 'demo.user@example.com', 1);

INSERT INTO expenses (trip_id, user_id, category_id, title, amount_original, currency_original, exchange_rate, rate_source, amount_converted, expense_date, payment_method, merchant, notes)
SELECT @london, @uid, (SELECT id FROM categories WHERE name = 'Transport'), 'Flight deposit', 300, 'GBP', 1, 'same', 300, CURDATE(), 'Card', 'Demo Airways', 'Demo expense'
WHERE (SELECT COUNT(*) FROM expenses WHERE trip_id = @london) = 0;
