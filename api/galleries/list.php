<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');

require_once __DIR__ . '/../includes/db_config.php';

try {
    // Check if gallery_images table exists
    $tableCheck = $pdo->query("SHOW TABLES LIKE 'gallery_images'");
    $hasGalleryImages = $tableCheck->rowCount() > 0;
    
    if ($hasGalleryImages) {
        $stmt = $pdo->query("
            SELECT 
                g.id,
                g.title as name,
                g.description,
                (SELECT image_path FROM gallery_images WHERE gallery_id = g.id LIMIT 1) as cover_image,
                g.created_at,
                (SELECT COUNT(*) FROM gallery_images WHERE gallery_id = g.id) as image_count
            FROM galleries g
            WHERE g.is_active = 1
            ORDER BY g.created_at DESC
        ");
    } else {
        // Fallback if gallery_images doesn't exist
        $stmt = $pdo->query("
            SELECT 
                g.id,
                g.title as name,
                g.description,
                NULL as cover_image,
                g.created_at,
                0 as image_count
            FROM galleries g
            WHERE g.is_active = 1
            ORDER BY g.created_at DESC
        ");
    }
    
    $galleries = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        'success' => true,
        'data' => $galleries
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Server error: ' . $e->getMessage()]);
}
?>

