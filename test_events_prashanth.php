<?php
$_SERVER['REQUEST_METHOD'] = 'GET';
ob_start();
require_once 'c:/Users/HEMANTH D/Downloads/gmu_alumni_app/gmu_alumni_app/api/includes/db_config.php';
$stmt = $pdo->prepare("SELECT id, usn FROM users WHERE name LIKE '%prashanth%' LIMIT 1");
$stmt->execute();
$user = $stmt->fetch(PDO::FETCH_ASSOC);

$alumniId = $user['id'];
$alumniUsn = !empty($user['usn']) ? $user['usn'] : '';

$query = "SELECT e.id, e.title, e.description, e.location, e.event_date, e.created_at, e.created_at as registered_at,
          (EXISTS (SELECT 1 FROM feedback f WHERE f.event_id = e.id AND (f.user_id = :alumni_id_str OR (f.user_id = :alumni_usn AND :alumni_usn != '')))) AS has_submitted_feedback
          FROM events e
          WHERE (JSON_CONTAINS(COALESCE(e.registered_alumni_ids, '[]'), :alumni_str) 
             OR JSON_CONTAINS(COALESCE(e.registered_alumni_ids, '[]'), :alumni_int))
            AND e.is_active = 1
          ORDER BY e.event_date DESC";
          
$eventsStmt = $pdo->prepare($query);
$eventsStmt->execute([
    ':alumni_str' => '"' . $alumniId . '"',
    ':alumni_int' => (string)$alumniId,
    ':alumni_id_str' => (string)$alumniId,
    ':alumni_usn' => (string)$alumniUsn
]);
print_r($eventsStmt->fetchAll(PDO::FETCH_ASSOC));
?>
