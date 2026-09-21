<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once __DIR__ . '/../includes/db_config.php';

try {
    $department = isset($_GET['department']) ? $_GET['department'] : null;

    if ($department) {
        $stmt = $pdo->prepare("SELECT id, name, email_id as email, usn, branch as department, year_of_graduation as batch, phone_number as phone, created_at FROM users WHERE is_active = 0 AND branch = ? ORDER BY created_at DESC");
        $stmt->execute([$department]);
    } else {
        $stmt = $pdo->prepare("SELECT id, name, email_id as email, usn, branch as department, year_of_graduation as batch, phone_number as phone, created_at FROM users WHERE is_active = 0 ORDER BY created_at DESC");
        $stmt->execute();
    }

    $users = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        'success' => true,
        'data' => $users
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Database error: ' . $e->getMessage()]);
}
?>
