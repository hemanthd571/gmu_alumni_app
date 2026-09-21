<?php
require 'api/includes/db_config.php';
$stmt = $pdo->query('SHOW CREATE TABLE groups');
print_r($stmt->fetch(PDO::FETCH_ASSOC));
$stmt = $pdo->query('SHOW CREATE TABLE group_members');
print_r($stmt->fetch(PDO::FETCH_ASSOC));
?>
