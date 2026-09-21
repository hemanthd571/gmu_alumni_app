<?php
require_once 'c:/Users/HEMANTH D/Downloads/gmu_alumni_app/gmu_alumni_app/api/includes/db_config.php';
$stmt = $pdo->query("DESCRIBE messages");
print_r($stmt->fetchAll(PDO::FETCH_ASSOC));
?>
