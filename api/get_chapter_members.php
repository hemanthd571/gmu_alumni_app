<?php
header('Content-Type: application/json');
require_once __DIR__ . '/includes/db_config.php';

// Enable error reporting
error_reporting(E_ALL);
ini_set('display_errors', 1);

try {
    // Get chapter_id from query parameters
    $chapterId = filter_input(INPUT_GET, 'chapter_id', FILTER_VALIDATE_INT);
    
    if (!$chapterId) {
        throw new Exception('Invalid chapter ID');
    }
    
    // Query to get chapter members
    $query = "
        SELECT 
            u.id,
            u.name,
            u.usn,
            u.profile_picture,
            u.email_id as email,
            u.phone_number as phone,
            u.year_of_graduation,
            u.branch,
            u.institute
        FROM users u
        INNER JOIN user_chapters uc ON u.id = uc.user_id
        WHERE uc.chapter_id = ?
        ORDER BY u.name ASC
    ";
    
    $stmt = $pdo->prepare($query);
    $stmt->execute([$chapterId]);
    $members = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Process profile picture URLs
    $baseUrl = (isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https' : 'http') . '://' . $_SERVER['HTTP_HOST'];
    
    foreach ($members as &$member) {
        if (!empty($member['profile_picture'])) {
            if (!filter_var($member['profile_picture'], FILTER_VALIDATE_URL)) {
                $member['profile_picture'] = $baseUrl . '/alumni/' . ltrim($member['profile_picture'], '/');
            }
        } else {
            $member['profile_picture'] = $baseUrl . '/alumni/assets/images/default-avatar.png';
        }
    }
    
    echo json_encode([
        'success' => true,
        'members' => $members
    ]);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error: ' . $e->getMessage()
    ]);
}
