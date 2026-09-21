<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');

require_once __DIR__ . '/../includes/db_config.php';

try {
    $stmt = $pdo->query("
        SELECT id, title, company, description, location, job_type, experience_level,
               CONCAT(COALESCE(salary_min, ''), ' - ', COALESCE(salary_max, '')) as salary, 
               application_link, created_at 
        FROM jobs 
        WHERE is_active = 1 AND is_approved = 1
        ORDER BY created_at DESC
    ");
    
    $jobs = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        'success' => true,
        'data' => $jobs
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Server error: ' . $e->getMessage()]);
}
?>

