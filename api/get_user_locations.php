<?php
header('Content-Type: application/json');
require_once __DIR__ . '/includes/db_config.php';

// Enable error reporting for debugging
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Function to get the base URL
function getBaseUrl() {
    $protocol = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
    return $protocol . '://' . $_SERVER['HTTP_HOST'];
}

try {
    // First, check if profile_visibility column exists
    $checkColumn = $pdo->query("SHOW COLUMNS FROM users LIKE 'profile_visibility'");
    $hasVisibility = $checkColumn->rowCount() > 0;
    
    // Build the base query
    $query = "
        SELECT 
            u.id,
            u.name,
            u.profile_picture,
            u.usn,
            u.latitude,
            u.longitude
        FROM users u
        WHERE u.latitude IS NOT NULL 
        AND u.longitude IS NOT NULL
        ";
    
    // Add profile visibility check if the column exists
    if ($hasVisibility) {
        $query .= " AND (u.profile_visibility = 1)";
    }
    
    $query .= " ORDER BY u.name ASC";
    
    $stmt = $pdo->query($query);
    $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // If no users found with separate lat/lng, try with POINT location
    if (empty($users)) {
        $query = "
            SELECT 
                u.id,
                u.name,
                u.profile_picture,
                u.usn,
                X(u.location) as latitude,
                Y(u.location) as longitude
            FROM users u
            WHERE u.location IS NOT NULL
        ";
        
        // Add profile visibility check if the column exists
        if ($hasVisibility) {
            $query .= " AND (u.profile_visibility = 1)";
        }
        
        $query .= " ORDER BY u.name ASC";
        
        $stmt = $pdo->query($query);
        $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
    
    // Process profile picture URLs
    $baseUrl = getBaseUrl();
    $processedUsers = [];
    
    foreach ($users as $user) {
        // Skip if no valid coordinates
        if (empty($user['latitude']) || empty($user['longitude'])) {
            continue;
        }
        
        // Process profile picture
        $profilePicture = '';
        if (!empty($user['profile_picture'])) {
            if (filter_var($user['profile_picture'], FILTER_VALIDATE_URL)) {
                $profilePicture = $user['profile_picture'];
            } else {
                // Remove any leading slashes to prevent double slashes
                $picturePath = ltrim($user['profile_picture'], '/');
                // Check if the path already contains 'alumni' to avoid duplication
                if (strpos($picturePath, 'alumni/') === 0) {
                    $profilePicture = $baseUrl . '/' . $picturePath;
                } else {
                    $profilePicture = $baseUrl . '/alumni/' . $picturePath;
                }
            }
        } else {
            $profilePicture = $baseUrl . '/alumni/assets/images/default-avatar.png';
        }
        
        $processedUsers[] = [
            'id' => $user['id'],
            'name' => $user['name'],
            'usn' => $user['usn'] ?? '',
            'profile_picture' => $profilePicture,
            'latitude' => (float)$user['latitude'],
            'longitude' => (float)$user['longitude']
        ];
    }
    
    echo json_encode([
        'success' => true,
        'users' => $processedUsers
    ], JSON_PRETTY_PRINT);
    
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Database error: ' . $e->getMessage(),
        'trace' => $e->getTraceAsString()
    ], JSON_PRETTY_PRINT);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error: ' . $e->getMessage()
    ]);
}
