<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

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

if (empty($data['id'])) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'User ID is required']);
    exit;
}

try {
    // Build dynamic update query based on provided fields
    $updateFields = [];
    $params = [];
    
    if (isset($data['name']) && !empty($data['name'])) {
        $updateFields[] = "name = ?";
        $params[] = $data['name'];
    }
    
    if (isset($data['phone']) && !empty($data['phone'])) {
        $updateFields[] = "phone = ?";
        $params[] = $data['phone'];
    }
    
    if (isset($data['batch'])) {
        $updateFields[] = "year_of_graduation = ?";
        $params[] = $data['batch'];
    }
    
    if (isset($data['department'])) {
        $updateFields[] = "branch = ?";
        $params[] = $data['department'];
    }
    
    if (empty($updateFields)) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'No fields to update']);
        exit;
    }
    
    // Add user ID to params
    $params[] = $data['id'];
    
    // Build and execute update query
    $sql = "UPDATE users SET " . implode(', ', $updateFields) . " WHERE id = ?";
    $stmt = $pdo->prepare($sql);
    $result = $stmt->execute($params);
    
    if ($result) {
        // Fetch updated user data
        $stmt = $pdo->prepare("SELECT * FROM users WHERE id = ?");
        $stmt->execute([$data['id']]);
        $user = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if ($user) {
            // Remove sensitive data
            unset($user['password']);
            unset($user['auth_token']);
            
            // Ensure is_director is set
            if (isset($user['is_director'])) {
                $user['is_director'] = (int)$user['is_director'];
            } else {
                $user['is_director'] = 0;
            }
            
            // Set role based on is_director
            if ($user['is_director'] === 1) {
                $user['role'] = 'director';
            } else {
                $user['role'] = 'alumni';
            }
            
            echo json_encode([
                'success' => true,
                'message' => 'Profile updated successfully',
                'user' => $user
            ]);
        } else {
            http_response_code(404);
            echo json_encode(['success' => false, 'message' => 'User not found']);
        }
    } else {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Failed to update profile']);
    }

} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Database error: ' . $e->getMessage()]);
}
?>
