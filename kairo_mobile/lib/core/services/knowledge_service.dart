import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class KnowledgeService {
  static List<dynamic> _metiers = [];
  static List<dynamic> _competences = [];
  static List<dynamic> _verbesAction = [];

  static Future<void> init() async {
    try {
      final metiersString = await rootBundle.loadString('assets/knowledge_base/lib_metiers.json');
      final metiersJson = json.decode(metiersString);
      _metiers = metiersJson['metiers'] ?? [];

      final competencesString = await rootBundle.loadString('assets/knowledge_base/lib_competences.json');
      final competencesJson = json.decode(competencesString);
      _competences = competencesJson['competences'] ?? [];

      final verbesString = await rootBundle.loadString('assets/knowledge_base/lib_verbes_action.json');
      final verbesJson = json.decode(verbesString);
      _verbesAction = verbesJson['verbes_action'] ?? [];
    } catch (e) {
      debugPrint('Erreur lors du chargement de la base documentaire: $e');
    }
  }

  /// Récupère la liste complète des verbes d'action catégorisés
  static List<dynamic> getActionVerbs() {
    return _verbesAction;
  }

  /// Suggère des compétences en fonction d'un titre professionnel
  static List<String> getSuggestedSkillsForTitle(String title) {
    if (title.isEmpty) return [];
    
    final lowerTitle = title.toLowerCase();
    List<String> suggestions = [];

    // Cherche le métier qui correspond le mieux au titre
    for (var metier in _metiers) {
      final metierTitre = (metier['titre'] as String).toLowerCase();
      // Si on trouve une correspondance partielle (ex: "Développeur" matche "Développeur Mobile")
      if (lowerTitle.contains(metierTitre) || metierTitre.contains(lowerTitle)) {
        suggestions.addAll(List<String>.from(metier['competences_requises'] ?? []));
        suggestions.addAll(List<String>.from(metier['outils'] ?? []));
      }
    }

    // Si aucune correspondance directe, on retourne quelques compétences générales par défaut
    if (suggestions.isEmpty) {
      for (var cat in _competences) {
        if (cat['categorie'] == 'Soft Skills (Savoir-être)') {
          for (var item in cat['items']) {
            suggestions.add(item['nom']);
          }
        }
      }
    }

    // Éliminer les doublons et limiter à 10
    return suggestions.toSet().toList().take(10).toList();
  }

  /// Récupère le contexte métier complet (Missions, KPIs) pour nourrir l'IA
  static Map<String, dynamic>? getJobContextForTitle(String title) {
    if (title.isEmpty) return null;
    final lowerTitle = title.toLowerCase();

    for (var metier in _metiers) {
      final metierTitre = (metier['titre'] as String).toLowerCase();
      if (lowerTitle.contains(metierTitre) || metierTitre.contains(lowerTitle)) {
        return metier;
      }
    }
    return null;
  }
}
