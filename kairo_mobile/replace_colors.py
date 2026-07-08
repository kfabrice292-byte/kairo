import os
import glob

def refactor_colors():
    base_dir = r"c:\Users\HP ZBOOK\Downloads\KAIRO\kairo_mobile\lib"
    dart_files = glob.glob(os.path.join(base_dir, "**", "*.dart"), recursive=True)
    
    for file_path in dart_files:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
            
        if 'Color(0xFFF97316)' in content or 'const Color(0xFFF97316)' in content:
            # We must be careful about const. AppColors.primary is const, so we can replace 'const Color(0xFFF97316)' with 'AppColors.primary'.
            content = content.replace('const Color(0xFFF97316)', 'AppColors.primary')
            content = content.replace('Color(0xFFF97316)', 'AppColors.primary')
            
            # We also need to import app_colors.dart
            # Let's find the package path or relative path
            # Instead of figuring out relative, we use the package import
            import_statement = "import 'package:kairo_mobile/core/theme/app_colors.dart';\n"
            
            # Put import after the last import
            if import_statement not in content and 'AppColors.primary' in content:
                # Find last import
                lines = content.split('\n')
                last_import_idx = -1
                for i, line in enumerate(lines):
                    if line.startswith('import '):
                        last_import_idx = i
                
                if last_import_idx != -1:
                    lines.insert(last_import_idx + 1, import_statement.strip())
                else:
                    lines.insert(0, import_statement.strip())
                
                content = '\n'.join(lines)
                
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)

if __name__ == '__main__':
    refactor_colors()
