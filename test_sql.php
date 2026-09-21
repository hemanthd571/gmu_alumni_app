<?php
require_once 'c:/Users/HEMANTH D/Downloads/gmu_alumni_app/gmu_alumni_app/api/includes/db_config.php';
$query = "SELECT DISTINCT
                     CASE
                       WHEN sender_id = 2 THEN receiver_id
                       ELSE sender_id
                     END as other_user_id,
                     u.name, u.profile_picture,
                     (SELECT content FROM messages WHERE (sender_id = 2 AND receiver_id = other_user_id) OR (sender_id = other_user_id AND receiver_id = 2) ORDER BY created_at DESC LIMIT 1) as last_message,
                     (SELECT created_at FROM messages WHERE (sender_id = 2 AND receiver_id = other_user_id) OR (sender_id = other_user_id AND receiver_id = 2) ORDER BY created_at DESC LIMIT 1) as last_message_time,
                     (SELECT COUNT(*) FROM messages WHERE receiver_id = 2 AND sender_id = other_user_id AND is_read = 0) as unread_count
              FROM messages m
              JOIN users u ON u.id = (
                  CASE
                    WHEN sender_id = 2 THEN receiver_id
                    ELSE sender_id
                  END
              )
              WHERE (sender_id = 2 OR receiver_id = 2)
              GROUP BY other_user_id, u.name, u.profile_picture
              ORDER BY last_message_time DESC";

$stmt = $pdo->query($query);
print_r($stmt->fetchAll(PDO::FETCH_ASSOC));
?>
