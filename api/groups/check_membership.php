<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

require_once __DIR__ . '/../includes/db_config.php';

$group_id = $_GET['group_id'] ?? null;
$user_id = $_GET['user_id'] ?? null;

if (!$group_id || !$user_id) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Group ID and User ID are required']);
    exit;
}

try {
    // Create table if it doesn't exist
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS group_members (
            id INT AUTO_INCREMENT PRIMARY KEY,
            group_id INT NOT NULL,
            user_id INT NOT NULL,
            joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (group_id) REFERENCES interest_groups(id) ON DELETE CASCADE,
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
            UNIQUE KEY unique_membership (group_id, user_id)
        )
    ");

    $stmt = $pdo->prepare("SELECT id FROM group_members WHERE group_id = ? AND user_id = ?");
    $stmt->execute([$group_id, $user_id]);
    
    $isMember = $stmt->fetch() ? true : false;

    echo json_encode([
        'success' => true,
        'is_member' => $isMember
    ]);

} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Database error: ' . $e->getMessage()
    ]);
}
?>

