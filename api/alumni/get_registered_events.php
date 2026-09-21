<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once __DIR__ . '/../includes/db_config.php';

$headers = getallheaders();
$authHeader = $headers['Authorization'] ?? (isset($_SERVER['HTTP_AUTHORIZATION']) ? $_SERVER['HTTP_AUTHORIZATION'] : '');
$token = '';
if (strpos($authHeader, 'Bearer ') === 0) {
    $token = substr($authHeader, 7);
} else {
    $token = $authHeader;
}

if (empty($token)) {
    http_response_code(401);
    echo json_encode(['success' => false, 'message' => 'Unauthorized']);
    exit;
}

try {
    $stmt = $pdo->prepare("SELECT id, usn FROM users WHERE auth_token = ? AND is_active = 1");
    $stmt->execute([$token]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$user) {
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Invalid token or inactive user']);
        exit;
    }
    
    $alumniId = $user['id'];
    $alumniUsn = !empty($user['usn']) ? $user['usn'] : '';

    $columns = $pdo->query("SHOW COLUMNS FROM events")->fetchAll(PDO::FETCH_COLUMN);
    $imageSelect = in_array('featured_image', $columns) ? 'e.featured_image' : 
                   (in_array('image', $columns) ? 'e.image' : 'NULL');

    // Handle both the old legacy format (raw IDs) and the new format (JSON objects)
    $query = "SELECT e.id, e.title, e.description, e.location, $imageSelect as image, e.event_date, e.created_at, e.created_at as registered_at,
              (EXISTS (SELECT 1 FROM feedback f WHERE f.event_id = e.id AND (f.user_id = :alumni_id_str OR (f.user_id = :alumni_usn AND :alumni_usn != '')))) AS has_submitted_feedback
              FROM events e
              WHERE (
                 JSON_CONTAINS(COALESCE(e.registered_alumni_ids, '[]'), :alumni_str) 
                 OR JSON_CONTAINS(COALESCE(e.registered_alumni_ids, '[]'), :alumni_int)
                 OR JSON_CONTAINS(COALESCE(e.registered_alumni_ids, '[]'), :alumni_obj_str)
                 OR JSON_CONTAINS(COALESCE(e.registered_alumni_ids, '[]'), :alumni_obj_int)
              )
              AND e.is_active = 1
              ORDER BY e.event_date DESC";
              
    $eventsStmt = $pdo->prepare($query);
    $eventsStmt->execute([
        ':alumni_str' => '"' . $alumniId . '"',
        ':alumni_int' => (string)$alumniId,
        ':alumni_obj_str' => '{"id":"' . $alumniId . '"}',
        ':alumni_obj_int' => '{"id":' . $alumniId . '}',
        ':alumni_id_str' => (string)$alumniId,
        ':alumni_usn' => (string)$alumniUsn
    ]);
    
    $events = $eventsStmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        'success' => true,
        'data' => $events
    ]);

} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Server Error: ' . $e->getMessage()]);
}
?>
