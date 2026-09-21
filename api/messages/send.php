<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

require_once __DIR__ . '/../includes/db_config.php';

try {
    $data = json_decode(file_get_contents('php://input'), true);
    $sender_id = $data['sender_id'] ?? 0;
    $receiver_id = $data['receiver_id'] ?? 0;
    $message = $data['message'] ?? '';
    
    if (empty($sender_id) || empty($receiver_id)) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Sender ID and Receiver ID are required']);
        exit;
    }
    
    if (empty($message)) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Message is required']);
        exit;
    }
    
    $query = "INSERT INTO messages (sender_id, receiver_id, content, created_at) VALUES (?, ?, ?, NOW())";
    $stmt = $pdo->prepare($query);
    $stmt->execute([$sender_id, $receiver_id, $message]);

    echo json_encode([
        'success' => true,
        'message' => 'Message sent successfully',
        'data' => ['id' => (int)$pdo->lastInsertId()]
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Server error: ' . $e->getMessage()]);
}
?>

