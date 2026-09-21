<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');

require_once __DIR__ . '/../includes/db_config.php';

try {
    // Check what columns exist
    $columns = $pdo->query("SHOW COLUMNS FROM events")->fetchAll(PDO::FETCH_COLUMN);
    
    $imageColumn = in_array('featured_image', $columns) ? 'featured_image' : 
                   (in_array('image', $columns) ? 'image' : 'NULL');
    
    $stmt = $pdo->query("
        SELECT id, title, description, location, $imageColumn as image, event_date, created_at 
        FROM events 
        WHERE is_active = 1 
        ORDER BY event_date DESC
    ");
    
    $events = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        'success' => true,
        'data' => $events
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Server error: ' . $e->getMessage()]);
}
?>

