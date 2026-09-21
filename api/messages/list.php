<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

require_once __DIR__ . '/../includes/db_config.php';

try {
    $user_id = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;
    $other_user_id = isset($_GET['other_user_id']) ? (int)$_GET['other_user_id'] : 0;
    
    if (empty($user_id) || empty($other_user_id)) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'User ID and Other User ID are required']);
        exit;
    }
    $limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 50;
    $offset = isset($_GET['offset']) ? (int)$_GET['offset'] : 0;
    
    // Mark messages as read
    $update = $pdo->prepare("UPDATE messages SET is_read = 1 WHERE sender_id = ? AND receiver_id = ? AND is_read = 0");
    $update->execute([$other_user_id, $user_id]);

    // Get messages
    $query = "SELECT m.*, u.name as sender_name, u.profile_picture as sender_profile_picture
              FROM messages m
              JOIN users u ON m.sender_id = u.id
              WHERE (m.sender_id = :user_id AND m.receiver_id = :other_user_id)
                 OR (m.sender_id = :other_user_id2 AND m.receiver_id = :user_id2)
              ORDER BY m.created_at DESC
              LIMIT :limit OFFSET :offset";

    $stmt = $pdo->prepare($query);
    $stmt->bindParam(":user_id", $user_id, PDO::PARAM_INT);
    $stmt->bindParam(":user_id2", $user_id, PDO::PARAM_INT);
    $stmt->bindParam(":other_user_id", $other_user_id, PDO::PARAM_INT);
    $stmt->bindParam(":other_user_id2", $other_user_id, PDO::PARAM_INT);
    $stmt->bindParam(":limit", $limit, PDO::PARAM_INT);
    $stmt->bindParam(":offset", $offset, PDO::PARAM_INT);
    $stmt->execute();

    $messages = [];
    while($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        $messages[] = [
            'id' => (int)$row['id'],
            'sender_id' => (int)$row['sender_id'],
            'receiver_id' => (int)$row['receiver_id'],
            'message' => $row['content'],
            'is_read' => (bool)$row['is_read'],
            'created_at' => $row['created_at'],
            'sender_name' => $row['sender_name'],
            'sender_profile_picture' => $row['sender_profile_picture'] ?: 'default.jpg'
        ];
    }

    $messages = array_reverse($messages);

    echo json_encode([
        'success' => true,
        'data' => $messages
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Server error: ' . $e->getMessage()]);
}
?>

