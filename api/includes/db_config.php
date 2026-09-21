<?php
// Database configuration with multiple fallback options
$host = '127.0.0.1';
$dbname = 'alumni';
$username = 'root';
$password = '';

$connectionAttempts = [
    // Try without password first (XAMPP default)
    ['host' => $host, 'user' => $username, 'pass' => $password],
    // Try with common XAMPP passwords
    ['host' => $host, 'user' => $username, 'pass' => '1234'],
    ['host' => $host, 'user' => $username, 'pass' => 'password'],
    ['host' => $host, 'user' => $username, 'pass' => '123456'],
];

foreach ($connectionAttempts as $attempt) {
    try {
        $pdo = new PDO("mysql:host={$attempt['host']};dbname=$dbname;charset=utf8mb4", $attempt['user'], $attempt['pass'], [
            PDO::ATTR_TIMEOUT => 3,
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC
        ]);
        
        // Test the connection
        $pdo->query("SELECT 1");
        break; // Success, exit the loop

    } catch(PDOException $e) {
        if ($e->getCode() == 1045) {
            // Access denied, try next attempt
            continue;
        } else {
            // Other error, re-throw
            throw $e;
        }
    }
}

// If we get here without a successful connection, show error
if (!isset($pdo)) {
    die("All database connection attempts failed. Please ensure XAMPP MySQL is running and configured correctly.");
}

// Helper function to check if user is logged in
function isLoggedIn() {
    return isset($_SESSION['user_id']);
}

// Helper function to get current user data
function getCurrentUser() {
    if (!isLoggedIn()) {
        return null;
    }

    global $pdo;
    $stmt = $pdo->prepare("SELECT * FROM users WHERE id = ?");
    $stmt->execute([$_SESSION['user_id']]);
    return $stmt->fetch();
}

// Helper function to redirect if not logged in
function requireLogin() {
    if (!isLoggedIn()) {
        header("Location: /alumni/login.php");
        exit();
    }
}

// Helper function to redirect if logged in (for login page)
function redirectIfLoggedIn() {
    if (isLoggedIn()) {
        header("Location: /alumni/index.php");
        exit();
    }
}
?>
