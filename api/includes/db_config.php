<?php
// Universal Database configuration (Supports Production & Local XAMPP)

$connectionAttempts = [
    // 1. Production Database Credentials
    [
        'host' => 'localhost',
        'port' => '3306',
        'dbname' => 'alumni',
        'user' => 'alumni',
        'pass' => '<$ecure@ccess@alumni>'
    ],
    // 2. Local XAMPP Default (root / no password)
    [
        'host' => '127.0.0.1',
        'port' => '3306',
        'dbname' => 'alumni',
        'user' => 'root',
        'pass' => ''
    ],
    // 3. Local XAMPP with common password
    [
        'host' => '127.0.0.1',
        'port' => '3306',
        'dbname' => 'alumni',
        'user' => 'root',
        'pass' => '1234'
    ],
];

foreach ($connectionAttempts as $attempt) {
    try {
        $pdo = new PDO(
            "mysql:host={$attempt['host']};port={$attempt['port']};dbname={$attempt['dbname']};charset=utf8mb4",
            $attempt['user'],
            $attempt['pass'],
            [
                PDO::ATTR_TIMEOUT => 2,
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC
            ]
        );
        
        // Test connection
        $pdo->query("SELECT 1");
        break; // Success

    } catch(PDOException $e) {
        continue; // Try next fallback
    }
}

if (!isset($pdo)) {
    die("All database connection attempts failed. Please check MySQL configuration.");
}

function isLoggedIn() {
    return isset($_SESSION['user_id']);
}

function getCurrentUser() {
    if (!isLoggedIn()) {
        return null;
    }

    global $pdo;
    $stmt = $pdo->prepare("SELECT * FROM users WHERE id = ?");
    $stmt->execute([$_SESSION['user_id']]);
    return $stmt->fetch();
}

function requireLogin() {
    if (!isLoggedIn()) {
        header("Location: /alumni/login.php");
        exit();
    }
}

function redirectIfLoggedIn() {
    if (isLoggedIn()) {
        header("Location: /alumni/index.php");
        exit();
    }
}
?>
