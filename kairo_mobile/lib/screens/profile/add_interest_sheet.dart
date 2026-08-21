import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kairo_mobile/core/providers/auth_provider.dart';
import 'package:kairo_mobile/widgets/kairo_text_field.dart';
import 'package:kairo_mobile/core/theme/app_colors.dart';

class AddInterestSheet extends StatefulWidget {
  const AddInterestSheet({super.key});

  @override
  State<AddInterestSheet> createState() => _AddInterestSheetState();
}

class _AddInterestSheetState extends State<AddInterestSheet> {
  final _controller = TextEditingController();

  void _save() async {
    if (_controller.text.trim().isEmpty) return;
    
    final newInterests = _controller.text.split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final auth = context.read<AuthProvider>();
    final user = auth.userModel;
    if (user != null) {
      final updatedInterests = List<String>.from(user.interests)..addAll(newInterests);
      await auth.updateProfile({'interests': updatedInterests});
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Ajouter des centres d\'intérêt', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(icon: Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 16),
          Text('Séparez-les par des virgules (ex: Lecture, Football, Musique)', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          KairoTextField(
            controller: _controller,
            hintText: 'Centres d\'intérêt', prefixIcon: PhosphorIcons.star(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text('Ajouter', style: TextStyle(color: Theme.of(context).cardColor)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
