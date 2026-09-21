<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

require_once __DIR__ . '/../includes/db_config.php';

try {
    $user_id = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;
    
    if (empty($user_id)) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'User ID is required']);
        exit;
    }
    
    $query = "SELECT DISTINCT
                     CASE
                       WHEN sender_id = :user_id THEN receiver_id
                       ELSE sender_id
                     END as other_user_id,
                     u.name, u.profile_picture,
                     (SELECT content FROM messages WHERE (sender_id = :user_id2 AND receiver_id = other_user_id) OR (sender_id = other_user_id AND receiver_id = :user_id3) ORDER BY created_at DESC LIMIT 1) as last_message,
                     (SELECT created_at FROM messages WHERE (sender_id = :user_id4 AND receiver_id = other_user_id) OR (sender_id = other_user_id AND receiver_id = :user_id5) ORDER BY created_at DESC LIMIT 1) as last_message_time,
                     (SELECT COUNT(*) FROM messages WHERE receiver_id = :user_id6 AND sender_id = other_user_id AND is_read = 0) as unread_count
              FROM messages m
              JOIN users u ON u.id = (
                  CASE
                    WHEN sender_id = :user_id7 THEN receiver_id
                    ELSE sender_id
                  END
              )
              WHERE (sender_id = :user_id8 OR receiver_id = :user_id9)
              GROUP BY other_user_id, u.name, u.profile_picture
              ORDER BY last_message_time DESC";

    $stmt = $pdo->prepare($query);
    $stmt->execute([
        ':user_id' => $user_id,
        ':user_id2' => $user_id,
        ':user_id3' => $user_id,
        ':user_id4' => $user_id,
        ':user_id5' => $user_id,
        ':user_id6' => $user_id,
        ':user_id7' => $user_id,
        ':user_id8' => $user_id,
        ':user_id9' => $user_id
    ]);

    $conversations = [];
    while($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        $conversations[] = [
            'user_id' => (int)$row['other_user_id'],
            'name' => $row['name'],
            'profile_picture' => $row['profile_picture'] ?: 'default.jpg',
            'last_message' => $row['last_message'] ?: '',
            'last_message_time' => $row['last_message_time'],
            'unread_count' => (int)$row['unread_count']
        ];
    }

    echo json_encode([
        'success' => true,
        'data' => $conversations
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Server error: ' . $e->getMessage()]);
}
?>

