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

$input = json_decode(file_get_contents('php://input'), true);

if (empty($input['post_id']) || empty($input['action'])) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Post ID and Action required']);
    exit;
}

$postId = $input['post_id'];
$action = strtolower($input['action']); // 'approve' or 'reject'

// Determine new status
$newStatus = '';
if ($action === 'approve') {
    $newStatus = 'approved';
} elseif ($action === 'reject') {
    $newStatus = 'rejected';
} else {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Invalid action']);
    exit;
}

try {
    $stmt = $pdo->prepare("UPDATE posts SET status = ? WHERE id = ?");
    $result = $stmt->execute([$newStatus, $postId]);

    if ($result) {
        echo json_encode([
            'success' => true, 
            'message' => "Post $newStatus successfully"
        ]);
    } else {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Failed to update post status']);
    }

} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Database error: ' . $e->getMessage()]);
}
?>
