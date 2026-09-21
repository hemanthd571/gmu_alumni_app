<?php
require 'C:/xampp/htdocs/alumni/api/includes/db_config.php';
$stmt = $pdo->query('SHOW COLUMNS FROM feedback');
print_r($stmt->fetchAll(PDO::FETCH_ASSOC));
?>
