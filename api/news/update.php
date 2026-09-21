<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

require_once __DIR__ . '/../includes/db_config.php';

$data = json_decode(file_get_contents("php://input"), true);

if (!isset($data['id']) || !isset($data['title']) || !isset($data['content'])) {
    echo json_encode(['success' => false, 'message' => 'ID, title and content are required']);
    exit;
}

$id = $data['id'];
$title = $data['title'];
$content = $data['content'];
$image = $data['image'] ?? null;

try {
    // Check if featured_image column exists
    $columns = $pdo->query("SHOW COLUMNS FROM news")->fetchAll(PDO::FETCH_COLUMN);
    $hasFeaturedImage = in_array('featured_image', $columns);
    
    if ($hasFeaturedImage) {
        $stmt = $pdo->prepare("UPDATE news SET title = ?, content = ?, featured_image = ? WHERE id = ?");
        $stmt->execute([$title, $content, $image, $id]);
    } else {
        $stmt = $pdo->prepare("UPDATE news SET title = ?, content = ? WHERE id = ?");
        $stmt->execute([$title, $content, $id]);
    }

    echo json_encode(['success' => true, 'message' => 'News updated successfully']);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Server error: ' . $e->getMessage()]);
}
?>

