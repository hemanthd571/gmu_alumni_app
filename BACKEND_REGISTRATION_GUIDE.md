# Backend Registration Setup Required

## Problem
The registration is failing with a 500 Server Error because the backend `register.php` likely doesn't handle the new fields (`usn`, `batch`, `department`) or the database table `users` is missing these columns.

## Solution

### Step 1: Update Database Table
Run this SQL command in your phpMyAdmin or database tool to add the necessary columns to the `users` table:

```sql
ALTER TABLE `users`
ADD COLUMN `usn` VARCHAR(20) NULL,
ADD COLUMN `batch` VARCHAR(10) NULL,
ADD COLUMN `department` VARCHAR(100) NULL,
ADD COLUMN `is_approved` TINYINT(1) DEFAULT 0,
ADD COLUMN `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
```

### Step 2: Update register.php
Replace the content of `c:\xampp_ss\htdocs\alumni\api\auth\register.php` with the code below.

**File Location:** `c:\xampp_ss\htdocs\alumni\api\auth\register.php`

```php
<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once '../../config/database.php';

$data = json_decode(file_get_contents("php://input"));

if(
    !empty($data->name) &&
    !empty($data->email) &&
    !empty($data->password) &&
    !empty($data->usn)
){
    try {
        $database = new Database();
        $db = $database->getConnection();

        // Check if email already exists
        $check_query = "SELECT id FROM users WHERE email = ?";
        $check_stmt = $db->prepare($check_query);
        $check_stmt->bind_param("s", $data->email);
        $check_stmt->execute();
        if($check_stmt->get_result()->num_rows > 0){
            http_response_code(400);
            echo json_encode(["success" => false, "message" => "Email already exists."]);
            exit();
        }

        $query = "INSERT INTO users
                    (name, email, password, usn, department, batch, role, is_approved, created_at)
                  VALUES
                    (?, ?, ?, ?, ?, ?, 'alumni', 0, NOW())";

        $stmt = $db->prepare($query);

        // Sanitize
        $name = htmlspecialchars(strip_tags($data->name));
        $email = htmlspecialchars(strip_tags($data->email));
        $usn = htmlspecialchars(strip_tags($data->usn));
        $department = htmlspecialchars(strip_tags($data->department));
        $batch = htmlspecialchars(strip_tags($data->batch));
        
        // Hash password
        $password_hash = password_hash($data->password, PASSWORD_BCRYPT);

        $stmt->bind_param("ssssss", $name, $email, $password_hash, $usn, $department, $batch);

        if($stmt->execute()){
            http_response_code(201);
            echo json_encode(["success" => true, "message" => "User was created. Please wait for SPOC approval."]);
        } else {
            // Log the specific error for debugging
            error_log("Registration SQL Error: " . $stmt->error);
            http_response_code(503);
            echo json_encode(["success" => false, "message" => "Unable to create user. Data base error."]);
        }
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(["success" => false, "message" => "Server error: " . $e->getMessage()]);
    }
} else {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Unable to create user. Data is incomplete."]);
}
?>
```
