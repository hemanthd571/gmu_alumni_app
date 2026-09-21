<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');

require_once __DIR__ . '/../includes/db_config.php';

try {
    // Sample proud alumni data
    $proudAlumni = [
        [
            'id' => '1',
            'name' => 'Dr. Manjunatha Thondamal',
            'batch' => '2006 Output',
            'description' => 'Associate Professor at Department of Biotechnology, GST. He received his Ph.D. from the ENS de Lyon, France in 2014.',
            'image' => 'assets/images/proud/Manjunath.png'
        ],
        [
            'id' => '2',
            'name' => 'Dr. Anshu Alok',
            'batch' => '2009 Output',
            'description' => 'Postdoctoral researcher at the University of Minnesota, USA, working in plant molecular biology and biotechnology.',
            'image' => 'assets/images/proud/Anshu.png'
        ],
    ];

    echo json_encode([
        'success' => true,
        'data' => $proudAlumni
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Server error']);
}
?>

