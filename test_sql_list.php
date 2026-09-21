<?php
require_once 'c:/Users/HEMANTH D/Downloads/gmu_alumni_app/gmu_alumni_app/api/includes/db_config.php';
$user_id = 2;
$other_user_id = 88;
$limit = 50;
$offset = 0;

$query = "SELECT m.*, u.name as sender_name, u.profile_picture as sender_profile_picture
          FROM messages m
          JOIN users u ON m.sender_id = u.id
          WHERE (m.sender_id = :user_id AND m.receiver_id = :other_user_id)
             OR (m.sender_id = :other_user_id2 AND m.receiver_id = :user_id2)
          ORDER BY m.created_at DESC
          LIMIT :limit OFFSET :offset";

$stmt = $pdo->prepare($query);
$stmt->bindParam(":user_id", $user_id, PDO::PARAM_INT);
$stmt->bindParam(":user_id2", $user_id, PDO::PARAM_INT);
$stmt->bindParam(":other_user_id", $other_user_id, PDO::PARAM_INT);
$stmt->bindParam(":other_user_id2", $other_user_id, PDO::PARAM_INT);
$stmt->bindParam(":limit", $limit, PDO::PARAM_INT);
$stmt->bindParam(":offset", $offset, PDO::PARAM_INT);
if (!$stmt->execute()) {
    print_r($stmt->errorInfo());
} else {
    print_r($stmt->fetchAll(PDO::FETCH_ASSOC));
}
?>
