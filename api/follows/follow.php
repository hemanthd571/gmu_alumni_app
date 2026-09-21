<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once __DIR__ . '/../includes/db_config.php';

$input = json_decode(file_get_contents('php://input'), true);

if (!isset($input['follower_id']) || !isset($input['following_id'])) {
    echo json_encode([
        'success' => false,
        'message' => 'Missing required fields'
    ]);
    exit();
}

$follower_id = intval($input['follower_id']);
$following_id = intval($input['following_id']);

if ($follower_id === $following_id) {
    echo json_encode([
        'success' => false,
        'message' => 'You cannot follow yourself'
    ]);
    exit();
}

try {
    // Check if already following
    $check_query = "SELECT id FROM follows WHERE follower_id = :follower_id AND following_id = :following_id";
    $check_stmt = $pdo->prepare($check_query);
    $check_stmt->bindParam(":follower_id", $follower_id, PDO::PARAM_INT);
    $check_stmt->bindParam(":following_id", $following_id, PDO::PARAM_INT);
    $check_stmt->execute();
    $result = $check_stmt->fetch(PDO::FETCH_ASSOC);

    if ($result) {
        // Already following - unfollow
        $delete_query = "DELETE FROM follows WHERE follower_id = :follower_id AND following_id = :following_id";
        $delete_stmt = $pdo->prepare($delete_query);
        $delete_stmt->bindParam(":follower_id", $follower_id, PDO::PARAM_INT);
        $delete_stmt->bindParam(":following_id", $following_id, PDO::PARAM_INT);
        
        if ($delete_stmt->execute()) {
            echo json_encode([
                'success' => true,
                'message' => 'Unfollowed successfully',
                'is_following' => false
            ]);
        } else {
            throw new Exception('Failed to unfollow');
        }
    } else {
        // Not following - follow
        $insert_query = "INSERT INTO follows (follower_id, following_id, created_at) VALUES (:follower_id, :following_id, NOW())";
        $insert_stmt = $pdo->prepare($insert_query);
        $insert_stmt->bindParam(":follower_id", $follower_id, PDO::PARAM_INT);
        $insert_stmt->bindParam(":following_id", $following_id, PDO::PARAM_INT);
        
        if ($insert_stmt->execute()) {
            echo json_encode([
                'success' => true,
                'message' => 'Followed successfully',
                'is_following' => true
            ]);
        } else {
            throw new Exception('Failed to follow');
        }
    }

} catch (PDOException $e) {
    echo json_encode([
        'success' => false,
        'message' => 'Error: ' . $e->getMessage()
    ]);
}
?>

