<?php
require_once 'api/includes/db_config.php';
try {
    $stmt = $pdo->prepare("SELECT id FROM events WHERE JSON_CONTAINS(registered_alumni_ids, :json)");
    $stmt->execute([':json' => '"2"']);
    print_r($stmt->fetchAll(PDO::FETCH_ASSOC));
} catch (PDOException $e) {
    echo "Error: " . $e->getMessage();
}
?>
