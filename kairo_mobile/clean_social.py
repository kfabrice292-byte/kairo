import os
import re

public_path = 'lib/screens/profile/public_profile_screen.dart'
with open(public_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Remove imports
content = re.sub(r"import '../../core/providers/network_provider.dart';\n", "", content)
content = re.sub(r"import '../../core/providers/feed_provider.dart';\n", "", content)
content = re.sub(r"import '../../core/providers/chat_provider.dart';\n", "", content)
content = re.sub(r"import '../feed_screen.dart';\n", "", content)

# Remove _handleNetworkAction
content = re.sub(r"  void _handleNetworkAction.*?^  }", "", content, flags=re.MULTILINE | re.DOTALL)

# Remove NetworkProvider assignments and usage in build
# This removes from "final network =" to "fgColor = Colors.white;\n    }"
content = re.sub(r"    final network = context.watch<NetworkProvider>\(\);.*?fgColor = Colors\.white;\n    }", "", content, flags=re.MULTILINE | re.DOTALL)

# Remove the Network action button
# Note: we need to handle the whole `if (!isMe)` block
button_regex = r"            if \(!isMe\)\n              SizedBox\(\n                width: double\.infinity,.*?const SizedBox\(height: 32\),"
content = re.sub(button_regex, "            const SizedBox(height: 32),", content, flags=re.MULTILINE | re.DOTALL)

# Remove FeedProvider usage (the Posts section)
feed_regex = r"            if \(_user!\.posts\.isNotEmpty \? true : false\).*?const SizedBox\(height: 24\),\n            \],"
content = re.sub(feed_regex, "", content, flags=re.MULTILINE | re.DOTALL)

# Actually, the posts section might not be conditioned that way. Let's just remove the word "FeedProvider" to see if it still compiles, or better yet, remove the whole Consumer<FeedProvider> block.
feed_consumer = r"            Consumer<FeedProvider>\(.*?},\n            \),"
content = re.sub(feed_consumer, "", content, flags=re.MULTILINE | re.DOTALL)

with open(public_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Cleaned public_profile_screen.dart")

# Now notifications_screen.dart
notif_path = 'lib/screens/notifications/notifications_screen.dart'
with open(notif_path, 'r', encoding='utf-8') as f:
    notif_content = f.read()

notif_content = re.sub(r"import '../../core/providers/network_provider.dart';\n", "", notif_content)
# Remove network provider usages inside build
notif_content = re.sub(r"                final networkProvider = context.watch<NetworkProvider>\(\);\n", "", notif_content)
notif_content = re.sub(r"      final network = context.read<NetworkProvider>\(\);\n", "", notif_content)

with open(notif_path, 'w', encoding='utf-8') as f:
    f.write(notif_content)
print("Cleaned notifications_screen.dart")

# chat_detail_screen.dart
chat_path = 'lib/screens/chat/chat_detail_screen.dart'
with open(chat_path, 'r', encoding='utf-8') as f:
    chat_content = f.read()

chat_content = re.sub(r"import '../../core/providers/network_provider.dart';\n", "", chat_content)
chat_content = re.sub(r"    final network = context.watch<NetworkProvider>\(\);\n", "", chat_content)

with open(chat_path, 'w', encoding='utf-8') as f:
    f.write(chat_content)
print("Cleaned chat_detail_screen.dart")

# connection_card.dart (replace with an empty widget or comment out)
conn_path = 'lib/widgets/connection_card.dart'
with open(conn_path, 'w', encoding='utf-8') as f:
    f.write("""import 'package:flutter/material.dart';
import '../core/models/user_model.dart';

class ConnectionCard extends StatelessWidget {
  final UserModel user;

  const ConnectionCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
""")
print("Cleaned connection_card.dart")

