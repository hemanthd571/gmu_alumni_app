<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');

require_once __DIR__ . '/../includes/db_config.php';

try {
    $stmt = $pdo->query("
        SELECT id, title, content, priority as category, created_at 
        FROM noticeboard 
        WHERE is_active = 1 
        ORDER BY publish_date DESC
    ");
    
    $notices = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        'success' => true,
        'data' => $notices
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Server error: ' . $e->getMessage()]);
}
?>

