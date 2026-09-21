<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

require_once __DIR__ . '/../includes/db_config.php';

// Get authorization token
$headers = getallheaders();
$authHeader = $headers['Authorization'] ?? (isset($_SERVER['HTTP_AUTHORIZATION']) ? $_SERVER['HTTP_AUTHORIZATION'] : '');

// Extract token from "Bearer <token>" format
$token = '';
if (strpos($authHeader, 'Bearer ') === 0) {
    $token = substr($authHeader, 7);
} else {
    $token = $authHeader; // Fallback for backward compatibility
}

error_log("ME.PHP: Raw auth header: " . $authHeader);
error_log("ME.PHP: Extracted token: " . $token);

if (empty($token)) {
    http_response_code(401);
    echo json_encode(['success' => false, 'message' => 'Unauthorized']);
    exit;
}

try {
    error_log("ME.PHP: Token received: " . $token);
    
    $stmt = $pdo->prepare("SELECT * FROM users WHERE auth_token = ? AND is_active = 1");
    $stmt->execute([$token]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);
    
    error_log("ME.PHP: User data found: " . print_r($user, true));

    if ($user) {
        unset($user['password']);
        unset($user['auth_token']);
        
        // Map database columns to expected API format
        $userData = [
            'id' => $user['id'],
            'name' => $user['name'],
            'email' => $user['email_id'] ?? '',
            // Check both phone_number (from register.php) and phone (from schema)
            'phone' => !empty($user['phone_number']) ? $user['phone_number'] : ($user['phone'] ?? null),
            // Check year_of_graduation and ensure it's a string, fallback to batch
            'batch' => !empty($user['year_of_graduation']) ? (string)$user['year_of_graduation'] : (!empty($user['batch']) ? (string)$user['batch'] : null),
            // Check branch (from register.php) and fallback to department
            'department' => !empty($user['branch']) ? $user['branch'] : ($user['department'] ?? null),
            'role' => $user['role'] ?? 'alumni',
            'profile_picture' => $user['profile_picture'] ?? null
        ];
        
        error_log("ME.PHP: Mapped user data: " . print_r($userData, true));
        
        echo json_encode([
            'success' => true,
            'data' => $userData
        ]);
    } else {
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Invalid token']);
    }
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Server error']);
}
?>

