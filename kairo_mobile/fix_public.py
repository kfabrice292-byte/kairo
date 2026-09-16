import os

filepath = 'lib/screens/profile/public_profile_screen.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# We will just do a simple replacement for the network buttons logic
import re

# Remove `_handleNetworkAction`
content = re.sub(r'void _handleNetworkAction.*?^  }', '', content, flags=re.MULTILINE | re.DOTALL)

# Remove the network/connection logic in build
content = re.sub(r'final network = context.watch<NetworkProvider>\(\);.*?fgColor = Colors\.white;.*?}', '', content, flags=re.MULTILINE | re.DOTALL)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
print("Removed network logic from public profile")
