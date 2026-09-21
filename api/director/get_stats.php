<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

// Absolute path to config
require_once __DIR__ . '/../includes/db_config.php';

try {
    // Count all users
    $query = "SELECT COUNT(*) as count FROM users";
    $stmt = $pdo->prepare($query);
    $stmt->execute();
    $result = $stmt->fetch(PDO::FETCH_ASSOC);

    echo json_encode([
        'success' => true,
        'total_users' => (int)$result['count']
    ]);

} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Database error: ' . $e->getMessage()]);
}
?>
