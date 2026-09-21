<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

require_once '../../includes/db_config.php';

$data = json_decode(file_get_contents("php://input"), true);

if (!isset($data['title']) || !isset($data['content'])) {
    echo json_encode(['success' => false, 'message' => 'Title and content are required']);
    exit;
}

$title = $data['title'];
$content = $data['content'];
$image = $data['image'] ?? null;

try {
    // Check if author_id column exists
    $columns = $pdo->query("SHOW COLUMNS FROM news")->fetchAll(PDO::FETCH_COLUMN);
    $hasAuthorId = in_array('author_id', $columns);
    $hasFeaturedImage = in_array('featured_image', $columns);
    
    // Find a valid user ID (preferably a director)
    $authorId = 1; // Default
    if ($hasAuthorId) {
        $userCheck = $pdo->query("SELECT id FROM users WHERE is_director = 1 LIMIT 1")->fetch(PDO::FETCH_ASSOC);
        if ($userCheck) {
            $authorId = $userCheck['id'];
        } else {
            // If no director, use any user
            $userCheck = $pdo->query("SELECT id FROM users LIMIT 1")->fetch(PDO::FETCH_ASSOC);
            if ($userCheck) {
                $authorId = $userCheck['id'];
            }
        }
    }
    
    if ($hasAuthorId && $hasFeaturedImage) {
        $stmt = $pdo->prepare("INSERT INTO news (title, content, featured_image, author_id, created_at, is_active) VALUES (?, ?, ?, ?, NOW(), 1)");
        $stmt->execute([$title, $content, $image, $authorId]);
    } elseif ($hasAuthorId) {
        $stmt = $pdo->prepare("INSERT INTO news (title, content, author_id, created_at, is_active) VALUES (?, ?, ?, NOW(), 1)");
        $stmt->execute([$title, $content, $authorId]);
    } elseif ($hasFeaturedImage) {
        $stmt = $pdo->prepare("INSERT INTO news (title, content, featured_image, created_at, is_active) VALUES (?, ?, ?, NOW(), 1)");
        $stmt->execute([$title, $content, $image]);
    } else {
        $stmt = $pdo->prepare("INSERT INTO news (title, content, created_at, is_active) VALUES (?, ?, NOW(), 1)");
        $stmt->execute([$title, $content]);
    }

    echo json_encode(['success' => true, 'message' => 'News created successfully']);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Server error: ' . $e->getMessage()]);
}
?>
