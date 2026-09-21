<?php
header('Content-Type: application/json');
require_once __DIR__ . '/includes/db_config.php';

// Check if group ID is provided
if (!isset($_GET['group_id']) || !is_numeric($_GET['group_id'])) {
    http_response_code(400);
    echo json_encode(['error' => 'Invalid group ID']);
    exit;
}

$groupId = (int)$_GET['group_id'];

try {
    // Get group members with user details
    $stmt = $pdo->prepare("
        SELECT 
            u.id, 
            u.name, 
            u.email_id as email,
            u.profile_picture,
            u.usn
        FROM users u
        JOIN group_members gm ON u.id = gm.user_id
        WHERE gm.group_id = ? AND gm.is_active = 1
        ORDER BY u.name ASC
    
    ");
    
    $stmt->execute([$groupId]);
    $members = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Format the response
    $response = [
        'success' => true,
        'members' => array_map(function($member) {
            return [
                'id' => $member['id'],
                'name' => $member['name'],
                'email' => $member['email'],
                'profile_picture' => !empty($member['profile_picture']) ? 
                    (strpos($member['profile_picture'], 'http') === 0 ? $member['profile_picture'] : 
                    '/' . ltrim($member['profile_picture'], '/')) : 
                    '/alumni/assets/images/default-avatar.png',
                'usn' => $member['usn'] ?? ''
            ];
        }, $members)
    ];
    
    echo json_encode($response);
    
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => 'Database error: ' . $e->getMessage()
    ]);
}
