<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

require_once __DIR__ . '/../includes/db_config.php';

try {
    $data = json_decode(file_get_contents('php://input'), true);
    $user_id = $data['user_id'] ?? 0;
    $post_id = $data['post_id'] ?? 0;
    
    if (empty($user_id) || empty($post_id)) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'User ID and Post ID are required']);
        exit;
    }
    
    // Check if already liked
    $check = $pdo->prepare("SELECT id FROM post_likes WHERE user_id = ? AND post_id = ?");
    $check->execute([$user_id, $post_id]);
    
    if ($check->rowCount() > 0) {
        // Unlike
        $stmt = $pdo->prepare("DELETE FROM post_likes WHERE user_id = ? AND post_id = ?");
        $stmt->execute([$user_id, $post_id]);
        $action = 'unliked';
    } else {
        // Like
        $stmt = $pdo->prepare("INSERT INTO post_likes (user_id, post_id, created_at) VALUES (?, ?, NOW())");
        $stmt->execute([$user_id, $post_id]);
        $action = 'liked';
    }
    
    echo json_encode([
        'success' => true,
        'message' => 'Post ' . $action,
        'action' => $action
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Server error: ' . $e->getMessage()]);
}
?>

