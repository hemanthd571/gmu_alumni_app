<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once __DIR__ . '/../includes/db_config.php';

$input = json_decode(file_get_contents('php://input'), true);

if (
    empty($input['name']) || 
    empty($input['email']) || 
    empty($input['password']) ||
    empty($input['usn'])
) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Name, Email, Password, and USN are required']);
    exit;
}

try {
    // Check if user exists
    $stmt = $pdo->prepare("SELECT id FROM users WHERE email_id = ? OR usn = ?");
    $stmt->execute([$input['email'], $input['usn']]);
    if ($stmt->rowCount() > 0) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'User with this Email or USN already exists']);
        exit;
    }

    // Insert new user
    // Assuming 'branch' maps to department and 'year_of_graduation' maps to batch
    $sql = "INSERT INTO users (
                name, 
                email_id, 
                password, 
                usn, 
                branch, 
                year_of_graduation, 
                phone_number,
                is_active, 
                created_at
            ) VALUES (
                ?, ?, ?, ?, ?, ?, ?, 1, NOW()
            )";
            
    $stmt = $pdo->prepare($sql);
    
    $passwordHash = password_hash($input['password'], PASSWORD_DEFAULT);
    $department = $input['department'] ?? null;
    $batch = $input['batch'] ?? null;
    $phone = $input['phone'] ?? null;
    
    $result = $stmt->execute([
        $input['name'],
        $input['email'],
        $passwordHash,
        $input['usn'],
        $department,
        $batch,
        $phone
    ]);

    if ($result) {
        echo json_encode(['success' => true, 'message' => 'User created successfully']);
    } else {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Failed to create user']);
    }

} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Database error: ' . $e->getMessage()]);
}
?>
