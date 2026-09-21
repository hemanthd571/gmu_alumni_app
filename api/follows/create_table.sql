-- Create follows table for alumni follow feature
-- Run this SQL in phpMyAdmin or MySQL Workbench

CREATE TABLE IF NOT EXISTS `follows` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `follower_id` int(11) NOT NULL COMMENT 'User who is following',
  `following_id` int(11) NOT NULL COMMENT 'User being followed',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_follow` (`follower_id`, `following_id`),
  KEY `follower_id` (`follower_id`),
  KEY `following_id` (`following_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Stores user follow relationships';

-- Optional: Add some test data (uncomment if needed)
-- INSERT INTO follows (follower_id, following_id) VALUES (19, 18);
-- INSERT INTO follows (follower_id, following_id) VALUES (19, 21);
