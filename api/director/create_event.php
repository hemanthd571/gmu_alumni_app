<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
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

error_log("CREATE_EVENT: Token received: " . $token);

if (empty($token)) {
    http_response_code(401);
    echo json_encode(['success' => false, 'message' => 'Unauthorized']);
    exit;
}

try {
    $stmt = $pdo->prepare("SELECT id, is_director FROM users WHERE auth_token = ? AND is_active = 1");
    $stmt->execute([$token]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    error_log("CREATE_EVENT: User fetched: " . print_r($user, true));

    if (!$user) {
        error_log("CREATE_EVENT: User is null for token: " . $token);
        http_response_code(403);
        echo json_encode(['success' => false, 'message' => 'Forbidden: Director access required (User not found)']);
        exit;
    }

    if ($user['is_director'] != 1) {
        error_log("CREATE_EVENT: User is not director. is_director: " . $user['is_director']);
        http_response_code(403);
        echo json_encode(['success' => false, 'message' => 'Forbidden: Director access required (Not a director)']);
        exit;
    }

    $input = file_get_contents('php://input');
    $data = json_decode($input, true);

    $title = $data['title'] ?? '';
    $description = $data['description'] ?? '';
    $eventDate = $data['event_date'] ?? '';
    $endDate = $data['end_date'] ?? $eventDate; // default to event_date if no end_date is provided
    $location = $data['location'] ?? '';
    $priority = $data['priority'] ?? 'high';

    if (empty($title) || empty($eventDate)) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Title and event date are required']);
        exit;
    }

    $query = "INSERT INTO events (title, description, event_date, end_date, location, created_at, is_active, organizer_id) 
              VALUES (:title, :description, :event_date, :end_date, :location, NOW(), 1, :organizer_id)";
    $insertStmt = $pdo->prepare($query);
    $insertStmt->execute([
        ':title' => $title,
        ':description' => $description,
        ':event_date' => $eventDate,
        ':end_date' => date('Y-m-d H:i:s', strtotime($endDate)),
        ':location' => $location,
        ':organizer_id' => $user['id']
    ]);
    
    $eventId = $pdo->lastInsertId();

    // Sync to noticeboard
    $noticeTitle = "New Event: " . $title;
    $noticeContent = "A new event has been scheduled for " . date('F j, Y, g:i a', strtotime($eventDate));
    if (!empty($location)) {
        $noticeContent .= " at " . $location;
    }
    $noticeContent .= ".\n\nDetails: " . $description;
    
    $noticeQuery = "INSERT INTO noticeboard (title, content, author_id, priority, is_active, publish_date, created_at) 
                    VALUES (:title, :content, :author_id, :priority, 1, NOW(), NOW())";
    $noticeStmt = $pdo->prepare($noticeQuery);
    $noticeStmt->execute([
        ':title' => $noticeTitle,
        ':content' => $noticeContent,
        ':author_id' => $user['id'],
        ':priority' => $priority
    ]);

    echo json_encode([
        'success' => true,
        'message' => 'Event created and added to noticeboard successfully',
        'event_id' => $eventId
    ]);

} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Server error: ' . $e->getMessage()]);
}
?>


