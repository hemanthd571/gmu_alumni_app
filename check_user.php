<?php
require_once 'c:/Users/HEMANTH D/Downloads/gmu_alumni_app/gmu_alumni_app/api/includes/db_config.php';
$stmt = $pdo->query("SELECT id, usn, name FROM users WHERE name LIKE '%prashanth%' OR usn = '4GM06EC060'");
print_r($stmt->fetchAll(PDO::FETCH_ASSOC));
?>
