# Backend Implementation Guide for Follow Feature

## Database Table Required

Create a `follows` table in your MySQL database:

```sql
CREATE TABLE IF NOT EXISTS `follows` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `follower_id` int(11) NOT NULL,
  `following_id` int(11) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_follow` (`follower_id`, `following_id`),
  KEY `follower_id` (`follower_id`),
  KEY `following_id` (`following_id`),
  FOREIGN KEY (`follower_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`following_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

## Backend API Endpoints Required

Create these PHP files in `c:\xampp_ss\htdocs\alumni\follows\`:

### 1. follow.php - Toggle Follow/Unfollow

```php
<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once '../config/database.php';

$input = json_decode(file_get_contents('php://input'), true);

if (!isset($input['follower_id']) || !isset($input['following_id'])) {
    echo json_encode([
        'success' => false,
        'message' => 'Missing required fields'
    ]);
    exit();
}

$follower_id = intval($input['follower_id']);
$following_id = intval($input['following_id']);

if ($follower_id === $following_id) {
    echo json_encode([
        'success' => false,
        'message' => 'You cannot follow yourself'
    ]);
    exit();
}

try {
    $database = new Database();
    $conn = $database->getConnection();

    // Check if already following
    $check_query = "SELECT id FROM follows WHERE follower_id = ? AND following_id = ?";
    $check_stmt = $conn->prepare($check_query);
    $check_stmt->bind_param("ii", $follower_id, $following_id);
    $check_stmt->execute();
    $result = $check_stmt->get_result();

    if ($result->num_rows > 0) {
        // Already following - unfollow
        $delete_query = "DELETE FROM follows WHERE follower_id = ? AND following_id = ?";
        $delete_stmt = $conn->prepare($delete_query);
        $delete_stmt->bind_param("ii", $follower_id, $following_id);
        
        if ($delete_stmt->execute()) {
            echo json_encode([
                'success' => true,
                'message' => 'Unfollowed successfully',
                'is_following' => false
            ]);
        } else {
            throw new Exception('Failed to unfollow');
        }
    } else {
        // Not following - follow
        $insert_query = "INSERT INTO follows (follower_id, following_id, created_at) VALUES (?, ?, NOW())";
        $insert_stmt = $conn->prepare($insert_query);
        $insert_stmt->bind_param("ii", $follower_id, $following_id);
        
        if ($insert_stmt->execute()) {
            echo json_encode([
                'success' => true,
                'message' => 'Followed successfully',
                'is_following' => true
            ]);
        } else {
            throw new Exception('Failed to follow');
        }
    }

} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => 'Error: ' . $e->getMessage()
    ]);
}
?>
```

### 2. following.php - Get Following List

```php
<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

require_once '../config/database.php';

if (!isset($_GET['user_id'])) {
    echo json_encode([
        'success' => false,
        'message' => 'User ID required'
    ]);
    exit();
}

$user_id = intval($_GET['user_id']);

try {
    $database = new Database();
    $conn = $database->getConnection();

    $query = "SELECT following_id FROM follows WHERE follower_id = ?";
    $stmt = $conn->prepare($query);
    $stmt->bind_param("i", $user_id);
    $stmt->execute();
    $result = $stmt->get_result();

    $following = [];
    while ($row = $result->fetch_assoc()) {
        $following[] = $row;
    }

    echo json_encode([
        'success' => true,
        'data' => $following
    ]);

} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => 'Error: ' . $e->getMessage()
    ]);
}
?>
```

### 3. check.php - Check Follow Status

```php
<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

require_once '../config/database.php';

if (!isset($_GET['follower_id']) || !isset($_GET['following_id'])) {
    echo json_encode([
        'success' => false,
        'is_following' => false
    ]);
    exit();
}

$follower_id = intval($_GET['follower_id']);
$following_id = intval($_GET['following_id']);

try {
    $database = new Database();
    $conn = $database->getConnection();

    $query = "SELECT id FROM follows WHERE follower_id = ? AND following_id = ?";
    $stmt = $conn->prepare($query);
    $stmt->bind_param("ii", $follower_id, $following_id);
    $stmt->execute();
    $result = $stmt->get_result();

    echo json_encode([
        'success' => true,
        'is_following' => $result->num_rows > 0
    ]);

} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'is_following' => false
    ]);
}
?>
```

## What Has Been Implemented in Flutter

1. **FollowService** (`lib/services/follow_service.dart`):
   - `toggleFollow()` - Calls `/follows/follow.php` to follow/unfollow
   - `getFollowingList()` - Calls `/follows/following.php` to get all users being followed
   - `isFollowing()` - Calls `/follows/check.php` to check individual follow status

2. **UserDiscoveryScreen** Updates:
   - Loads following list on screen init
   - Filters out directors and SPOCs from the alumni list
   - Shows "Follow" button for users not followed
   - Shows "Message" icon for users already followed
   - Persists follow actions to backend via API
   - Handles errors and shows appropriate feedback

3. **UserModel** Updates:
   - Added `isFollowed` boolean field to track follow status

## Testing Steps

1. Create the `follows` table in your database
2. Create the three PHP files in `c:\xampp_ss\htdocs\alumni\follows\`
3. Restart your Flutter app
4. Navigate to "Connect with Alumni"
5. Click "Follow" on a user - it should save to the database
6. Restart the app - the follow status should persist
7. Click the message icon to open chat with followed users
