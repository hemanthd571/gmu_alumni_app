import os
import re

api_dir = r"c:\xampp_ss\htdocs\alumni\gmu_alumni_app\api"

for root, dirs, files in os.walk(api_dir):
    # skip the new includes directory itself
    if os.path.basename(root) == 'includes':
        continue

    for f in files:
        if f.endswith('.php'):
            path = os.path.join(root, f)
            with open(path, 'r', encoding='utf-8') as file:
                content = file.read()
            
            # calculate relative __DIR__ based path
            rel_dir = os.path.relpath(root, api_dir)
            if rel_dir == '.':
                req_str = "require_once __DIR__ . '/includes/db_config.php';"
            else:
                depth = len(rel_dir.split(os.sep))
                req_str = "require_once __DIR__ . '/" + ("../" * depth) + "includes/db_config.php';"
            
            # Replace various existing includes
            new_content = re.sub(r"require_once\s+dirname\(__DIR__,\s*3\)\s*\.\s*['\"]/includes/db_config\.php['\"];", req_str, content)
            new_content = re.sub(r"require_once\s+['\"]\.\./includes/db_config\.php['\"];", req_str, new_content)
            
            config_block_pattern = re.compile(
                r"\$configPath\s*=\s*'[^']+db_config\.php';\s*"
                r"(?:if\s*\(!file_exists\(\$configPath\)\)\s*\{[^}]+\}\s*)?"
                r"require_once\s*\$configPath;", 
                re.MULTILINE
            )
            new_content = config_block_pattern.sub(req_str, new_content)
            
            complex_block = re.search(r"// Try multiple possible config paths.*?require_once\s+\$configPath;", new_content, re.DOTALL)
            if complex_block:
                new_content = new_content[:complex_block.start()] + req_str + new_content[complex_block.end():]

            
            if new_content != content:
                with open(path, 'w', encoding='utf-8') as file:
                    file.write(new_content)
                print(f"Updated {path}")
