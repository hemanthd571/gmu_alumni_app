<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

require_once __DIR__ . '/../includes/db_config.php';

try {
    $data = json_decode(file_get_contents('php://input'), true);
    $user_id = $data['user_id'] ?? null;
    $content = $data['content'] ?? '';
    $media_type = $data['media_type'] ?? 'none';
    $media_url = $data['media_url'] ?? null;
    
    if ($user_id === null || $user_id === '') {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'User ID is required']);
        exit;
    }
    
    if (empty($content) && empty($media_url)) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Post must have text or an image']);
        exit;
    }
    
    // Posts require approval from admin
    $query = "INSERT INTO posts (user_id, content, media_type, media_url, status, created_at) 
              VALUES (:user_id, :content, :media_type, :media_url, 'pending', NOW())";
    $stmt = $pdo->prepare($query);
    $stmt->execute([
        ':user_id' => $user_id,
        ':content' => $content,
        ':media_type' => $media_type,
        ':media_url' => $media_url
    ]);

    $post_id = $pdo->lastInsertId();
    
    echo json_encode([
        'success' => true,
        'message' => 'Post created successfully! It will appear after admin approval.',
        'data' => ['id' => (int)$post_id]
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Server error: ' . $e->getMessage()]);
}
?>

