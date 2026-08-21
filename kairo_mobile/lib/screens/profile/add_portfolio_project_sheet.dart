import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kairo_mobile/core/providers/auth_provider.dart';
import 'package:kairo_mobile/core/models/user_model.dart';
import 'package:kairo_mobile/widgets/kairo_text_field.dart';
import 'package:kairo_mobile/core/theme/app_colors.dart';
import 'package:uuid/uuid.dart';

class AddPortfolioProjectSheet extends StatefulWidget {
  final PortfolioProject? projectToEdit;

  const AddPortfolioProjectSheet({super.key, this.projectToEdit});

  @override
  State<AddPortfolioProjectSheet> createState() => _AddPortfolioProjectSheetState();
}

class _AddPortfolioProjectSheetState extends State<AddPortfolioProjectSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _techController = TextEditingController();
  final _linkController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.projectToEdit != null) {
      _titleController.text = widget.projectToEdit!.title;
      _descController.text = widget.projectToEdit!.description;
      _techController.text = widget.projectToEdit!.technologies.join(', ');
      _linkController.text = widget.projectToEdit!.link;
    }
  }

  void _save() async {
    if (_titleController.text.trim().isEmpty) return;

    final auth = context.read<AuthProvider>();
    final user = auth.userModel;
    if (user != null) {
      List<PortfolioProject> projects = List.from(user.portfolioProjects);
      
      final techList = _techController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      
      final newProject = PortfolioProject(
        id: widget.projectToEdit?.id ?? const Uuid().v4(),
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        technologies: techList,
        link: _linkController.text.trim(),
        result: '',
        imageUrl: '',
      );

      if (widget.projectToEdit != null) {
        final index = projects.indexWhere((p) => p.id == widget.projectToEdit!.id);
        if (index != -1) projects[index] = newProject;
      } else {
        projects.add(newProject);
      }

      final projectsMapList = projects.map((p) => p.toMap()).toList();
      await auth.updateProfile({'portfolioProjects': projectsMapList});
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.projectToEdit == null ? 'Ajouter un projet' : 'Modifier le projet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(icon: Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 24),
            KairoTextField(controller: _titleController, hintText: 'Titre du projet *', prefixIcon: PhosphorIcons.folder()),
            const SizedBox(height: 16),
            KairoTextField(controller: _descController, hintText: 'Description', prefixIcon: PhosphorIcons.textAa(), maxLines: 3),
            const SizedBox(height: 16),
            KairoTextField(controller: _techController, hintText: 'Technologies (séparées par des virgules)', prefixIcon: PhosphorIcons.code()),
            const SizedBox(height: 16),
            KairoTextField(controller: _linkController, hintText: 'Lien (URL)', prefixIcon: PhosphorIcons.link()),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 16)),
                child: Text('Enregistrer', style: TextStyle(color: Theme.of(context).cardColor)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
