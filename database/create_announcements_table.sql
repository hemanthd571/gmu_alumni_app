-- Create announcements table for alumni app
-- Run this SQL in phpMyAdmin or MySQL Workbench

CREATE TABLE IF NOT EXISTS `announcements` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `director_id` int(11) NOT NULL COMMENT 'ID of the director who created the announcement',
  `title` varchar(255) NOT NULL COMMENT 'Announcement title',
  `content` text NOT NULL COMMENT 'Announcement content/description',
  `is_active` tinyint(1) NOT NULL DEFAULT 1 COMMENT '1 = active, 0 = inactive',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'When the announcement was created',
  PRIMARY KEY (`id`),
  KEY `director_id` (`director_id`),
  KEY `is_active` (`is_active`),
  KEY `created_at` (`created_at`),
  CONSTRAINT `fk_announcements_director` FOREIGN KEY (`director_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Stores announcements made by directors';

-- Create index for faster queries
CREATE INDEX idx_active_announcements ON announcements(is_active, created_at DESC);

-- Optional: Add some sample data (uncomment if needed)
-- INSERT INTO announcements (director_id, title, content) VALUES 
-- (1, 'Welcome to GMU Alumni Network', 'We are excited to launch our new alumni platform!'),
-- (1, 'Annual Alumni Meetup 2024', 'Join us for our annual alumni meetup on December 15th, 2024.');
