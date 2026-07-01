DROP TABLE IF EXISTS `project_workflow_mapping`, `workflow_status_transitions`, `workflows`, `issue_sprint_mapping`, `sprints`, `attachments`, `comments`, `issues`, `issue_statuses`, `issue_types`, `projects`, `users`;

--
-- Users Table: Stores information about users
--
CREATE TABLE `users` (
  `user_id` INT AUTO_INCREMENT PRIMARY KEY,
  `username` VARCHAR(255) NOT NULL UNIQUE,
  `password_hash` VARCHAR(255) NOT NULL,
  `email` VARCHAR(255) NOT NULL UNIQUE,
  `full_name` VARCHAR(255) DEFAULT NULL,
  `avatar_url` VARCHAR(255) DEFAULT NULL,
  `role` ENUM('admin', 'user') NOT NULL DEFAULT 'user',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

--
-- Projects Table: Stores information about projects
--
CREATE TABLE `projects` (
  `project_id` INT AUTO_INCREMENT PRIMARY KEY,
  `project_key` VARCHAR(10) NOT NULL UNIQUE,
  `project_name` VARCHAR(255) NOT NULL,
  `description` TEXT DEFAULT NULL,
  `lead_user_id` INT,
  `start_date` DATE DEFAULT NULL,
  `end_date` DATE DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (`lead_user_id`) REFERENCES `users`(`user_id`) ON DELETE SET NULL
);

--
-- Issue Types Table
--
CREATE TABLE `issue_types` (
  `issue_type_id` INT AUTO_INCREMENT PRIMARY KEY,
  `type_name` VARCHAR(50) NOT NULL UNIQUE,
  `icon_url` VARCHAR(255) DEFAULT NULL
);

--
-- Issue Statuses Table
--
CREATE TABLE `issue_statuses` (
  `status_id` INT AUTO_INCREMENT PRIMARY KEY,
  `status_name` VARCHAR(50) NOT NULL UNIQUE,
  `status_order` INT DEFAULT 0
);

--
-- Issues (Tasks) Table
--
CREATE TABLE `issues` (
  `issue_id` INT AUTO_INCREMENT PRIMARY KEY,
  `project_id` INT NOT NULL,
  `issue_key` VARCHAR(20) NOT NULL UNIQUE,
  `summary` VARCHAR(255) NOT NULL,
  `description` TEXT DEFAULT NULL,
  `issue_type_id` INT NOT NULL,
  `status_id` INT NOT NULL,
  `reporter_id` INT NOT NULL,
  `assignee_id` INT DEFAULT NULL,
  `priority` ENUM('Low', 'Medium', 'High') DEFAULT 'Medium',
  `due_date` DATE DEFAULT NULL,
  `story_points` INT DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (`project_id`) REFERENCES `projects`(`project_id`) ON DELETE CASCADE,
  FOREIGN KEY (`issue_type_id`) REFERENCES `issue_types`(`issue_type_id`),
  FOREIGN KEY (`status_id`) REFERENCES `issue_statuses`(`status_id`),
  FOREIGN KEY (`reporter_id`) REFERENCES `users`(`user_id`),
  FOREIGN KEY (`assignee_id`) REFERENCES `users`(`user_id`) ON DELETE SET NULL
);

--
-- Comments Table
--
CREATE TABLE `comments` (
  `comment_id` INT AUTO_INCREMENT PRIMARY KEY,
  `issue_id` INT NOT NULL,
  `user_id` INT NOT NULL,
  `comment_text` TEXT NOT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (`issue_id`) REFERENCES `issues`(`issue_id`) ON DELETE CASCADE,
  FOREIGN KEY (`user_id`) REFERENCES `users`(`user_id`) ON DELETE CASCADE
);

--
-- Attachments Table
--
CREATE TABLE `attachments` (
  `attachment_id` INT AUTO_INCREMENT PRIMARY KEY,
  `issue_id` INT NOT NULL,
  `uploader_user_id` INT NOT NULL,
  `file_name` VARCHAR(255) NOT NULL,
  `file_path` VARCHAR(255) NOT NULL,
  `file_type` VARCHAR(100) DEFAULT NULL,
  `file_size_bytes` INT DEFAULT NULL,
  `uploaded_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (`issue_id`) REFERENCES `issues`(`issue_id`) ON DELETE CASCADE,
  FOREIGN KEY (`uploader_user_id`) REFERENCES `users`(`user_id`)
);

--
-- Seed Data
--

-- Insert Users with properly hashed passwords
-- Admin passwords: AdminFlow#2025!
-- User passwords: UserPass@ProJ789
INSERT INTO `users` (`user_id`, `username`, `password_hash`, `email`, `full_name`, `avatar_url`, `role`) VALUES
(1, 'asri.azraff', '$2a$10$wI/hSDRL.0qY9gZ0g0iQ5e.o/uJ.K6L4g.P7h.I8j.L9k.M0n.O1p', 'asri.azraff@example.com', 'Asri Azraff', 'https://placehold.co/128x128/E0E7FF/4F46E5?text=AA', 'admin'),
(2, 'siti.nurhaliza', '$2a$10$Vx/Wq1K57q1L2YFbAbugYu4ADdoHbHHGVJZ.67WoQZgXm1fJ6KRPy', 'siti.nurhaliza@example.com', 'Siti Nurhaliza', 'https://placehold.co/128x128/FFBFBF/B91C1C?text=SN', 'user'),
(3, 'ahmad.ismail', '$2a$10$Vx/Wq1K57q1L2YFbAbugYu4ADdoHbHHGVJZ.67WoQZgXm1fJ6KRPy', 'ahmad.ismail@example.com', 'Ahmad bin Ismail', 'https://placehold.co/128x128/BFD7FF/1E3A8A?text=AI', 'user'),
(4, 'fatimah.kassim', '$2a$10$Vx/Wq1K57q1L2YFbAbugYu4ADdoHbHHGVJZ.67WoQZgXm1fJ6KRPy', 'fatimah.kassim@example.com', 'Fatimah binti Kassim', 'https://placehold.co/128x128/A7F3D0/047857?text=FK', 'user'),
(5, 'muhammadasri', '$2a$10$wI/hSDRL.0qY9gZ0g0iQ5e.o/uJ.K6L4g.P7h.I8j.L9k.M0n.O1p', 'muhammad.asri@example.com', 'Muhammad Asri', 'https://placehold.co/128x128/C4B5FD/4338CA?text=MA', 'admin'),
(6, 'nurul.aina', '$2a$10$Vx/Wq1K57q1L2YFbAbugYu4ADdoHbHHGVJZ.67WoQZgXm1fJ6KRPy', 'nurul.aina@example.com', 'Nurul Aina', 'https://placehold.co/128x128/FED7D7/991B1B?text=NA', 'user'),
(7, 'hassan.omar', '$2a$10$Vx/Wq1K57q1L2YFbAbugYu4ADdoHbHHGVJZ.67WoQZgXm1fJ6KRPy', 'hassan.omar@example.com', 'Hassan Omar', 'https://placehold.co/128x128/D1FAE5/065F46?text=HO', 'user'),
(8, 'liyana.abdul', '$2a$10$Vx/Wq1K57q1L2YFbAbugYu4ADdoHbHHGVJZ.67WoQZgXm1fJ6KRPy', 'liyana.abdul@example.com', 'Liyana Abdul Rahman', 'https://placehold.co/128x128/E0E7FF/3730A3?text=LA', 'user'),
(9, 'zaki.ibrahim', '$2a$10$Vx/Wq1K57q1L2YFbAbugYu4ADdoHbHHGVJZ.67WoQZgXm1fJ6KRPy', 'zaki.ibrahim@example.com', 'Zaki Ibrahim', 'https://placehold.co/128x128/FEF3C7/92400E?text=ZI', 'user'),
(10, 'sara.mohamed', '$2a$10$Vx/Wq1K57q1L2YFbAbugYu4ADdoHbHHGVJZ.67WoQZgXm1fJ6KRPy', 'sara.mohamed@example.com', 'Sara Mohamed', 'https://placehold.co/128x128/F3E8FF/6B21A8?text=SM', 'user'),
(11, 'farid.hamid', '$2a$10$Vx/Wq1K57q1L2YFbAbugYu4ADdoHbHHGVJZ.67WoQZgXm1fJ6KRPy', 'farid.hamid@example.com', 'Farid Hamid', 'https://placehold.co/128x128/DBEAFE/3730A3?text=FH', 'user'),
(12, 'amira.hassan', '$2a$10$Vx/Wq1K57q1L2YFbAbugYu4ADdoHbHHGVJZ.67WoQZgXm1fJ6KRPy', 'amira.hassan@example.com', 'Amira Hassan', 'https://placehold.co/128x128/FCE7F3/BE185D?text=AH', 'user');

-- Insert Projects with realistic descriptions and dates
INSERT INTO `projects` (`project_id`, `project_key`, `project_name`, `description`, `lead_user_id`, `start_date`, `end_date`) VALUES
(1, 'PROJ-A', 'Alpha E-Commerce Platform', 'Development of a comprehensive e-commerce platform with modern UI/UX, payment integration, and inventory management. This project aims to create a scalable solution for online retail businesses.', 2, '2025-01-15', '2025-08-30'),
(2, 'PROJ-B', 'Beta Mobile Application', 'Cross-platform mobile application for customer engagement and loyalty program. Features include push notifications, in-app purchases, and social media integration.', 3, '2025-02-01', '2025-07-15'),
(3, 'GAMMA', 'Gamma Analytics Dashboard', 'Internal analytics dashboard for real-time business intelligence and reporting. Includes data visualization, automated reports, and KPI tracking.', 1, '2025-01-01', '2025-06-30'),
(4, 'DELTA', 'Delta API Gateway', 'Microservices API gateway with authentication, rate limiting, and monitoring capabilities. Designed to handle high-throughput enterprise applications.', 5, '2025-03-01', '2025-10-31'),
(5, 'EPSILON', 'Epsilon HR Management System', 'Complete human resources management system with employee onboarding, payroll integration, and performance tracking modules.', 7, '2025-02-15', '2025-09-30'),
(6, 'ZETA', 'Zeta IoT Platform', 'Internet of Things platform for device management, data collection, and real-time monitoring with cloud-based architecture.', 8, '2025-04-01', '2025-12-31');

-- Insert Issue Types
INSERT INTO `issue_types` (`issue_type_id`, `type_name`) VALUES 
(1, 'Bug'), 
(2, 'Task'), 
(3, 'Story'), 
(4, 'Epic'),
(5, 'Improvement'),
(6, 'Feature');

-- Insert Issue Statuses
INSERT INTO `issue_statuses` (`status_id`, `status_name`, `status_order`) VALUES 
(1, 'To Do', 1), 
(2, 'In Progress', 2), 
(3, 'In Review', 3), 
(4, 'Done', 4);

-- Insert Issues Data
INSERT INTO `issues` (`issue_id`, `project_id`, `issue_key`, `summary`, `description`, `issue_type_id`, `status_id`, `reporter_id`, `assignee_id`, `priority`, `due_date`, `story_points`) VALUES
-- Alpha E-Commerce Platform Issues
(1, 1, 'PROJ-A-001', 'Set up development environment', 'Configure development tools, IDE settings, and project structure for the e-commerce platform.', 2, 4, 1, 2, 'Medium', '2025-01-20', 3),
(2, 1, 'PROJ-A-002', 'Design user authentication system', 'Create comprehensive user authentication with OAuth integration, password reset, and email verification.', 3, 3, 2, 3, 'High', '2025-02-05', 8),
(3, 1, 'PROJ-A-003', 'Implement product catalog', 'Build product listing, search functionality, and category management with filtering options.', 3, 2, 1, 2, 'High', '2025-02-15', 13),
(4, 1, 'PROJ-A-004', 'Shopping cart functionality', 'Develop shopping cart with add/remove items, quantity updates, and persistent storage.', 3, 1, 2, 4, 'Medium', '2025-02-28', 8),
(5, 1, 'PROJ-A-005', 'Payment gateway integration', 'Integrate multiple payment methods including credit cards, PayPal, and digital wallets.', 3, 1, 1, 6, 'High', '2025-03-10', 13),
(6, 1, 'PROJ-A-006', 'Fix login redirect issue', 'Users are not being redirected properly after successful login, causing confusion.', 1, 2, 3, 2, 'High', '2025-02-10', NULL),
(7, 1, 'PROJ-A-007', 'Admin dashboard development', 'Create comprehensive admin panel for order management, user administration, and analytics.', 4, 1, 1, NULL, 'Medium', '2025-04-01', 21),
(8, 1, 'PROJ-A-008', 'Mobile responsive design', 'Ensure all pages are fully responsive and optimized for mobile devices.', 5, 1, 2, 8, 'Medium', '2025-03-20', 8),

-- Beta Mobile Application Issues  
(9, 2, 'PROJ-B-001', 'Mobile app architecture setup', 'Define React Native project structure and configure build tools for iOS and Android.', 2, 4, 3, 9, 'High', '2025-02-05', 5),
(10, 2, 'PROJ-B-002', 'User onboarding flow', 'Create intuitive onboarding experience with app introduction and feature highlights.', 3, 3, 3, 10, 'Medium', '2025-02-20', 5),
(11, 2, 'PROJ-B-003', 'Push notifications system', 'Implement Firebase push notifications for customer engagement and promotions.', 6, 2, 7, 9, 'High', '2025-03-01', 8),
(12, 2, 'PROJ-B-004', 'Loyalty program integration', 'Connect with existing loyalty program API and display points, rewards, and redemption options.', 3, 1, 3, 11, 'Medium', '2025-03-15', 8),
(13, 2, 'PROJ-B-005', 'Social media sharing', 'Add social sharing capabilities for products and achievements within the app.', 6, 1, 10, 12, 'Low', '2025-04-01', 3),
(14, 2, 'PROJ-B-006', 'App crashes on iOS 14', 'Application crashes consistently on iOS 14.6 when accessing profile section.', 1, 2, 9, 10, 'High', '2025-02-25', NULL),

-- Gamma Analytics Dashboard Issues
(15, 3, 'GAMMA-001', 'Data visualization components', 'Build reusable chart components using D3.js for various data visualization needs.', 2, 4, 1, 4, 'High', '2025-01-25', 13),
(16, 3, 'GAMMA-002', 'Real-time data streaming', 'Implement WebSocket connections for real-time dashboard updates and live data feeds.', 6, 2, 1, 7, 'High', '2025-02-10', 13),
(17, 3, 'GAMMA-003', 'Custom report builder', 'Create drag-and-drop report builder allowing users to create custom analytics reports.', 4, 1, 5, 4, 'Medium', '2025-03-30', 21),
(18, 3, 'GAMMA-004', 'Export functionality', 'Add PDF and Excel export options for dashboards and reports with custom formatting.', 5, 1, 1, 8, 'Low', '2025-03-15', 5),
(19, 3, 'GAMMA-005', 'User permission system', 'Implement role-based access control for different dashboard sections and data sensitivity.', 3, 2, 5, 6, 'Medium', '2025-02-28', 8),

-- Delta API Gateway Issues
(20, 4, 'DELTA-001', 'API authentication middleware', 'Develop JWT-based authentication middleware with token refresh and validation.', 2, 1, 5, 11, 'High', '2025-03-20', 8),
(21, 4, 'DELTA-002', 'Rate limiting implementation', 'Create configurable rate limiting system to prevent API abuse and ensure fair usage.', 6, 1, 5, 12, 'Medium', '2025-04-05', 5),
(22, 4, 'DELTA-003', 'API documentation portal', 'Build interactive API documentation with testing capabilities and code examples.', 2, 1, 1, 7, 'Medium', '2025-04-15', 8),
(23, 4, 'DELTA-004', 'Monitoring and logging', 'Implement comprehensive logging and monitoring with alerts for API performance metrics.', 6, 1, 5, NULL, 'High', '2025-04-30', 13),

-- Epsilon HR Management Issues
(24, 5, 'EPSILON-001', 'Employee database schema', 'Design and implement database schema for employee records, departments, and positions.', 2, 4, 7, 9, 'High', '2025-02-25', 8),
(25, 5, 'EPSILON-002', 'Payroll calculation engine', 'Build automated payroll calculation system with tax deductions and benefit calculations.', 6, 2, 7, 10, 'High', '2025-03-20', 21),
(26, 5, 'EPSILON-003', 'Leave management system', 'Create leave request workflow with approval process and calendar integration.', 3, 1, 11, 11, 'Medium', '2025-04-10', 13),
(27, 5, 'EPSILON-004', 'Performance review module', 'Develop performance review system with goal setting and feedback collection.', 3, 1, 7, 12, 'Medium', '2025-05-01', 13),

-- Zeta IoT Platform Issues
(28, 6, 'ZETA-001', 'Device registration system', 'Create system for IoT device registration, authentication, and management.', 6, 1, 8, 2, 'High', '2025-04-20', 13),
(29, 6, 'ZETA-002', 'Real-time data collection', 'Implement MQTT broker for real-time IoT data collection and processing.', 6, 1, 8, 3, 'High', '2025-05-10', 21),
(30, 6, 'ZETA-003', 'Device monitoring dashboard', 'Build dashboard for monitoring device status, health, and performance metrics.', 3, 1, 1, 4, 'Medium', '2025-06-01', 13);

-- Insert Comments
INSERT INTO `comments` (`issue_id`, `user_id`, `comment_text`, `created_at`) VALUES
-- Comments for PROJ-A-002 (Design user authentication system)
(2, 2, 'I have started working on the OAuth integration. Planning to support Google and Facebook login initially.', '2025-01-28 09:15:00'),
(2, 1, 'Great! Make sure to include proper error handling for network failures during OAuth flow.', '2025-01-28 10:30:00'),
(2, 3, 'Should we also consider implementing two-factor authentication for enhanced security?', '2025-01-29 14:20:00'),
(2, 2, 'Good point! I will add 2FA as a separate task since it will require additional UI components.', '2025-01-29 15:45:00'),

-- Comments for PROJ-A-003 (Implement product catalog)
(3, 1, 'The initial wireframes look good. Please ensure the search functionality includes autocomplete suggestions.', '2025-02-01 11:00:00'),
(3, 2, 'Working on the database schema for product categories. Should we support nested categories?', '2025-02-02 13:30:00'),
(3, 4, 'Yes, nested categories would be beneficial for better organization. Consider using adjacency list model.', '2025-02-02 16:15:00'),

-- Comments for PROJ-A-006 (Fix login redirect issue)
(6, 3, 'I can reproduce this issue consistently. It seems to be related to session storage in private browsing mode.', '2025-02-08 10:00:00'),
(6, 2, 'Thanks for the debugging info. I will investigate the session handling logic.', '2025-02-08 11:30:00'),
(6, 2, 'Found the issue! The redirect URL was not being properly encoded. Fix will be ready by EOD.', '2025-02-09 14:45:00'),

-- Comments for PROJ-B-004 (Loyalty program integration)
(12, 3, 'The loyalty program API documentation is available. I will share the endpoint details.', '2025-02-28 09:00:00'),
(12, 11, 'Received the API docs. The integration looks straightforward. Starting development today.', '2025-02-28 10:15:00'),
(12, 10, 'Please ensure we handle cases where users do not have loyalty accounts yet.', '2025-03-01 08:30:00'),

-- Comments for PROJ-B-006 (App crashes on iOS 14)
(14, 9, 'This is a critical issue affecting about 15% of our iOS users. High priority fix needed.', '2025-02-23 16:00:00'),
(14, 10, 'Investigating the crash logs now. Seems to be related to memory management in the profile image loading.', '2025-02-24 09:30:00'),
(14, 10, 'Fixed the memory leak issue. Testing on multiple iOS 14 devices before releasing the patch.', '2025-02-25 11:15:00'),

-- Comments for GAMMA-002 (Real-time data streaming)  
(16, 1, 'Consider using Server-Sent Events as a fallback for environments where WebSockets are not supported.', '2025-02-08 13:00:00'),
(16, 7, 'Good suggestion! I will implement both WebSocket and SSE with automatic fallback detection.', '2025-02-08 14:30:00'),
(16, 4, 'Make sure to handle connection drops gracefully and implement automatic reconnection logic.', '2025-02-09 10:00:00'),

-- Comments for GAMMA-005 (User permission system)
(19, 5, 'The role definitions document is ready for review. Please check if we covered all use cases.', '2025-02-25 11:00:00'),
(19, 6, 'Reviewed the roles. We might need a custom role builder for enterprise clients.', '2025-02-25 15:30:00'),
(19, 1, 'Let us start with predefined roles and add custom roles in phase 2 if there is demand.', '2025-02-26 09:15:00'),

-- Comments for EPSILON-002 (Payroll calculation engine)
(25, 7, 'The tax calculation logic is complex due to different state regulations. May need additional time.', '2025-03-15 10:00:00'),
(25, 10, 'I can help with the tax calculations. I have experience with payroll systems from my previous company.', '2025-03-15 11:30:00'),
(25, 9, 'Great teamwork! Please document the tax calculation formulas for future maintenance.', '2025-03-15 14:00:00'),

-- Comments for ZETA-001 (Device registration system)
(28, 8, 'Starting with device registration API. Planning to use device certificates for authentication.', '2025-04-15 09:00:00'),
(28, 2, 'Make sure to include device metadata like firmware version and hardware specs in registration.', '2025-04-15 10:30:00'),
(28, 1, 'Consider implementing device provisioning workflows for bulk device setup in enterprise scenarios.', '2025-04-16 08:45:00');

-- Insert Sample Attachments
INSERT INTO `attachments` (`issue_id`, `uploader_user_id`, `file_name`, `file_path`, `file_type`, `file_size_bytes`) VALUES
(2, 2, 'oauth_integration_diagram.png', '/attachments/oauth_integration_diagram.png', 'image/png', 245760),
(2, 1, 'authentication_requirements.pdf', '/attachments/authentication_requirements.pdf', 'application/pdf', 524288),
(3, 2, 'product_catalog_wireframes.pdf', '/attachments/product_catalog_wireframes.pdf', 'application/pdf', 1048576),
(3, 4, 'database_schema_design.sql', '/attachments/database_schema_design.sql', 'text/sql', 8192),
(10, 3, 'onboarding_mockups.zip', '/attachments/onboarding_mockups.zip', 'application/zip', 2097152),
(15, 1, 'chart_components_specs.docx', '/attachments/chart_components_specs.docx', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', 65536),
(16, 7, 'websocket_architecture.png', '/attachments/websocket_architecture.png', 'image/png', 131072),
(19, 5, 'role_definitions.xlsx', '/attachments/role_definitions.xlsx', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', 32768),
(24, 7, 'hr_database_erd.pdf', '/attachments/hr_database_erd.pdf', 'application/pdf', 409600),
(28, 8, 'iot_device_specs.json', '/attachments/iot_device_specs.json', 'application/json', 4096);

-- Update timestamps to make data more realistic
UPDATE `issues` SET `created_at` = DATE_SUB(NOW(), INTERVAL FLOOR(RAND() * 30) DAY);
UPDATE `issues` SET `updated_at` = DATE_ADD(`created_at`, INTERVAL FLOOR(RAND() * 10) DAY);
UPDATE `projects` SET `created_at` = DATE_SUB(NOW(), INTERVAL FLOOR(RAND() * 60) DAY);
UPDATE `projects` SET `updated_at` = DATE_ADD(`created_at`, INTERVAL FLOOR(RAND() * 20) DAY);

-- Add some additional sample users for testing registration
INSERT INTO `users` (`username`, `password_hash`, `email`, `full_name`, `avatar_url`, `role`) VALUES
('testuser1', '$2a$10$Vx/Wq1K57q1L2YFbAbugYu4ADdoHbHHGVJZ.67WoQZgXm1fJ6KRPy', 'testuser1@example.com', 'Test User One', 'https://placehold.co/128x128/F59E0B/FFFFFF?text=T1', 'user'),
('testuser2', '$2a$10$Vx/Wq1K57q1L2YFbAbugYu4ADdoHbHHGVJZ.67WoQZgXm1fJ6KRPy', 'testuser2@example.com', 'Test User Two', 'https://placehold.co/128x128/10B981/FFFFFF?text=T2', 'user');

-- Performance optimization indexes
CREATE INDEX idx_issues_project_id ON issues(project_id);
CREATE INDEX idx_issues_assignee_id ON issues(assignee_id);
CREATE INDEX idx_issues_status_id ON issues(status_id);
CREATE INDEX idx_comments_issue_id ON comments(issue_id);
CREATE INDEX idx_comments_user_id ON comments(user_id);

COMMIT;