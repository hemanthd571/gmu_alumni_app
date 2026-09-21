<?php
require_once 'c:/Users/HEMANTH D/Downloads/gmu_alumni_app/gmu_alumni_app/api/includes/db_config.php';
$stmt = $pdo->query('SELECT * FROM feedback ORDER BY id DESC LIMIT 5');
print_r($stmt->fetchAll(PDO::FETCH_ASSOC));
?>
