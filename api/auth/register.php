<?php
// Add these at the very top for debugging
error_reporting(E_ALL);
ini_set('display_errors', 1);
ini_set('log_errors', 1);
ini_set('error_log', '/var/log/php_errors.log');

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// Wrap everything in try-catch to catch all errors
try {
    require_once __DIR__ . '/../includes/db_config.php';

    // Check if PDO connection exists
    if (!isset($pdo)) {
        throw new Exception('PDO connection not established');
    }

    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        http_response_code(405);
        echo json_encode(['success' => false, 'message' => 'Method not allowed']);
        exit;
    }

    $input = file_get_contents('php://input');
    $data = json_decode($input, true);

    if (json_last_error() !== JSON_ERROR_NONE) {
        throw new Exception('Invalid JSON: ' . json_last_error_msg());
    }

    if (
        empty($data['name']) || 
        empty($data['email']) || 
        empty($data['password']) ||
        empty($data['usn'])
    ) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Missing required fields (name, email, password, usn)']);
        exit;
    }

    // Check existing user
    $stmt = $pdo->prepare("SELECT id FROM users WHERE email_id = ? OR usn = ?");
    $stmt->execute([$data['email'], $data['usn']]);
    
    if ($stmt->rowCount() > 0) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'User with this Email or USN already exists']);
        exit;
    }

    // Insert new user
    $sql = "INSERT INTO users (
                name, 
                email_id, 
                password, 
                usn, 
                branch, 
                phone_number,
                year_of_graduation, 
                is_active, 
                created_at
            ) VALUES (
                ?, ?, ?, ?, ?, ?, ?, 0, NOW()
            )";
            
    $stmt = $pdo->prepare($sql);
    
    $passwordHash = password_hash($data['password'], PASSWORD_DEFAULT);
    $department = $data['department'] ?? null;
    $phoneNumber = $data['phone_number'] ?? null;
    $batch = $data['batch'] ?? null;
    
    $result = $stmt->execute([
        $data['name'],
        $data['email'],
        $passwordHash,
        $data['usn'],
        $department, 
        $phoneNumber,
        $batch       
    ]);

    if ($result) {
        http_response_code(201);
        echo json_encode([
            'success' => true, 
            'message' => 'Registration successful. Please wait for SPOC approval.'
        ]);
    } else {
        throw new Exception('Database Insert Failed');
    }

} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false, 
        'message' => 'Database error',
        'error' => $e->getMessage(),
        'trace' => $e->getTraceAsString()
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false, 
        'message' => 'Server error',
        'error' => $e->getMessage(),
        'trace' => $e->getTraceAsString()
    ]);
}
?>
