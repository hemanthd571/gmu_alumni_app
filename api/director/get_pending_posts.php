<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

// Absolute path to config
require_once __DIR__ . '/../includes/db_config.php';

try {
    // UPDATED QUERY: Uses 'media_url' instead of 'image_path'
    $query = "
        SELECT 
            p.id, 
            p.content, 
            p.media_url as image_url, -- CORRECT COLUMN NAME
            p.created_at, 
            p.status,
            u.name as author_name,
            u.profile_picture as author_image
        FROM posts p
        JOIN users u ON p.user_id = u.id
        WHERE p.status = 'pending'
        ORDER BY p.created_at DESC
    ";

    $stmt = $pdo->prepare($query);
    $stmt->execute();
    $posts = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        'success' => true,
        'data' => $posts
    ]);

} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Database error: ' . $e->getMessage()]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Server error: ' . $e->getMessage()]);
}
?>
