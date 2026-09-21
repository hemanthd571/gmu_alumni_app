<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');

require_once __DIR__ . '/../includes/db_config.php';

try {
    $limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 20;
    $offset = isset($_GET['offset']) ? (int)$_GET['offset'] : 0;
    
    $query = "SELECT a.*, u.name as director_name, u.profile_picture as director_profile_picture
              FROM announcements a
              JOIN users u ON a.user_id = u.id
              WHERE a.is_active = 1
              ORDER BY a.created_at DESC
              LIMIT :limit OFFSET :offset";

    $stmt = $pdo->prepare($query);
    $stmt->bindParam(":limit", $limit, PDO::PARAM_INT);
    $stmt->bindParam(":offset", $offset, PDO::PARAM_INT);
    $stmt->execute();

    $announcements = [];
    while($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        $announcements[] = [
            'id' => (int)$row['id'],
            'director_id' => (int)$row['user_id'],
            'title' => $row['title'],
            'content' => $row['content'],
            'created_at' => $row['created_at'],
            'director_name' => $row['director_name'],
            'director_profile_picture' => $row['director_profile_picture'] ?: 'default.jpg'
        ];
    }

    echo json_encode([
        'success' => true,
        'data' => $announcements
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Server error: ' . $e->getMessage()]);
}
?>

