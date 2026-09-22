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

if (empty($token)) {
    http_response_code(401);
    echo json_encode(['success' => false, 'message' => 'Unauthorized']);
    exit;
}

try {
    // 1. Identify Authenticated Alumni AND fetch their details
    $stmt = $pdo->prepare("SELECT id, name, branch, year_of_graduation FROM users WHERE auth_token = ? AND is_active = 1");
    $stmt->execute([$token]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$user) {
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Invalid token or inactive user']);
        exit;
    }
    
    $alumniId = $user['id'];
    $alumniName = $user['name'] ?? 'Unknown';
    $alumniBranch = $user['branch'] ?? 'Unknown';
    $alumniBatch = $user['year_of_graduation'] ?? 'Unknown';

    $input = file_get_contents('php://input');
    $data = json_decode($input, true);
    $eventId = $data['event_id'] ?? null;

    if (!$eventId) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'event_id is required']);
        exit;
    }

    // 2. Validate event existence and active status
    $eventStmt = $pdo->prepare("SELECT id, registered_alumni_ids FROM events WHERE id = ? AND is_active = 1 FOR UPDATE");
    $eventStmt->execute([$eventId]);
    $event = $eventStmt->fetch(PDO::FETCH_ASSOC);

    if (!$event) {
        http_response_code(404);
        echo json_encode(['success' => false, 'message' => 'Event not found or inactive']);
        exit;
    }

    // 3. Insert registration (handling objects inside JSON array)
    try {
        $registeredAlumni = json_decode($event['registered_alumni_ids'] ?? '[]', true);
        if (!is_array($registeredAlumni)) {
            $registeredAlumni = [];
        }

        // Check if user is already registered (handles both the old simple ID format and new Object format)
        $isRegistered = false;
        foreach ($registeredAlumni as $reg) {
            // New format (object with id)
            if (is_array($reg) && isset($reg['id']) && $reg['id'] == $alumniId) {
                $isRegistered = true;
                break;
            }
            // Old format (just raw ID)
            elseif ($reg == $alumniId) {
                $isRegistered = true;
                break;
            }
        }

        if ($isRegistered) {
            http_response_code(409); // Conflict
            echo json_encode(['success' => false, 'message' => 'You are already registered for this event.']);
            exit;
        }

        // Push the new structured object into the JSON array!
        $registeredAlumni[] = [
            'id' => $alumniId,
            'name' => $alumniName,
            'branch' => $alumniBranch,
            'batch' => $alumniBatch
        ];
        
        $updatedJson = json_encode($registeredAlumni);

        $updateStmt = $pdo->prepare("UPDATE events SET registered_alumni_ids = ? WHERE id = ?");
        $updateStmt->execute([$updatedJson, $eventId]);
        
        echo json_encode([
            'success' => true,
            'message' => 'Successfully registered for the event!'
        ]);

    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Database update error: ' . $e->getMessage()]);
    }

} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Server error: ' . $e->getMessage()]);
}
?>
