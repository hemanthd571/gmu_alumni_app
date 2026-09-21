<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");

// Enable error reporting for debugging
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Database connection
require_once __DIR__ . '/includes/db_config.php';

// Get mentor_id from query parameters
$mentor_id = isset($_GET['mentor_id']) ? intval($_GET['mentor_id']) : 0;

// Log the request
file_put_contents('debug_get_students.log', "[DEBUG] Request received. Mentor ID: $mentor_id\n", FILE_APPEND);

try {
    // Use the global $pdo connection from db_config.php
    global $pdo;
    
    if (!isset($pdo)) {
        throw new Exception("Database connection failed");
    }

    // Base query to fetch all students with profile pictures
    $sql = "SELECT s.student_id as id, s.name, s.usn, s.email, 
                   u.profile_picture, u.PROFILE_PICTURE as user_profile_picture
            FROM students s
            LEFT JOIN users u ON s.student_id = u.USER_NAME OR s.email = u.EMAIL";
    
    // If mentor_id is provided, exclude already mapped students
    if ($mentor_id > 0) {
        $sql .= " WHERE NOT EXISTS (
                    SELECT 1 FROM mentor_student_mapping m 
                    WHERE m.mentor_id = :mentor_id AND m.student_id = s.student_id
                  )";
    }
    
    $sql .= " ORDER BY s.name";
    
    $stmt = $pdo->prepare($sql);
    
    if ($mentor_id > 0) {
        $stmt->bindParam(':mentor_id', $mentor_id, PDO::PARAM_INT);
    }
    
    $stmt->execute();
    $students = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Log the query and result count
    $log = "[DEBUG] Query executed. Found " . count($students) . " students.\n";
    $log .= "[DEBUG] SQL: " . $sql . "\n";
    if ($mentor_id > 0) {
        $log .= "[DEBUG] With mentor_id: $mentor_id\n";
    }
    file_put_contents('debug_get_students.log', $log, FILE_APPEND);
    
    if (count($students) > 0) {
        // Log first student data for debugging
        if (count($students) > 0) {
            file_put_contents('debug_get_students.log', "[DEBUG] First student: " . json_encode($students[0]) . "\n", FILE_APPEND);
        }
        echo json_encode(["status" => "success", "data" => $students]);
    } else {
        // Fallback to users table if students table is empty (for backward compatibility)
        $fallback_sql = "SELECT ID as id, NAME as name, USER_NAME AS usn, EMAIL as email 
                         FROM users 
                         WHERE USER_TYPE = 'student' 
                         ORDER BY NAME";
        $fallback_stmt = $pdo->query($fallback_sql);
        $fallback_students = $fallback_stmt->fetchAll(PDO::FETCH_ASSOC);
        
        if (count($fallback_students) > 0) {
            echo json_encode(["status" => "success", "data" => $fallback_students]);
        } else {
            echo json_encode(["status" => "empty", "message" => "No students found in the database"]);
        }
    }
    
} catch (Exception $e) {
    // Log the error
    $errorLog = "[ERROR] " . $e->getMessage() . "\n";
    $errorLog .= "[TRACE] " . $e->getTraceAsString() . "\n";
    file_put_contents('debug_get_students.log', $errorLog, FILE_APPEND);
    
    // Return error response
    http_response_code(500);
    echo json_encode([
        "status" => "error", 
        "message" => "An error occurred while fetching students",
        "debug" => $e->getMessage()
    ]);
}
?>
