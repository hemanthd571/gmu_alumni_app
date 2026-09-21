<?php
require_once 'C:\xampp\htdocs\alumni\api\includes\db_config.php';
$stmt = $pdo->query('SELECT id, feedback_text, video_path FROM feedback ORDER BY id DESC LIMIT 5');
$rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
print_r($rows);
?>
