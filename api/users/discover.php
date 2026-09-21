<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');

require_once __DIR__ . '/../includes/db_config.php';

try {
    $search = isset($_GET['search']) ? $_GET['search'] : '';
    $limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 100;
    $offset = isset($_GET['offset']) ? (int)$_GET['offset'] : 0;
    
    $query = "SELECT id, name, usn, email_id as email, phone_number as phone, year_of_graduation as batch, branch as department, profile_picture
              FROM users
              WHERE is_active = 1";
    
    if (!empty($search)) {
        $query .= " AND (name LIKE :search OR usn LIKE :search2 OR email_id LIKE :search3)";
    }
    
    $query .= " ORDER BY name ASC";

    $stmt = $pdo->prepare($query);
    
    if (!empty($search)) {
        $searchParam = '%' . $search . '%';
        $stmt->bindParam(":search", $searchParam);
        $stmt->bindParam(":search2", $searchParam);
        $stmt->bindParam(":search3", $searchParam);
    }
    
    $stmt->execute();

    $users = [];
    while($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        $users[] = [
            'id' => (int)$row['id'],
            'name' => $row['name'],
            'usn' => $row['usn'],
            'email' => $row['email'],
            'phone' => $row['phone'],
            'batch' => $row['batch'],
            'department' => $row['department'],
            'profile_picture' => $row['profile_picture'] ?: 'default.jpg'
        ];
    }

    echo json_encode([
        'success' => true,
        'data' => $users
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Server error: ' . $e->getMessage()]);
}
?>

