import os
import glob
import re

def refactor_colors():
    base_dir = r"c:\Users\HP ZBOOK\Downloads\KAIRO\kairo_mobile\lib"
    dart_files = glob.glob(os.path.join(base_dir, "**", "*.dart"), recursive=True)
    
    replacements = {
        r'const Color\(0xFFF97316\)': 'AppColors.primary',
        r'Color\(0xFFF97316\)': 'AppColors.primary',
        r'const Color\(0xFFFFF7ED\)': 'AppColors.primaryLight',
        r'Color\(0xFFFFF7ED\)': 'AppColors.primaryLight',
        r'const Color\(0xFF1E293B\)': 'AppColors.secondary',
        r'Color\(0xFF1E293B\)': 'AppColors.secondary',
        r'const Color\(0xFFFAFAFA\)': 'AppColors.background',
        r'Color\(0xFFFAFAFA\)': 'AppColors.background',
        r'const Color\(0xFF1F2937\)': 'AppColors.textPrimary',
        r'Color\(0xFF1F2937\)': 'AppColors.textPrimary',
        r'const Color\(0xFF6B7280\)': 'AppColors.textSecondary',
        r'Color\(0xFF6B7280\)': 'AppColors.textSecondary',
        r'const Color\(0xFF10B981\)': 'AppColors.success',
        r'Color\(0xFF10B981\)': 'AppColors.success',
        r'const Color\(0xFFEF4444\)': 'AppColors.error',
        r'Color\(0xFFEF4444\)': 'AppColors.error',
        r'const Color\(0xFFF59E0B\)': 'AppColors.warning',
        r'Color\(0xFFF59E0B\)': 'AppColors.warning',
    }
    
    for file_path in dart_files:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
            
        original_content = content
        
        for pattern, replacement in replacements.items():
            content = re.sub(pattern, replacement, content)
            
        if content != original_content:
            import_statement = "import 'package:kairo_mobile/core/theme/app_colors.dart';"
            if import_statement not in content and 'AppColors.' in content:
                # Insert import statement after the last import
                lines = content.split('\n')
                last_import_idx = -1
                for i, line in enumerate(lines):
                    if line.startswith('import '):
                        last_import_idx = i
                
                if last_import_idx != -1:
                    lines.insert(last_import_idx + 1, import_statement)
                else:
                    lines.insert(0, import_statement)
                
                content = '\n'.join(lines)
                
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)

if __name__ == '__main__':
    refactor_colors()
