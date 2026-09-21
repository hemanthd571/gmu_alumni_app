<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');

require_once __DIR__ . '/../includes/db_config.php';

try {
    // Sample core team data - you can create a core_team table in database
    $coreTeam = [
        [
            'id' => '1',
            'name' => 'Dr. Rajesh Kumar',
            'position' => 'President',
            'image' => null,
            'email' => 'rajesh@example.com',
            'phone' => null
        ],
        [
            'id' => '2',
            'name' => 'Priya Sharma',
            'position' => 'Vice President',
            'image' => null,
            'email' => 'priya@example.com',
            'phone' => null
        ],
        [
            'id' => '3',
            'name' => 'Amit Patel',
            'position' => 'Secretary',
            'image' => null,
            'email' => 'amit@example.com',
            'phone' => null
        ],
        [
            'id' => '4',
            'name' => 'Sneha Reddy',
            'position' => 'Treasurer',
            'image' => null,
            'email' => 'sneha@example.com',
            'phone' => null
        ],
        [
            'id' => '5',
            'name' => 'Vikram Singh',
            'position' => 'Events Coordinator',
            'image' => null,
            'email' => 'vikram@example.com',
            'phone' => null
        ],
        [
            'id' => '6',
            'name' => 'Anita Desai',
            'position' => 'Communications Head',
            'image' => null,
            'email' => 'anita@example.com',
            'phone' => null
        ],
    ];

    echo json_encode([
        'success' => true,
        'data' => $coreTeam
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Server error']);
}
?>

