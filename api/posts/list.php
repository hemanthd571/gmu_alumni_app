<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');

require_once __DIR__ . '/../includes/db_config.php';

try {
    $user_id = isset($_GET['user_id']) ? (int)$_GET['user_id'] : null;
    $author_id = isset($_GET['author_id']) ? (int)$_GET['author_id'] : null;
    $limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 20;
    $offset = isset($_GET['offset']) ? (int)$_GET['offset'] : 0;
    
    $query = "SELECT p.*, u.name, u.profile_picture, u.usn,
                     (SELECT COUNT(*) FROM post_likes WHERE post_id = p.id) as like_count,
                     (SELECT COUNT(*) FROM post_shares WHERE post_id = p.id) as share_count";
    
    if ($user_id) {
        $query .= ", (SELECT COUNT(*) FROM post_likes WHERE post_id = p.id AND user_id = :user_id) as is_liked";
    } else {
        $query .= ", 0 as is_liked";
    }
    
    $query .= " FROM posts p
               JOIN users u ON p.user_id = u.id
               WHERE p.status = 'approved' AND p.is_active = 1";

    // Filter by specific author (used on profile screen)
    if ($author_id) {
        $query .= " AND p.user_id = :author_id";
    }

    $query .= " ORDER BY p.created_at DESC
               LIMIT :limit OFFSET :offset";

    $stmt = $pdo->prepare($query);
    
    if ($user_id) {
        $stmt->bindParam(":user_id", $user_id, PDO::PARAM_INT);
    }
    if ($author_id) {
        $stmt->bindParam(":author_id", $author_id, PDO::PARAM_INT);
    }
    $stmt->bindParam(":limit", $limit, PDO::PARAM_INT);
    $stmt->bindParam(":offset", $offset, PDO::PARAM_INT);
    $stmt->execute();

    $posts = [];
    while($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        $posts[] = [
            'id' => (int)$row['id'],
            'user_id' => (int)$row['user_id'],
            'content' => $row['content'],
            'media_type' => $row['media_type'],
            'media_url' => $row['media_url'],
            'status' => $row['status'],
            'created_at' => $row['created_at'],
            'user' => [
                'id' => (int)$row['user_id'],
                'name' => $row['name'],
                'profile_picture' => $row['profile_picture'] ?: 'default.jpg',
                'usn' => $row['usn']
            ],
            'like_count' => (int)$row['like_count'],
            'share_count' => (int)$row['share_count'],
            'is_liked' => (bool)$row['is_liked']
        ];
    }

    echo json_encode([
        'success' => true,
        'data' => $posts
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Server error: ' . $e->getMessage()]);
}
?>

