<?php
require_once __DIR__ . '/../includes/db_config.php';

// Enable error reporting
error_reporting(E_ALL);
ini_set('display_errors', 1);

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

try {
    $data = json_decode(file_get_contents("php://input"), true);
    
    if (!isset($data['user_id'])) {
        echo json_encode(['success' => false, 'message' => 'User ID is required']);
        exit;
    }

    $userId = $data['user_id'];
    $name = $data['name'] ?? '';
    $email = $data['email'] ?? '';
    $usn = $data['usn'] ?? '';
    $department = $data['department'] ?? '';
    $batch = $data['batch'] ?? '';
    $phone = $data['phone'] ?? '';
    $branch = $department; // using department for branch as well based on UI

    $query = "UPDATE users SET 
                name = :name,
                email_id = :email,
                usn = :usn,
                branch = :branch,
                year_of_graduation = :batch,
                phone_number = :phone
              WHERE id = :id";
              
    $stmt = $pdo->prepare($query);
    $result = $stmt->execute([
        ':name' => $name,
        ':email' => $email,
        ':usn' => $usn,
        ':branch' => $branch,
        ':batch' => $batch,
        ':phone' => $phone,
        ':id' => $userId
    ]);

    if ($result) {
        echo json_encode(['success' => true, 'message' => 'User updated successfully']);
    } else {
        echo json_encode(['success' => false, 'message' => 'Failed to update user']);
    }
} catch (PDOException $e) {
    echo json_encode([
        'success' => false, 
        'message' => 'Database error: ' . $e->getMessage()
    ]);
}
?>
