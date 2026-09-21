# URGENT: Backend Files Missing - Follow Feature Not Working

## Problem
The app is trying to call these endpoints but getting 404 errors:
- `http://172.21.83.139:90/alumni/api/follows/follow.php` - **404 NOT FOUND**
- `http://172.21.83.139:90/alumni/api/follows/following.php` - **404 NOT FOUND**

## Solution: Create Backend Files

### Step 1: Create Database Table

Run this SQL in your MySQL database (phpMyAdmin or MySQL Workbench):

```sql
CREATE TABLE IF NOT EXISTS `follows` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `follower_id` int(11) NOT NULL COMMENT 'User who is following',
  `following_id` int(11) NOT NULL COMMENT 'User being followed',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_follow` (`follower_id`, `following_id`),
  KEY `follower_id` (`follower_id`),
  KEY `following_id` (`following_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

### Step 2: Create Backend Directory

Create folder: `c:\xampp_ss\htdocs\alumni\api\follows\`

### Step 3: Create follow.php

**File location:** `c:\xampp_ss\htdocs\alumni\api\follows\follow.php`

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

require_once '../../config/database.php';

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

### Step 4: Create following.php

**File location:** `c:\xampp_ss\htdocs\alumni\api\follows\following.php`

```php
<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

require_once '../../config/database.php';

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

### Step 5: Create check.php

**File location:** `c:\xampp_ss\htdocs\alumni\api\follows\check.php`

```php
<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

require_once '../../config/database.php';

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

## Testing After Setup

1. Create the `follows` table in your database
2. Create the three PHP files in `c:\xampp_ss\htdocs\alumni\api\follows\`
3. Restart your Flutter app
4. Go to "Connect with Alumni"
5. Click "Follow" on a user
6. Check your database - you should see a new row in the `follows` table
7. The message icon should now appear and persist even after restarting the app

## Verification

Test the endpoint directly in your browser:
- `http://172.21.83.139:90/alumni/api/follows/following.php?user_id=19`

You should see JSON response, not a 404 error.
