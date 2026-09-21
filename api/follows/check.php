<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

require_once __DIR__ . '/../includes/db_config.php';

if (!isset($_GET['follower_id']) || !isset($_GET['following_id'])) {
    echo json_encode([
        'success' => false,
        'is_following' => false
    ]);
    exit();
}

$follower_id = intval($_GET['follower_id']);
$following_id = intval($_GET['following_id']);

try {
    $query = "SELECT id FROM follows WHERE follower_id = :follower_id AND following_id = :following_id";
    $stmt = $pdo->prepare($query);
    $stmt->bindParam(":follower_id", $follower_id, PDO::PARAM_INT);
    $stmt->bindParam(":following_id", $following_id, PDO::PARAM_INT);
    $stmt->execute();
    $result = $stmt->fetch(PDO::FETCH_ASSOC);

    echo json_encode([
        'success' => true,
        'is_following' => $result !== false
    ]);

} catch (PDOException $e) {
    echo json_encode([
        'success' => false,
        'is_following' => false
    ]);
}
?>

