<?php
// Add these at the very top for debugging
error_reporting(E_ALL);
ini_set('display_errors', 1);
ini_set('log_errors', 1);
ini_set('error_log', '/var/log/php_errors.log');

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');

// Wrap everything in try-catch to catch all errors
try {
    require_once __DIR__ . '/../includes/db_config.php';

    // Check if PDO connection exists
    if (!isset($pdo)) {
        throw new Exception('PDO connection not established');
    }

    // Fetch all SPOCs (users with is_spoc = 1)
    $query = "SELECT 
                id,
                name,
                email_id as email,
                phone_number as phone,
                institute,
                branch,
                usn,
                profile_picture,
                created_at
              FROM users 
              WHERE is_spoc = 1 
              ORDER BY name ASC";
    
    $stmt = $pdo->prepare($query);
    $stmt->execute();
    $spocs = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Map data to ensure consistent format
    $mappedSpocs = [];
    foreach ($spocs as $spoc) {
        $mappedSpocs[] = [
            'id' => (int)$spoc['id'],
            'name' => $spoc['name'],
            'email' => $spoc['email'],
            'phone' => $spoc['phone'] ?? '',
            'institute' => $spoc['institute'] ?? '',
            'branch' => $spoc['branch'] ?? '',
            'usn' => $spoc['usn'] ?? '',
            'profile_picture' => $spoc['profile_picture'] ?? 'default.jpg',
            'created_at' => $spoc['created_at']
        ];
    }

    echo json_encode([
        'success' => true,
        'data' => $mappedSpocs,
        'count' => count($mappedSpocs)
    ]);

} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false, 
        'message' => 'Database error',
        'error' => $e->getMessage(),
        'trace' => $e->getTraceAsString()
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false, 
        'message' => 'Server error',
        'error' => $e->getMessage(),
        'trace' => $e->getTraceAsString()
    ]);
}
?>
