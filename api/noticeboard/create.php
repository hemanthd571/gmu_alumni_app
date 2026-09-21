<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

require_once __DIR__ . '/../includes/db_config.php';

// Get the authorization token
$headers = getallheaders();
$token = isset($headers['Authorization']) ? $headers['Authorization'] : null;

// Get user ID from token (you may need to implement token validation)
// For now, we'll use a default director user ID or get it from session
$author_id = 1; // Default to admin/director user

// If you have token validation, decode it to get the actual user ID
// Example: $author_id = validateTokenAndGetUserId($token);

$data = json_decode(file_get_contents("php://input"), true);

if (!isset($data['title']) || !isset($data['content'])) {
    echo json_encode(['success' => false, 'message' => 'Title and content are required']);
    exit;
}

$title = $data['title'];
$content = $data['content'];
$priority = $data['priority'] ?? 'medium';
$publish_date = $data['publish_date'] ?? date('Y-m-d H:i:s');

try {
    $stmt = $pdo->prepare("INSERT INTO noticeboard (title, content, priority, publish_date, is_active, author_id) VALUES (?, ?, ?, ?, 1, ?)");
    $stmt->execute([$title, $content, $priority, $publish_date, $author_id]);

    echo json_encode(['success' => true, 'message' => 'Notice created successfully']);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Server error: ' . $e->getMessage()]);
}
?>

