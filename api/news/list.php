<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');

require_once __DIR__ . '/../includes/db_config.php';

try {
    // First, check what columns exist
    $columns = $pdo->query("SHOW COLUMNS FROM news")->fetchAll(PDO::FETCH_COLUMN);
    
    // Build query based on available columns
    $imageColumn = in_array('featured_image', $columns) ? 'featured_image' : 
                   (in_array('image', $columns) ? 'image' : 'NULL');
    
    $stmt = $pdo->query("
        SELECT id, title, content, $imageColumn as image, created_at 
        FROM news 
        WHERE is_active = 1 
        ORDER BY publish_date DESC
    ");
    
    $news = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        'success' => true,
        'data' => $news
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Server error: ' . $e->getMessage()]);
}
?>

