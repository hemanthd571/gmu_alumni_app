import os
import re

api_dir = r"c:\xampp_ss\htdocs\alumni\gmu_alumni_app\api"

pattern = re.compile(r"\$configPath\s*=\s*'C:/xampp/htdocs/alumni/includes/db_config\.php';.*?require_once\s*\$configPath;", re.DOTALL)
replacement = r"require_once dirname(__DIR__, 3) . '/includes/db_config.php';"

for root, dirs, files in os.walk(api_dir):
    for f in files:
        if f.endswith('.php'):
            path = os.path.join(root, f)
            with open(path, 'r', encoding='utf-8') as file:
                content = file.read()
            
            new_content = pattern.sub(replacement, content)
            
            if new_content != content:
                with open(path, 'w', encoding='utf-8') as file:
                    file.write(new_content)
                print(f"Updated {path}")
