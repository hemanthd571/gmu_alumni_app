<?php
// ENABLE ERROR REPORTING
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

// Use existing db_config path
require_once __DIR__ . '/../includes/db_config.php';

try {
    // 1. Fetch data
    // Removed 'branch' alias if it doesn't exist, just select * to be safe first
    $query = "SELECT * FROM users ORDER BY created_at DESC";
    $stmt = $pdo->prepare($query);
    $stmt->execute();
    $users = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // 2. Map data to match Flutter model expectation
    $mappedUsers = [];
    foreach ($users as $user) {
        $mappedUsers[] = [
            'id' => $user['id'],
            'name' => $user['name'],
            'email' => $user['email_id'], // Map email_id -> email
            'usn' => $user['usn'] ?? '',
            'department' => $user['branch'] ?? '', // Map branch -> department
            'batch' => $user['year_of_graduation'] ?? '', // Map year -> batch
            'phone' => $user['phone_number'] ?? '',
            'profile_picture' => $user['profile_picture'] ?? null,
            'role' => $user['role'] ?? 'alumni'
        ];
    }

    echo json_encode([
        'success' => true,
        'data' => $mappedUsers
    ]);

} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Database error: ' . $e->getMessage()]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Server error: ' . $e->getMessage()]);
}
?>
