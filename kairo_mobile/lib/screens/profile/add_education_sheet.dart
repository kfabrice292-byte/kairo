import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/models/user_model.dart';
import 'package:kairo_mobile/core/theme/app_colors.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class AddEducationSheet extends StatefulWidget {
  final Education? education;

  const AddEducationSheet({super.key, this.education});

  @override
  State<AddEducationSheet> createState() => _AddEducationSheetState();
}

class _AddEducationSheetState extends State<AddEducationSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _institutionController = TextEditingController();
  final _periodController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.education != null) {
      _titleController.text = widget.education!.title;
      _institutionController.text = widget.education!.institution;
      _periodController.text = widget.education!.period;
      _descriptionController.text = widget.education!.description;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _institutionController.dispose();
    _periodController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();

      final edu = Education(
        id: widget.education?.id ?? const Uuid().v4(),
        title: _titleController.text.trim(),
        institution: _institutionController.text.trim(),
        period: _periodController.text.trim(),
        description: _descriptionController.text.trim(),
      );

      if (widget.education == null) {
        await authProvider.addEducation(edu);
      } else {
        await authProvider.updateEducation(edu);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Formation sauvegardée !'),
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
                  widget.education == null
                      ? 'Ajouter une formation'
                      : 'Modifier la formation',
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
                'Titre / Diplôme (ex: Master en IA)',
                PhosphorIcons.certificate(),
              ),
              validator: (v) => v!.isEmpty ? 'Requis' : null,
            ),
            SizedBox(height: 12),
            TextFormField(
              controller: _institutionController,
              decoration: _buildInputDecoration(
                'Établissement / Université',
                PhosphorIcons.bank(),
              ),
              validator: (v) => v!.isEmpty ? 'Requis' : null,
            ),
            SizedBox(height: 12),
            TextFormField(
              controller: _periodController,
              decoration: _buildInputDecoration(
                'Période (ex: 2021 - 2023)',
                PhosphorIcons.calendar(),
              ),
              validator: (v) => v!.isEmpty ? 'Requis' : null,
            ),
            SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: _buildInputDecoration(
                'Description (Optionnel)...',
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
