<?php
$ch = curl_init('http://localhost/alumni/api/director/get_feedback.php?user_id=22');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
$response = curl_exec($ch);
echo $response;
?>
