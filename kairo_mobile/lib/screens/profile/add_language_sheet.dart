import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kairo_mobile/core/providers/auth_provider.dart';
import 'package:kairo_mobile/core/models/user_model.dart';
import 'package:kairo_mobile/widgets/kairo_text_field.dart';
import 'package:kairo_mobile/core/theme/app_colors.dart';

class AddLanguageSheet extends StatefulWidget {
  final Language? languageToEdit;

  const AddLanguageSheet({super.key, this.languageToEdit});

  @override
  State<AddLanguageSheet> createState() => _AddLanguageSheetState();
}

class _AddLanguageSheetState extends State<AddLanguageSheet> {
  final _nameController = TextEditingController();
  int _level = 3;

  @override
  void initState() {
    super.initState();
    if (widget.languageToEdit != null) {
      _nameController.text = widget.languageToEdit!.name;
      _level = widget.languageToEdit!.level;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() async {
    if (_nameController.text.trim().isEmpty) return;

    final auth = context.read<AuthProvider>();
    final user = auth.userModel;
    if (user != null) {
      List<Language> languages = List.from(user.languages);
      if (widget.languageToEdit != null) {
        final index = languages.indexWhere((l) => l.name == widget.languageToEdit!.name);
        if (index != -1) {
          languages[index] = Language(name: _nameController.text.trim(), level: _level);
        }
      } else {
        languages.add(Language(name: _nameController.text.trim(), level: _level));
      }
      
      final languagesMapList = languages.map((l) => l.toMap()).toList();
      await auth.updateProfile({'languages': languagesMapList});
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
              Text(
                widget.languageToEdit == null ? 'Ajouter une langue' : 'Modifier la langue',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(icon: Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 24),
          KairoTextField(
            controller: _nameController,
            hintText: 'Langue (ex: Anglais, Français)', prefixIcon: PhosphorIcons.translate(),
          ),
          const SizedBox(height: 16),
          Text('Niveau ($_level/5)', style: TextStyle(fontWeight: FontWeight.w600)),
          Slider(
            value: _level.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            activeColor: AppColors.primary,
            onChanged: (val) => setState(() => _level = val.toInt()),
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
              child: Text('Enregistrer', style: TextStyle(color: Theme.of(context).cardColor)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
