<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

require_once '../includes/db_config.php';

try {
    // For multipart/form-data, data comes in $_POST, not php://input
    $user_id = $_POST['user_id'] ?? null;
    $rating = $_POST['rating'] ?? null;
    $feedback_text = $_POST['feedback_text'] ?? '';
    $event_id = $_POST['event_id'] ?? null;
    $video_path = null;
    
    if ($user_id === null || $user_id === '') {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'User ID is required']);
        exit;
    }

    if ($rating === null || $rating < 1 || $rating > 5) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Valid rating (1-5) is required']);
        exit;
    }
    
    if (empty($feedback_text) && empty($_FILES['video'])) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Text or video feedback is required']);
        exit;
    }

    // Handle video upload if present
    if (isset($_FILES['video']) && $_FILES['video']['error'] === UPLOAD_ERR_OK) {
        $upload_dir = '../uploads/feedback_videos/';
        if (!file_exists($upload_dir)) {
            mkdir($upload_dir, 0777, true);
        }

        $file_info = pathinfo($_FILES['video']['name']);
        $ext = strtolower($file_info['extension']);
        $allowed_exts = ['mp4', 'mov', 'avi', 'mkv', 'webm', 'm4a', 'mp3', 'aac', 'wav'];

        if (!in_array($ext, $allowed_exts)) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Invalid media format. Allowed: mp4, mov, avi, mkv, webm, m4a, mp3, aac, wav']);
            exit;
        }

        $new_filename = 'feedback_' . $user_id . '_' . time() . '.' . $ext;
        $destination = $upload_dir . $new_filename;

        if (move_uploaded_file($_FILES['video']['tmp_name'], $destination)) {
            $video_path = 'uploads/feedback_videos/' . $new_filename;
        } else {
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => 'Failed to upload video']);
            exit;
        }
    }
    
    if ($event_id !== null && $event_id !== '') {
        $check_query = "SELECT id FROM feedback WHERE user_id = :user_id AND event_id = :event_id";
        $check_stmt = $pdo->prepare($check_query);
        $check_stmt->execute([':user_id' => $user_id, ':event_id' => $event_id]);
        if ($check_stmt->fetch()) {
            http_response_code(409);
            echo json_encode(['success' => false, 'message' => 'You have already submitted feedback for this event.']);
            exit;
        }
    }

    $query = "INSERT INTO feedback (user_id, event_id, rating, feedback_text, video_audio_path, created_at) 
              VALUES (:user_id, :event_id, :rating, :feedback_text, :video_audio_path, NOW())";
    $stmt = $pdo->prepare($query);
    $stmt->execute([
        ':user_id' => $user_id,
        ':event_id' => $event_id,
        ':rating' => $rating,
        ':feedback_text' => $feedback_text,
        ':video_audio_path' => $video_path
    ]);

    echo json_encode([
        'success' => true,
        'message' => 'Feedback submitted successfully!'
    ]);

} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Server error: ' . $e->getMessage()]);
}
?>
