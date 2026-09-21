-- Create jobs table for alumni app
-- Run this SQL in phpMyAdmin or MySQL Workbench

CREATE TABLE IF NOT EXISTS `jobs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) NOT NULL COMMENT 'Job title',
  `company` varchar(255) NOT NULL COMMENT 'Company name',
  `description` text NOT NULL COMMENT 'Job description',
  `requirements` text DEFAULT NULL COMMENT 'Job requirements',
  `location` varchar(255) DEFAULT NULL COMMENT 'Job location',
  `job_type` varchar(50) NOT NULL COMMENT 'Full-time, Part-time, Contract, Internship, Temporary',
  `experience_level` varchar(50) NOT NULL COMMENT 'Entry Level, Mid Level, Senior Level, Executive',
  `salary_min` decimal(10,2) DEFAULT NULL COMMENT 'Minimum salary',
  `salary_max` decimal(10,2) DEFAULT NULL COMMENT 'Maximum salary',
  `salary_range` varchar(100) DEFAULT NULL COMMENT 'Salary range text (for backward compatibility)',
  `apply_link` text DEFAULT NULL COMMENT 'Application link',
  `posted_by` int(11) NOT NULL COMMENT 'User ID who posted the job',
  `is_approved` tinyint(1) NOT NULL DEFAULT 0 COMMENT '1 = approved, 0 = pending approval',
  `is_active` tinyint(1) NOT NULL DEFAULT 1 COMMENT '1 = active, 0 = inactive/deleted',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'When the job was posted',
  PRIMARY KEY (`id`),
  KEY `posted_by` (`posted_by`),
  KEY `is_approved` (`is_approved`),
  KEY `is_active` (`is_active`),
  KEY `created_at` (`created_at`),
  KEY `job_type` (`job_type`),
  KEY `experience_level` (`experience_level`),
  CONSTRAINT `fk_jobs_posted_by` FOREIGN KEY (`posted_by`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Job postings by alumni';

-- Create indexes for faster queries
CREATE INDEX idx_active_approved_jobs ON jobs(is_active, is_approved, created_at DESC);
CREATE INDEX idx_company_jobs ON jobs(company, is_active);
CREATE INDEX idx_location_jobs ON jobs(location, is_active);

-- Optional: Add some sample data (uncomment if needed)
-- INSERT INTO jobs (title, company, description, requirements, location, job_type, experience_level, salary_max, apply_link, posted_by, is_approved) VALUES 
-- ('Software Developer', 'Tech Corp', 'Looking for experienced software developer', '3+ years experience, React, Node.js', 'Remote', 'Full-time', 'Mid Level', 80000.00, 'https://techcorp.com/apply', 1, 1),
-- ('Data Analyst Intern', 'Analytics Inc', 'Internship for data analysis', 'SQL, Python, Excel', 'New York', 'Internship', 'Entry Level', 25000.00, 'https://analyticsinc.com/careers', 1, 1);
