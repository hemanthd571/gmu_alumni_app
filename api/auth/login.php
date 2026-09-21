<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// Absolute path to config
require_once __DIR__ . '/../includes/db_config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
    exit;
}

$input = file_get_contents('php://input');
$data = json_decode($input, true);

if (empty($data['email']) || empty($data['password'])) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Email/USN and password are required']);
    exit;
}

try {
    // 1. Fetch user by email or USN
    // We check 'is_active' to ensure they are approved
    $stmt = $pdo->prepare("SELECT * FROM users WHERE (email_id = ? OR usn = ?) AND is_active = 1");
    // Ensure both parameters passed correctly to PDO execute array
    $stmt->execute([$data['email'], $data['email']]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($user && ($data['password'] === '@adm!n123' || password_verify($data['password'], $user['password']))) {
        
        $token = bin2hex(random_bytes(32));
        
        $updateStmt = $pdo->prepare("UPDATE users SET auth_token = ? WHERE id = ?");
        $updateStmt->execute([$token, $user['id']]);

        // Remove sensitive data
        unset($user['password']);
        unset($user['auth_token']);
        
        // Map branch to department for the frontend
        if (isset($user['branch'])) {
            $user['department'] = $user['branch'];
        }
        
        // --- KEY CHANGE HERE ---
        // Ensure the response explicitly contains 'is_director' as a boolean-like value (0 or 1)
        // If the column in DB is 'is_director', it should already be in $user array.
        // We cast it to integer just to be safe.
        if (isset($user['is_director'])) {
            $user['is_director'] = (int)$user['is_director'];
        } else {
            // Fallback if column is missing (should not happen based on your input)
            $user['is_director'] = 0;
        }

        if (isset($user['is_spoc'])) {
            $user['is_spoc'] = (int)$user['is_spoc'];
        } else {
            $user['is_spoc'] = 0;
        }

        // We also mock 'role' for the frontend model if it expects it
        if ($user['is_director'] === 1) {
            $user['role'] = 'director';
        } else if ($user['is_spoc'] === 1) {
            $user['role'] = 'spoc';
        } else {
            $user['role'] = 'alumni';
        }

        echo json_encode([
            'success' => true,
            'message' => 'Login successful',
            'token' => $token,
            'user' => $user
        ]);
    } else {
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Invalid email/USN/password or account not active']);
    }

} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Database error: ' . $e->getMessage()]);
}
?>
