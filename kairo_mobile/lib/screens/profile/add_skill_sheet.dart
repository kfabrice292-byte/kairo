import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/models/user_model.dart';
import 'package:kairo_mobile/core/theme/app_colors.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class AddSkillSheet extends StatefulWidget {
  final UserModel user;
  final Skill? initialSkill;

  const AddSkillSheet({super.key, required this.user, this.initialSkill});

  @override
  State<AddSkillSheet> createState() => _AddSkillSheetState();
}

class _AddSkillSheetState extends State<AddSkillSheet> {
  final _nameController = TextEditingController();
  String _selectedLevel = 'Intermédiaire';
  final List<String> _levels = ['Débutant', 'Intermédiaire', 'Avancé'];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialSkill != null) {
      _nameController.text = widget.initialSkill!.name;
      _selectedLevel = widget.initialSkill!.level;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveSkill() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final newSkill = Skill(name: name, level: _selectedLevel);
      final updatedSkills = List<Skill>.from(widget.user.skills);
      
      if (widget.initialSkill != null) {
        final index = updatedSkills.indexWhere((s) => s.name == widget.initialSkill!.name);
        if (index != -1) {
          updatedSkills[index] = newSkill;
        } else {
          updatedSkills.add(newSkill);
        }
      } else {
        updatedSkills.add(newSkill);
      }

      await context.read<AuthProvider>().updateProfile({
        'skills': updatedSkills.map((s) => s.toMap()).toList(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Compétence ajoutée !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.initialSkill != null ? 'Modifier la compétence' : 'Ajouter une compétence',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'Ex: Gestion de projet, Flutter, Design...',
              prefixIcon: Icon(
                PhosphorIcons.lightning(),
                color: Colors.grey.shade600,
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
          SizedBox(height: 20),
          Text('Niveau', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _levels.map((lvl) {
              final isSelected = _selectedLevel == lvl;
              return ChoiceChip(
                label: Text(lvl),
                selected: isSelected,
                onSelected: (val) {
                  if (val) {
                    setState(() => _selectedLevel = lvl);
                  }
                },
                selectedColor: AppColors.primary.withValues(alpha: 0.1),
                backgroundColor: Colors.grey.shade100,
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.primary : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.5)
                        : Colors.transparent,
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 32),
          ElevatedButton(
            onPressed: _isLoading ? null : _saveSkill,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Theme.of(context).iconTheme.color,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Theme.of(context).cardColor,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    widget.initialSkill != null ? 'Modifier' : 'Ajouter',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
          SizedBox(height: 24),
        ],
      ),
    );
  }
}
