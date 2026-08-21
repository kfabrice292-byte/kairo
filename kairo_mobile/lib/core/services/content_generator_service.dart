import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'knowledge_service.dart';

class ContentGeneratorService {
  
  static Future<String> generateCoverLetter({
    required UserModel user,
    required String companyName,
    required String jobTitle,
    required String jobDescription,
    required String additionalNotes,
    String employerType = 'Privé',
  }) async {
    // Génération instantanée déterministe basée sur le profil (Sans IA)
    await Future.delayed(const Duration(milliseconds: 800)); // Simuler un traitement
    
    final skillsText = user.skills.isNotEmpty 
        ? user.skills.take(3).map((s) => s.name).join(', ') 
        : 'mon dynamisme, ma rigueur et ma capacité d\'adaptation';

    return '''
Objet : Candidature au poste de $jobTitle chez $companyName

Madame, Monsieur,

Actuellement ${user.professionalTitle}, c'est avec un vif intérêt que je vous soumets ma candidature pour le poste de $jobTitle au sein de $companyName.

Mon parcours m'a permis de développer de solides compétences, notamment : $skillsText. Lors de mes précédentes expériences, j'ai eu l'opportunité de mettre en pratique ces acquis et de contribuer efficacement aux objectifs qui m'étaient fixés.

$additionalNotes

Je suis convaincu(e) que mon profil correspond aux attentes de $companyName et je serais ravi(e) de pouvoir échanger avec vous lors d'un entretien pour vous démontrer ma motivation.

Dans cette attente, je vous prie d'agréer, Madame, Monsieur, l'expression de mes salutations distinguées.
''';
  }

  // Cette méthode n'est plus utilisée, elle est remplacée par le Scoring ATS.
  // On la garde vide au cas où une référence subsiste avant nettoyage complet.
  static Future<Map<String, String>> adaptCvToJobOffer({
    required UserModel user,
    required String jobDescription,
  }) async {
    return {'title': user.professionalTitle, 'bio': user.bio};
  }
}
