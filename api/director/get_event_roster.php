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
    $stmt = $pdo->prepare("SELECT id, is_director FROM users WHERE auth_token = ? AND is_active = 1");
    $stmt->execute([$token]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$user || $user['is_director'] != 1) {
        http_response_code(403);
        echo json_encode(['success' => false, 'message' => 'Forbidden: Director access required']);
        exit;
    }

    $eventId = $_GET['event_id'] ?? null;
    
    if (!$eventId) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'event_id is required']);
        exit;
    }

    $eventStmt = $pdo->prepare("SELECT registered_alumni_ids, updated_at FROM events WHERE id = :event_id");
    $eventStmt->execute([':event_id' => $eventId]);
    $event = $eventStmt->fetch(PDO::FETCH_ASSOC);

    $roster = [];
    if ($event && !empty($event['registered_alumni_ids'])) {
        $ids = json_decode($event['registered_alumni_ids'], true);
        if (is_array($ids) && count($ids) > 0) {
            $inQuery = implode(',', array_fill(0, count($ids), '?'));
            $userStmt = $pdo->prepare("SELECT id, name, email_id, usn, branch, year_of_graduation as batch, phone_number as phone, designation as current_position, institute FROM users WHERE id IN ($inQuery)");
            $userStmt->execute($ids);
            
            $users = $userStmt->fetchAll(PDO::FETCH_ASSOC);
            foreach ($users as &$u) {
                $u['registered_at'] = $event['updated_at'];
            }
            $roster = $users;
        }
    }

    echo json_encode([
        'success' => true,
        'data' => $roster
    ]);

} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Server error: ' . $e->getMessage()]);
}
?>

