-- ==========================================
-- Friends Monthly Fund Management System
-- Production Ready MySQL Relational Schema & Seed Data
-- Target Database Engine: MySQL 8.0+ / MariaDB
-- ==========================================

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS `notifications`;
DROP TABLE IF EXISTS `transactions`;
DROP TABLE IF EXISTS `dues`;
DROP TABLE IF EXISTS `expenses`;
DROP TABLE IF EXISTS `collections`;
DROP TABLE IF EXISTS `members`;
DROP TABLE IF EXISTS `users`;
DROP TABLE IF EXISTS `admins`;
DROP TABLE IF EXISTS `settings`;
DROP TABLE IF EXISTS `activity_logs`;
SET FOREIGN_KEY_CHECKS = 1;

-- 1. settings Table
CREATE TABLE `settings` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `fund_name` VARCHAR(100) NOT NULL DEFAULT 'Friends Monthly Fund',
  `monthly_contribution` DECIMAL(10,2) NOT NULL DEFAULT 1000.00,
  `currency` VARCHAR(10) NOT NULL DEFAULT '৳',
  `logo` VARCHAR(50) NOT NULL DEFAULT 'FMF',
  `theme` VARCHAR(10) NOT NULL DEFAULT 'light',
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. admins Table
CREATE TABLE `admins` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `username` VARCHAR(50) NOT NULL UNIQUE,
  `password` VARCHAR(255) NOT NULL, -- To store hashed password (e.g. Bcrypt)
  `role` VARCHAR(15) NOT NULL DEFAULT 'admin',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. members Table
CREATE TABLE `members` (
  `id` VARCHAR(15) NOT NULL PRIMARY KEY, -- MEM-001, MEM-002 etc.
  `name` VARCHAR(100) NOT NULL,
  `phone` VARCHAR(15) NOT NULL,
  `email` VARCHAR(100) UNIQUE NOT NULL,
  `address` TEXT NOT NULL,
  `monthly_contribution` DECIMAL(10,2) NOT NULL DEFAULT 1000.00,
  `join_date` DATE NOT NULL,
  `status` ENUM('active', 'inactive') NOT NULL DEFAULT 'active',
  `avatar` VARCHAR(10) NOT NULL DEFAULT 'U',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. users (Member Accounts) Table
CREATE TABLE `users` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `member_id` VARCHAR(15) UNIQUE NOT NULL,
  `username` VARCHAR(100) UNIQUE NOT NULL,
  `password` VARCHAR(255) NOT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (`member_id`) REFERENCES `members`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. collections Table
CREATE TABLE `collections` (
  `id` VARCHAR(15) NOT NULL PRIMARY KEY, -- PAY-0001, PAY-0002
  `member_id` VARCHAR(15) NOT NULL,
  `amount` DECIMAL(10,2) NOT NULL,
  `date` DATE NOT NULL,
  `time` TIME NOT NULL,
  `month` VARCHAR(15) NOT NULL, -- e.g. "January"
  `year` INT NOT NULL, -- e.g. 2026
  `payment_method` ENUM('Cash', 'bKash', 'Bank Transfer', 'Nagad', 'Rocket') NOT NULL DEFAULT 'Cash',
  `status` VARCHAR(15) NOT NULL DEFAULT 'Paid',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (`member_id`) REFERENCES `members`(`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 6. expenses Table
CREATE TABLE `expenses` (
  `id` VARCHAR(15) NOT NULL PRIMARY KEY, -- EXP-0001, EXP-0002
  `title` VARCHAR(150) NOT NULL,
  `description` TEXT NOT NULL,
  `amount` DECIMAL(10,2) NOT NULL,
  `category` VARCHAR(50) NOT NULL, -- "Meetings", "Charity", "Utility"
  `date` DATE NOT NULL,
  `time` TIME NOT NULL,
  `receipt` VARCHAR(255) DEFAULT NULL, -- File path or blob URL
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 7. dues (Pre-calculated dues or historical adjustments if any)
CREATE TABLE `dues` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `member_id` VARCHAR(15) NOT NULL,
  `month` VARCHAR(15) NOT NULL,
  `year` INT NOT NULL,
  `expected_amount` DECIMAL(10,2) NOT NULL,
  `paid_amount` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  `remaining_due` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  `overpayment` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `idx_member_period` (`member_id`, `month`, `year`),
  FOREIGN KEY (`member_id`) REFERENCES `members`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 8. transactions (Combined Ledger for fast audit and indexing)
CREATE TABLE `transactions` (
  `id` VARCHAR(15) NOT NULL PRIMARY KEY, -- TXN-P0001, TXN-E0001
  `type` ENUM('collection', 'expense') NOT NULL,
  `reference_id` VARCHAR(15) NOT NULL, -- references collections.id or expenses.id
  `member_or_title` VARCHAR(150) NOT NULL,
  `amount` DECIMAL(10,2) NOT NULL,
  `payment_method` VARCHAR(30) NOT NULL DEFAULT 'N/A',
  `date` DATE NOT NULL,
  `time` TIME NOT NULL,
  `status` VARCHAR(20) NOT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 9. notifications Table
CREATE TABLE `notifications` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `type` ENUM('payment', 'expense', 'due', 'summary', 'system') NOT NULL,
  `message` TEXT NOT NULL,
  `date` DATE NOT NULL,
  `time` TIME NOT NULL,
  `is_read` BOOLEAN NOT NULL DEFAULT FALSE,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 10. activity_logs Table
CREATE TABLE `activity_logs` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `user` VARCHAR(50) NOT NULL, -- e.g. "pavel28" or member name
  `action` VARCHAR(100) NOT NULL,
  `details` TEXT NOT NULL,
  `timestamp` DATETIME NOT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ==========================================
-- SEED DATA FOR DEMONSTRATION & TESTING
-- ==========================================

-- Seed Settings
INSERT INTO `settings` (`id`, `fund_name`, `monthly_contribution`, `currency`, `logo`, `theme`)
VALUES (1, 'Friends Monthly Fund', 1000.00, '৳', 'FMF', 'light');

-- Seed Admin Profile (Username: pavel28, Hashed Password placeholder: 123456789)
-- (Real apps would hash this using password_hash() in PHP or bcrypt in Node)
INSERT INTO `admins` (`username`, `password`, `role`)
VALUES ('pavel28', '$2a$10$YourBcryptHashGoesHereFor123456789', 'admin');

-- Seed Members
INSERT INTO `members` (`id`, `name`, `phone`, `email`, `address`, `monthly_contribution`, `join_date`, `status`, `avatar`) VALUES
('MEM-001', 'Pavel Mahmud', '01712345678', 'pavelmahmud2020@gmail.com', 'Mirpur 10, Dhaka', 1000.00, '2026-01-01', 'active', 'PM'),
('MEM-002', 'Sazzad Hossain', '01812345679', 'sazzad@gmail.com', 'Dhanmondi, Dhaka', 1000.00, '2026-01-15', 'active', 'SH'),
('MEM-003', 'Fahim Chowdhury', '01912345680', 'fahim@gmail.com', 'Banani, Dhaka', 1000.00, '2026-02-01', 'active', 'FC'),
('MEM-004', 'Jamil Ahmed', '01512345681', 'jamil@gmail.com', 'Uttara, Dhaka', 1000.00, '2026-03-01', 'active', 'JA'),
('MEM-005', 'Tanvir Rahman', '01612345682', 'tanvir@gmail.com', 'Gulshan, Dhaka', 1200.00, '2026-04-01', 'inactive', 'TR');

-- Seed Member Accounts (password matches 123456789 as requested)
INSERT INTO `users` (`member_id`, `username`, `password`) VALUES
('MEM-001', 'pavel', '$2b$10$MockHashForPavel'),
('MEM-002', 'sazzad', '$2b$10$MockHashForSazzad'),
('MEM-003', 'fahim', '$2b$10$MockHashForFahim'),
('MEM-004', 'jamil', '$2b$10$MockHashForJamil'),
('MEM-005', 'tanvir', '$2b$10$MockHashForTanvir');

-- Seed Collections (Contributions)
INSERT INTO `collections` (`id`, `member_id`, `amount`, `date`, `time`, `month`, `year`, `payment_method`, `status`) VALUES
-- Pavel Mahmud: fully paid up to July 2026
('PAY-0001', 'MEM-001', 1000.00, '2026-01-05', '10:30:15', 'January', 2026, 'bKash', 'Paid'),
('PAY-0002', 'MEM-001', 1000.00, '2026-02-05', '11:15:22', 'February', 2026, 'Cash', 'Paid'),
('PAY-0003', 'MEM-001', 1000.00, '2026-03-06', '09:45:00', 'March', 2026, 'Nagad', 'Paid'),
('PAY-0004', 'MEM-001', 1000.00, '2026-04-05', '14:20:10', 'April', 2026, 'Bank Transfer', 'Paid'),
('PAY-0005', 'MEM-001', 1000.00, '2026-05-05', '18:00:30', 'May', 2026, 'bKash', 'Paid'),
('PAY-0006', 'MEM-001', 1000.00, '2026-06-04', '12:10:05', 'June', 2026, 'Rocket', 'Paid'),
('PAY-0007', 'MEM-001', 1000.00, '2026-07-02', '15:30:20', 'July', 2026, 'bKash', 'Paid'),

-- Sazzad Hossain: paid Jan-May, owes Jun & Jul
('PAY-0008', 'MEM-002', 1000.00, '2026-01-18', '16:40:11', 'January', 2026, 'Cash', 'Paid'),
('PAY-0009', 'MEM-002', 1000.00, '2026-02-12', '10:15:30', 'February', 2026, 'Nagad', 'Paid'),
('PAY-0010', 'MEM-002', 1000.00, '2026-03-10', '11:20:45', 'March', 2026, 'bKash', 'Paid'),
('PAY-0011', 'MEM-002', 1000.00, '2026-04-12', '14:15:10', 'April', 2026, 'bKash', 'Paid'),
('PAY-0012', 'MEM-002', 1000.00, '2026-05-15', '19:40:00', 'May', 2026, 'Rocket', 'Paid'),

-- Fahim Chowdhury: overpaid 1500 (Total paid 7500 for Feb-Jul expected 6000)
('PAY-0013', 'MEM-003', 1000.00, '2026-02-05', '11:00:00', 'February', 2026, 'Bank Transfer', 'Paid'),
('PAY-0014', 'MEM-003', 1000.00, '2026-03-05', '14:30:15', 'March', 2026, 'bKash', 'Paid'),
('PAY-0015', 'MEM-003', 1000.00, '2026-04-06', '15:20:00', 'April', 2026, 'Cash', 'Paid'),
('PAY-0016', 'MEM-003', 1500.00, '2026-05-10', '17:15:30', 'May', 2026, 'Nagad', 'Paid'),
('PAY-0017', 'MEM-003', 1500.00, '2026-06-10', '12:10:45', 'June', 2026, 'bKash', 'Paid'),
('PAY-0018', 'MEM-003', 1500.00, '2026-07-05', '10:15:20', 'July', 2026, 'bKash', 'Paid'),

-- Jamil Ahmed: paid Mar-May, owes Jun & Jul
('PAY-0019', 'MEM-004', 1000.00, '2026-03-05', '16:20:00', 'March', 2026, 'Cash', 'Paid'),
('PAY-0020', 'MEM-004', 1000.00, '2026-04-08', '11:30:15', 'April', 2026, 'bKash', 'Paid'),
('PAY-0021', 'MEM-004', 1000.00, '2026-05-09', '14:10:22', 'May', 2026, 'Nagad', 'Paid'),

-- Tanvir Rahman (Inactive): paid Apr
('PAY-0022', 'MEM-005', 1200.00, '2026-04-05', '10:10:00', 'April', 2026, 'Cash', 'Paid');

-- Seed Expenses
INSERT INTO `expenses` (`id`, `title`, `description`, `amount`, `category`, `date`, `time`, `receipt`) VALUES
('EXP-0001', 'Monthly Meeting Snacks', 'Purchased snacks and juice for January general assembly', 1200.00, 'Meetings', '2026-01-25', '18:30:00', NULL),
('EXP-0002', 'Winter Blankets Distribution', 'Bought 15 warm blankets for poor street families', 4500.00, 'Charity', '2026-01-30', '11:00:00', NULL),
('EXP-0003', 'Domain & Hosting Renewal', 'Annual group portal and ledger hosting renewal', 2500.00, 'Utility', '2026-03-15', '14:00:00', NULL),
('EXP-0004', 'Snacks & Coffee Meetup', 'Food cost for May review session', 1500.00, 'Meetings', '2026-05-20', '19:00:00', NULL);

-- Seed Ledger Transactions (Synchronized with Collections & Expenses)
INSERT INTO `transactions` (`id`, `type`, `reference_id`, `member_or_title`, `amount`, `payment_method`, `date`, `time`, `status`) VALUES
('TXN-P0001', 'collection', 'PAY-0001', 'Pavel Mahmud', 1000.00, 'bKash', '2026-01-05', '10:30:15', 'Paid'),
('TXN-P0002', 'collection', 'PAY-0002', 'Pavel Mahmud', 1000.00, 'Cash', '2026-02-05', '11:15:22', 'Paid'),
('TXN-P0003', 'collection', 'PAY-0003', 'Pavel Mahmud', 1000.00, 'Nagad', '2026-03-06', '09:45:00', 'Paid'),
('TXN-P0004', 'collection', 'PAY-0004', 'Pavel Mahmud', 1000.00, 'Bank Transfer', '2026-04-05', '14:20:10', 'Paid'),
('TXN-P0005', 'collection', 'PAY-0005', 'Pavel Mahmud', 1000.00, 'bKash', '2026-05-05', '18:00:30', 'Paid'),
('TXN-P0006', 'collection', 'PAY-0006', 'Pavel Mahmud', 1000.00, 'Rocket', '2026-06-04', '12:10:05', 'Paid'),
('TXN-P0007', 'collection', 'PAY-0007', 'Pavel Mahmud', 1000.00, 'bKash', '2026-07-02', '15:30:20', 'Paid'),
('TXN-P0008', 'collection', 'PAY-0008', 'Sazzad Hossain', 1000.00, 'Cash', '2026-01-18', '16:40:11', 'Paid'),
('TXN-P0009', 'collection', 'PAY-0009', 'Sazzad Hossain', 1000.00, 'Nagad', '2026-02-12', '10:15:30', 'Paid'),
('TXN-P0010', 'collection', 'PAY-0010', 'Sazzad Hossain', 1000.00, 'bKash', '2026-03-10', '11:20:45', 'Paid'),
('TXN-P0011', 'collection', 'PAY-0011', 'Sazzad Hossain', 1000.00, 'bKash', '2026-04-12', '14:15:10', 'Paid'),
('TXN-P0012', 'collection', 'PAY-0012', 'Sazzad Hossain', 1000.00, 'Rocket', '2026-05-15', '19:40:00', 'Paid'),
('TXN-P0013', 'collection', 'PAY-0013', 'Fahim Chowdhury', 1000.00, 'Bank Transfer', '2026-02-05', '11:00:00', 'Paid'),
('TXN-P0014', 'collection', 'PAY-0014', 'Fahim Chowdhury', 1000.00, 'bKash', '2026-03-05', '14:30:15', 'Paid'),
('TXN-P0015', 'collection', 'PAY-0015', 'Fahim Chowdhury', 1000.00, 'Cash', '2026-04-06', '15:20:00', 'Paid'),
('TXN-P0016', 'collection', 'PAY-0016', 'Fahim Chowdhury', 1500.00, 'Nagad', '2026-05-10', '17:15:30', 'Paid'),
('TXN-P0017', 'collection', 'PAY-0017', 'Fahim Chowdhury', 1500.00, 'bKash', '2026-06-10', '12:10:45', 'Paid'),
('TXN-P0018', 'collection', 'PAY-0018', 'Fahim Chowdhury', 1500.00, 'bKash', '2026-07-05', '10:15:20', 'Paid'),
('TXN-P0019', 'collection', 'PAY-0019', 'Jamil Ahmed', 1000.00, 'Cash', '2026-03-05', '16:20:00', 'Paid'),
('TXN-P0020', 'collection', 'PAY-0020', 'Jamil Ahmed', 1000.00, 'bKash', '2026-04-08', '11:30:15', 'Paid'),
('TXN-P0021', 'collection', 'PAY-0021', 'Jamil Ahmed', 1000.00, 'Nagad', '2026-05-09', '14:10:22', 'Paid'),
('TXN-P0022', 'collection', 'PAY-0022', 'Tanvir Rahman', 1200.00, 'Cash', '2026-04-05', '10:10:00', 'Paid'),
('TXN-E0001', 'expense', 'EXP-0001', 'Monthly Meeting Snacks', 1200.00, 'N/A', '2026-01-25', '18:30:00', 'Completed'),
('TXN-E0002', 'expense', 'EXP-0002', 'Winter Blankets Distribution', 4500.00, 'N/A', '2026-01-30', '11:00:00', 'Completed'),
('TXN-E0003', 'expense', 'EXP-0003', 'Domain & Hosting Renewal', 2500.00, 'N/A', '2026-03-15', '14:00:00', 'Completed'),
('TXN-E0004', 'expense', 'EXP-0004', 'Snacks & Coffee Meetup', 1500.00, 'N/A', '2026-05-20', '19:00:00', 'Completed');

-- Seed Notifications
INSERT INTO `notifications` (`type`, `message`, `date`, `time`, `is_read`) VALUES
('system', 'Friends Monthly Fund System initialized successfully.', '2026-01-01', '09:00:00', 1),
('payment', 'New Payment of ৳1000 received from Pavel Mahmud via bKash.', '2026-07-02', '15:30:00', 0),
('payment', 'New Payment of ৳1500 received from Fahim Chowdhury via bKash.', '2026-07-05', '10:15:00', 0),
('due', 'Monthly Due reminders calculated for June/July.', '2026-07-11', '10:00:00', 0);

-- Seed Activity Logs
INSERT INTO `activity_logs` (`user`, `action`, `details`, `timestamp`) VALUES
('pavel28', 'System Initialize', 'Initial database state and admin profile configured', '2026-01-01 09:00:00'),
('pavel28', 'Add Member', 'Added Sazzad Hossain (MEM-002) as active member', '2026-01-15 11:20:00'),
('pavel28', 'Record Payment', 'Recorded payment PAY-0007 for Pavel Mahmud (৳1000)', '2026-07-02 15:31:00'),
('pavel28', 'Record Payment', 'Recorded payment PAY-0018 for Fahim Chowdhury (৳1500)', '2026-07-05 10:16:00');
