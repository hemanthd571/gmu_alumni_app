<?php
$_SERVER['REQUEST_METHOD'] = 'GET';
$_GET['user_id'] = '38'; 
ob_start();
include 'c:/Users/HEMANTH D/Downloads/gmu_alumni_app/gmu_alumni_app/api/alumni/get_registered_events.php';
$output = ob_get_clean();
echo $output;
?>
