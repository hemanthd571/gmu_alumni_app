<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

require_once __DIR__ . '/../includes/db_config.php';

if (!isset($_GET['user_id'])) {
    echo json_encode([
        'success' => false,
        'message' => 'User ID required'
    ]);
    exit();
}

$user_id = intval($_GET['user_id']);

try {
    $query = "SELECT f.following_id, u.name, u.profile_picture 
              FROM follows f 
              JOIN users u ON f.following_id = u.id 
              WHERE f.follower_id = :user_id";
    $stmt = $pdo->prepare($query);
    $stmt->bindParam(":user_id", $user_id, PDO::PARAM_INT);
    $stmt->execute();

    $following = [];
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        $following[] = $row;
    }

    echo json_encode([
        'success' => true,
        'data' => $following
    ]);

} catch (PDOException $e) {
    echo json_encode([
        'success' => false,
        'message' => 'Error: ' . $e->getMessage()
    ]);
}
?>

