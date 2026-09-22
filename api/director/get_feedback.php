<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

require_once '../includes/db_config.php';

$director_id = $_GET['user_id'] ?? null;
$event_id = $_GET['event_id'] ?? null;

if (!$director_id) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Director ID is required']);
    exit;
}

try {
    // 1. Verify that the user requesting is actually a director
    $stmt = $pdo->prepare("SELECT is_director FROM users WHERE id = ? AND is_active = 1");
    $stmt->execute([$director_id]);
    $user = $stmt->fetch();

    if (!$user || (int)$user['is_director'] !== 1) {
        http_response_code(403);
        echo json_encode(['success' => false, 'message' => 'Unauthorized access. Director privileges required.']);
        exit;
    }

    // 2. Fetch all feedback, joining with the users table to get name and profile picture.
    // The feedback.user_id column might contain the string USN or the numeric ID.
    $query = "
        SELECT f.id, f.user_id as submitter_identifier, f.event_id, f.rating, f.feedback_text, f.video_audio_path as video_path, f.created_at,
               u.name, u.profile_picture, u.usn, u.branch, u.year_of_graduation as batch, u.phone_number as phone
        FROM feedback f
        LEFT JOIN users u ON f.user_id = u.usn OR f.user_id = CAST(u.id AS CHAR)
    ";

    $params = [];
    if ($event_id) {
        $query .= " WHERE f.event_id = ? ";
        $params[] = $event_id;
    }

    $query .= " ORDER BY f.created_at DESC ";

    $stmt = $pdo->prepare($query);
    $stmt->execute($params);
    $feedbackList = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        'success' => true,
        'data' => $feedbackList
    ]);

} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Database error: ' . $e->getMessage()]);
}
?>
