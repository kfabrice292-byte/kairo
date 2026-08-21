import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/models/user_model.dart';
import '../../core/services/knowledge_service.dart';
import 'package:kairo_mobile/core/theme/app_colors.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class AddExperienceSheet extends StatefulWidget {
  final Experience? experience; // Si null => Ajout, sinon => Modification

  const AddExperienceSheet({super.key, this.experience});

  @override
  State<AddExperienceSheet> createState() => _AddExperienceSheetState();
}

class _AddExperienceSheetState extends State<AddExperienceSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _organizationController = TextEditingController();
  final _periodController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.experience != null) {
      _titleController.text = widget.experience!.title;
      _organizationController.text = widget.experience!.organization;
      _periodController.text = widget.experience!.period;
      _descriptionController.text = widget.experience!.description;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _organizationController.dispose();
    _periodController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _showActionVerbsSheet(BuildContext context) {
    final verbs = KnowledgeService.getActionVerbs();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Verbes d\'action', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('Appuyez sur un verbe pour l\'ajouter à votre description.', style: TextStyle(color: Colors.grey.shade600)),
                  SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: verbs.length,
                      itemBuilder: (context, index) {
                        final category = verbs[index];
                        final items = category['items'] as List<dynamic>;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(category['categorie'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                            ),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: items.map((verb) {
                                return ActionChip(
                                  label: Text(verb),
                                  onPressed: () {
                                    final currentText = _descriptionController.text;
                                    _descriptionController.text = currentText.isEmpty ? verb.toString() : '$currentText ${verb.toString()}';
                                    Navigator.pop(context);
                                  },
                                );
                              }).toList(),
                            ),
                            SizedBox(height: 16),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();

      final exp = Experience(
        id: widget.experience?.id ?? const Uuid().v4(),
        title: _titleController.text.trim(),
        organization: _organizationController.text.trim(),
        period: _periodController.text.trim(),
        description: _descriptionController.text.trim(),
      );

      if (widget.experience == null) {
        await authProvider.addExperience(exp);
      } else {
        await authProvider.updateExperience(exp);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expérience sauvegardée !'),
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
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.experience == null
                      ? 'Ajouter une expérience'
                      : 'Modifier l\'expérience',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: _buildInputDecoration(
                'Titre du poste (ex: Stagiaire Data)',
                PhosphorIcons.briefcase(),
              ),
              validator: (v) => v!.isEmpty ? 'Requis' : null,
            ),
            SizedBox(height: 12),
            TextFormField(
              controller: _organizationController,
              decoration: _buildInputDecoration(
                'Entreprise / Organisation',
                PhosphorIcons.buildings(),
              ),
              validator: (v) => v!.isEmpty ? 'Requis' : null,
            ),
            SizedBox(height: 12),
            TextFormField(
              controller: _periodController,
              decoration: _buildInputDecoration(
                'Période (ex: Jan 2023 - Présent)',
                PhosphorIcons.calendar(),
              ),
              validator: (v) => v!.isEmpty ? 'Requis' : null,
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Missions', style: TextStyle(fontWeight: FontWeight.w600)),
                TextButton.icon(
                  onPressed: () {
                    _showActionVerbsSheet(context);
                  },
                  icon: Icon(PhosphorIcons.lightbulb(), size: 16),
                  label: Text('Verbes d\'action'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: _buildInputDecoration(
                'Description des missions...',
                PhosphorIcons.textAa(),
              ),
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _save,
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
                      'Sauvegarder',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.grey.shade600),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
