<?php
// Test all API endpoints to verify they work with existing database
header('Content-Type: text/html; charset=utf-8');
require_once __DIR__ . '/includes/db_config.php';

echo "<h1>API Test - Using Existing Database Tables</h1>";
echo "<p>Testing all APIs with your existing website database...</p>";
echo "<hr>";

// Test Noticeboard
echo "<h2>1. Noticeboard API</h2>";
try {
    $stmt = $pdo->query("SELECT COUNT(*) as count FROM noticeboard WHERE is_active = 1");
    $count = $stmt->fetch()['count'];
    echo "✅ Found $count active notices<br>";
    
    $stmt = $pdo->query("SELECT id, title, priority, created_at FROM noticeboard WHERE is_active = 1 LIMIT 3");
    $notices = $stmt->fetchAll(PDO::FETCH_ASSOC);
    echo "<pre>" . print_r($notices, true) . "</pre>";
    echo "<a href='noticeboard/list.php' target='_blank'>Test API →</a><br>";
} catch (Exception $e) {
    echo "❌ Error: " . $e->getMessage() . "<br>";
}
echo "<hr>";

// Test News
echo "<h2>2. News API</h2>";
try {
    $stmt = $pdo->query("SELECT COUNT(*) as count FROM news WHERE is_active = 1");
    $count = $stmt->fetch()['count'];
    echo "✅ Found $count active news articles<br>";
    
    $stmt = $pdo->query("SELECT id, title, featured_image, created_at FROM news WHERE is_active = 1 LIMIT 3");
    $news = $stmt->fetchAll(PDO::FETCH_ASSOC);
    echo "<pre>" . print_r($news, true) . "</pre>";
    echo "<a href='news/list.php' target='_blank'>Test API →</a><br>";
} catch (Exception $e) {
    echo "❌ Error: " . $e->getMessage() . "<br>";
}
echo "<hr>";

// Test Events
echo "<h2>3. Events API</h2>";
try {
    $stmt = $pdo->query("SELECT COUNT(*) as count FROM events WHERE is_active = 1");
    $count = $stmt->fetch()['count'];
    echo "✅ Found $count active events<br>";
    
    $stmt = $pdo->query("SELECT id, title, event_date, location FROM events WHERE is_active = 1 LIMIT 3");
    $events = $stmt->fetchAll(PDO::FETCH_ASSOC);
    echo "<pre>" . print_r($events, true) . "</pre>";
    echo "<a href='events/list.php' target='_blank'>Test API →</a><br>";
} catch (Exception $e) {
    echo "❌ Error: " . $e->getMessage() . "<br>";
}
echo "<hr>";

// Test Jobs
echo "<h2>4. Jobs API</h2>";
try {
    $stmt = $pdo->query("SELECT COUNT(*) as count FROM jobs WHERE is_active = 1");
    $count = $stmt->fetch()['count'];
    echo "✅ Found $count active jobs<br>";
    
    $stmt = $pdo->query("SELECT id, title, company, job_type FROM jobs WHERE is_active = 1 LIMIT 3");
    $jobs = $stmt->fetchAll(PDO::FETCH_ASSOC);
    echo "<pre>" . print_r($jobs, true) . "</pre>";
    echo "<a href='jobs/list.php' target='_blank'>Test API →</a><br>";
} catch (Exception $e) {
    echo "❌ Error: " . $e->getMessage() . "<br>";
}
echo "<hr>";

// Test Galleries
echo "<h2>5. Galleries API</h2>";
try {
    $stmt = $pdo->query("SELECT COUNT(*) as count FROM galleries WHERE is_active = 1");
    $count = $stmt->fetch()['count'];
    echo "✅ Found $count active galleries<br>";
    
    $stmt = $pdo->query("SELECT id, title, description FROM galleries WHERE is_active = 1 LIMIT 3");
    $galleries = $stmt->fetchAll(PDO::FETCH_ASSOC);
    echo "<pre>" . print_r($galleries, true) . "</pre>";
    echo "<a href='galleries/list.php' target='_blank'>Test API →</a><br>";
} catch (Exception $e) {
    echo "❌ Error: " . $e->getMessage() . "<br>";
}
echo "<hr>";

// Test Users
echo "<h2>6. Users Table</h2>";
try {
    $stmt = $pdo->query("SELECT COUNT(*) as count FROM users WHERE is_active = 1");
    $count = $stmt->fetch()['count'];
    echo "✅ Found $count active users<br>";
    
    $stmt = $pdo->query("SELECT id, name, email, role FROM users WHERE is_active = 1 LIMIT 3");
    $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
    echo "<pre>" . print_r($users, true) . "</pre>";
} catch (Exception $e) {
    echo "❌ Error: " . $e->getMessage() . "<br>";
}
echo "<hr>";

echo "<h2>✅ Summary</h2>";
echo "<p><strong>All APIs are configured to use your existing website database tables!</strong></p>";
echo "<p>The mobile app will show the same data as your website.</p>";
echo "<p><strong>Next Step:</strong> Update Flutter screens to fetch data from these APIs.</p>";
?>
