<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');

require_once __DIR__ . '/../includes/db_config.php';

try {
    $query = "SELECT id, name, usn, latitude, longitude, year_of_graduation as batch, branch as department
              FROM users
              WHERE is_active = 1 AND latitude IS NOT NULL AND longitude IS NOT NULL
              ORDER BY name ASC";

    $stmt = $pdo->prepare($query);
    $stmt->execute();

    $alumni = [];
    while($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        $alumni[] = [
            'id' => (int)$row['id'],
            'name' => $row['name'],
            'usn' => $row['usn'],
            'latitude' => (float)$row['latitude'],
            'longitude' => (float)$row['longitude'],
            'batch' => $row['batch'],
            'department' => $row['department']
        ];
    }

    echo json_encode([
        'success' => true,
        'data' => $alumni,
        'count' => count($alumni)
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Server error: ' . $e->getMessage()]);
}
?>

