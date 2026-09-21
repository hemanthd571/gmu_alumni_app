<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once __DIR__ . '/../includes/db_config.php';

$input = file_get_contents('php://input');
$data = json_decode($input, true);

if (empty($data['user_id'])) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'User ID is required']);
    exit;
}

try {
    // Only delete if the user is not active yet (safety check)
    $stmt = $pdo->prepare("DELETE FROM users WHERE id = ? AND is_active = 0");
    $stmt->execute([$data['user_id']]);

    if ($stmt->rowCount() > 0) {
        echo json_encode(['success' => true, 'message' => 'User registration rejected and deleted']);
    } else {
        echo json_encode(['success' => false, 'message' => 'User not found or is already active']);
    }
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Database error: ' . $e->getMessage()]);
}
?>
