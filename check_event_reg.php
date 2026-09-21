<?php
require_once 'c:/Users/HEMANTH D/Downloads/gmu_alumni_app/gmu_alumni_app/api/includes/db_config.php';
$stmt = $pdo->query('SELECT id, title, registered_alumni_ids FROM events WHERE id IN (9, 12)');
print_r($stmt->fetchAll(PDO::FETCH_ASSOC));
?>
