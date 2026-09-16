import os
import re

# Fix profile_screen.dart
filepath = 'lib/screens/profile_screen.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    lines = f.readlines()

start_idx = -1
for i, line in enumerate(lines):
    if "_buildSection('À propos'" in line:
        start_idx = i - 2
        break

end_idx = -1
for i, line in enumerate(lines):
    if "class _EditProfileDialog" in line:
        end_idx = i
        break

if start_idx != -1 and end_idx != -1:
    closing = """                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

"""
    new_lines = lines[:start_idx] + [closing] + lines[end_idx:]
    with open(filepath, 'w', encoding='utf-8') as f:
        f.writelines(new_lines)
    print("Fixed profile_screen.dart")

# Fix public_profile_screen.dart
public_path = 'lib/screens/profile/public_profile_screen.dart'
with open(public_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Remove _handleNetworkAction completely
content = re.sub(r'void _handleNetworkAction.*?^  }', '', content, flags=re.MULTILINE | re.DOTALL)

# 2. Remove the network provider logic in build
# This replaces everything from `final network = ...` to `fgColor = Colors.white; }`
content = re.sub(r'final network = context\.watch<NetworkProvider>\(\);.*?fgColor = Colors\.white;\n    }', '', content, flags=re.MULTILINE | re.DOTALL)

# 3. Remove the ElevatedButton for network action
button_regex = r'if \(!isMe\)\s*SizedBox\(\s*width: double\.infinity,.*?ElevatedButton\.icon\(.*?onPressed: \(\) => _handleNetworkAction.*?,\s*\),\s*\),\s*const SizedBox\(height: 32\),'
content = re.sub(button_regex, '', content, flags=re.MULTILINE | re.DOTALL)

# 4. Remove FeedProvider logic (Consumer<FeedProvider> down to the end of that block)
feed_regex = r'Consumer<FeedProvider>\(.*?\)\s*,\s*const SizedBox\(height: 32\),'
content = re.sub(feed_regex, '', content, flags=re.MULTILINE | re.DOTALL)

with open(public_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Fixed public_profile_screen.dart")
