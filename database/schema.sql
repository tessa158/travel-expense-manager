-- =====================================================================
-- Travel Expense Manager - database schema (MySQL 8.0+)
-- Run this whole file in MySQL Workbench (File > Open SQL Script > Run).
-- It is safe to run more than once: tables are only created if missing.
-- =====================================================================
CREATE DATABASE IF NOT EXISTS travel_expense_manager
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE travel_expense_manager;

-- ---------- Users and roles ----------
CREATE TABLE IF NOT EXISTS roles (
  id   TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(20) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_roles_name (name)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS users (
  id            INT UNSIGNED NOT NULL AUTO_INCREMENT,
  role_id       TINYINT UNSIGNED NOT NULL,
  username      VARCHAR(30)  NOT NULL,
  email         VARCHAR(190) NOT NULL,
  password_hash VARCHAR(100) NOT NULL,           -- bcrypt hash, never the password
  full_name     VARCHAR(100) NULL,
  is_active     TINYINT(1)   NOT NULL DEFAULT 1,
  last_login_at DATETIME     NULL,
  created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_users_username (username),
  UNIQUE KEY uq_users_email (email),
  KEY idx_users_role (role_id),
  CONSTRAINT fk_users_role FOREIGN KEY (role_id) REFERENCES roles (id)
) ENGINE=InnoDB;

-- ---------- Categories ----------
CREATE TABLE IF NOT EXISTS categories (
  id         SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name       VARCHAR(60) NOT NULL,
  color      CHAR(7)     NOT NULL DEFAULT '#0f9d93',
  is_active  TINYINT(1)  NOT NULL DEFAULT 1,
  is_default TINYINT(1)  NOT NULL DEFAULT 0,
  created_at DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_categories_name (name)
) ENGINE=InnoDB;

-- ---------- Trips ----------
CREATE TABLE IF NOT EXISTS trips (
  id                INT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id           INT UNSIGNED NOT NULL,
  name              VARCHAR(120) NOT NULL,
  destination       VARCHAR(120) NOT NULL,
  start_date        DATE NOT NULL,
  end_date          DATE NOT NULL,
  total_budget      DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  base_currency     CHAR(3) NOT NULL DEFAULT 'INR',
  description       TEXT NULL,
  warning_threshold TINYINT UNSIGNED NOT NULL DEFAULT 80,   -- % of budget that triggers a warning
  is_archived       TINYINT(1) NOT NULL DEFAULT 0,
  created_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_trips_user (user_id, is_archived),
  CONSTRAINT fk_trips_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
  CONSTRAINT chk_trips_dates CHECK (end_date >= start_date),
  CONSTRAINT chk_trips_budget CHECK (total_budget >= 0),
  CONSTRAINT chk_trips_threshold CHECK (warning_threshold BETWEEN 1 AND 100),
  CONSTRAINT chk_trips_currency CHECK (base_currency IN ('INR','USD','EUR','GBP'))
) ENGINE=InnoDB;

-- ---------- Trip participants (for group splitting) ----------
CREATE TABLE IF NOT EXISTS trip_participants (
  id         INT UNSIGNED NOT NULL AUTO_INCREMENT,
  trip_id    INT UNSIGNED NOT NULL,
  name       VARCHAR(80) NOT NULL,
  email      VARCHAR(190) NULL,
  is_owner   TINYINT(1) NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_participant_name (trip_id, name),
  CONSTRAINT fk_participants_trip FOREIGN KEY (trip_id) REFERENCES trips (id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------- Expenses ----------
-- amount_original/currency_original = what was actually paid.
-- exchange_rate + rate_source + amount_converted = frozen at save time, so history never changes.
CREATE TABLE IF NOT EXISTS expenses (
  id                     BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  trip_id                INT UNSIGNED NOT NULL,
  user_id                INT UNSIGNED NOT NULL,
  category_id            SMALLINT UNSIGNED NOT NULL,
  title                  VARCHAR(150) NOT NULL,
  amount_original        DECIMAL(14,2) NOT NULL,
  currency_original      CHAR(3) NOT NULL,
  exchange_rate          DECIMAL(18,8) NOT NULL DEFAULT 1.00000000,
  rate_source            ENUM('same','manual','api') NOT NULL DEFAULT 'same',
  amount_converted       DECIMAL(14,2) NOT NULL,           -- in the trip's base currency
  expense_date           DATE NOT NULL,
  payment_method         VARCHAR(30) NOT NULL DEFAULT 'Cash',
  merchant               VARCHAR(150) NULL,
  notes                  TEXT NULL,
  paid_by_participant_id INT UNSIGNED NULL,                -- only set for split expenses
  created_at             DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at             DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_expenses_trip_date (trip_id, expense_date),
  KEY idx_expenses_user (user_id),
  KEY idx_expenses_category (category_id),
  CONSTRAINT fk_expenses_trip     FOREIGN KEY (trip_id) REFERENCES trips (id) ON DELETE CASCADE,
  CONSTRAINT fk_expenses_user     FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
  CONSTRAINT fk_expenses_category FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE RESTRICT,
  CONSTRAINT fk_expenses_payer    FOREIGN KEY (paid_by_participant_id) REFERENCES trip_participants (id) ON DELETE RESTRICT,
  CONSTRAINT chk_expenses_amount CHECK (amount_original > 0 AND amount_converted >= 0),
  CONSTRAINT chk_expenses_currency CHECK (currency_original IN ('INR','USD','EUR','GBP'))
) ENGINE=InnoDB;

-- ---------- Receipts (one per expense; the file lives in backend/uploads) ----------
CREATE TABLE IF NOT EXISTS receipts (
  id            INT UNSIGNED NOT NULL AUTO_INCREMENT,
  expense_id    BIGINT UNSIGNED NOT NULL,
  stored_name   VARCHAR(100) NOT NULL,
  original_name VARCHAR(255) NOT NULL,
  mime_type     VARCHAR(60)  NOT NULL,
  size_bytes    INT UNSIGNED NOT NULL,
  uploaded_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_receipts_expense (expense_id),
  CONSTRAINT fk_receipts_expense FOREIGN KEY (expense_id) REFERENCES expenses (id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------- Expense splits (share_amount is in the trip's base currency) ----------
CREATE TABLE IF NOT EXISTS expense_splits (
  id             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  expense_id     BIGINT UNSIGNED NOT NULL,
  participant_id INT UNSIGNED NOT NULL,
  share_amount   DECIMAL(14,2) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_split (expense_id, participant_id),
  KEY idx_split_participant (participant_id),
  CONSTRAINT fk_splits_expense     FOREIGN KEY (expense_id) REFERENCES expenses (id) ON DELETE CASCADE,
  CONSTRAINT fk_splits_participant FOREIGN KEY (participant_id) REFERENCES trip_participants (id) ON DELETE RESTRICT,
  CONSTRAINT chk_split_amount CHECK (share_amount >= 0)
) ENGINE=InnoDB;

-- ---------- Settlements (recorded payments between participants) ----------
CREATE TABLE IF NOT EXISTS settlements (
  id                  INT UNSIGNED NOT NULL AUTO_INCREMENT,
  trip_id             INT UNSIGNED NOT NULL,
  from_participant_id INT UNSIGNED NOT NULL,   -- the person who paid money back
  to_participant_id   INT UNSIGNED NOT NULL,   -- the person who received it
  amount              DECIMAL(14,2) NOT NULL,
  note                VARCHAR(200) NULL,
  settled_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_by          INT UNSIGNED NOT NULL,
  PRIMARY KEY (id),
  KEY idx_settlements_trip (trip_id),
  CONSTRAINT fk_settle_trip FOREIGN KEY (trip_id) REFERENCES trips (id) ON DELETE CASCADE,
  CONSTRAINT fk_settle_from FOREIGN KEY (from_participant_id) REFERENCES trip_participants (id) ON DELETE RESTRICT,
  CONSTRAINT fk_settle_to   FOREIGN KEY (to_participant_id) REFERENCES trip_participants (id) ON DELETE RESTRICT,
  CONSTRAINT fk_settle_user FOREIGN KEY (created_by) REFERENCES users (id) ON DELETE CASCADE,
  CONSTRAINT chk_settle_amount CHECK (amount > 0)
  -- (from <> to is validated by the API; MySQL does not allow CHECKs on foreign-key columns here)
) ENGINE=InnoDB;

-- ---------- Notifications ----------
CREATE TABLE IF NOT EXISTS notifications (
  id         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id    INT UNSIGNED NOT NULL,
  trip_id    INT UNSIGNED NULL,
  type       ENUM('budget_warning','budget_exceeded','info') NOT NULL DEFAULT 'info',
  message    VARCHAR(255) NOT NULL,
  is_read    TINYINT(1) NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_notifications_user (user_id, is_read),
  CONSTRAINT fk_notifications_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
  CONSTRAINT fk_notifications_trip FOREIGN KEY (trip_id) REFERENCES trips (id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------- Audit logs (kept even if the user is later removed) ----------
CREATE TABLE IF NOT EXISTS audit_logs (
  id         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id    INT UNSIGNED NULL,
  actor      VARCHAR(190) NULL,
  action     VARCHAR(50)  NOT NULL,
  status     ENUM('success','failure') NOT NULL DEFAULT 'success',
  entity     VARCHAR(40)  NULL,
  entity_id  VARCHAR(40)  NULL,
  ip         VARCHAR(64)  NULL,
  user_agent VARCHAR(255) NULL,
  details    JSON NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_audit_action (action),
  KEY idx_audit_created (created_at),
  KEY idx_audit_user (user_id),
  CONSTRAINT fk_audit_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- ---------- Application settings ----------
CREATE TABLE IF NOT EXISTS app_settings (
  setting_key   VARCHAR(60)  NOT NULL,
  setting_value VARCHAR(255) NOT NULL,
  description   VARCHAR(255) NULL,
  updated_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (setting_key)
) ENGINE=InnoDB;

-- ---------- Login sessions (used by express-mysql-session) ----------
CREATE TABLE IF NOT EXISTS sessions (
  session_id VARCHAR(128) COLLATE utf8mb4_bin NOT NULL,
  expires    INT UNSIGNED NOT NULL,
  data       MEDIUMTEXT COLLATE utf8mb4_bin,
  PRIMARY KEY (session_id)
) ENGINE=InnoDB;
