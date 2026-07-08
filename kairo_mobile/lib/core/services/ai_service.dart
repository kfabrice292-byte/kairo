import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class AIService {
  // Optionnel: Récupérer depuis un fichier de config ou .env
  static const String _apiKey =
      'API_KEY_PLACEHOLDER'; // TODO: Remplacer par la vraie clé Gemini API

  static Future<String> generateCoverLetter({
    required UserModel user,
    required String companyName,
    required String jobTitle,
    required String additionalNotes,
  }) async {
    // Si la clé API n'est pas définie, on retourne un Mock pour pouvoir tester l'UI.
    if (_apiKey == 'API_KEY_PLACEHOLDER') {
      await Future.delayed(
        const Duration(seconds: 2),
      ); // Simuler l'appel réseau
      return '''
Objet : Candidature au poste de $jobTitle chez $companyName

Madame, Monsieur,

Actuellement ${user.professionalTitle}, c'est avec un vif intérêt que je vous soumets ma candidature pour le poste de $jobTitle au sein de $companyName.

Mon parcours m'a permis de développer de solides compétences en ${user.skills.take(3).map((s) => s).join(', ')}. Lors de mes précédentes expériences, j'ai eu l'opportunité de mettre en pratique ces acquis et de contribuer efficacement aux objectifs de mon équipe.

$additionalNotes

Je suis convaincu(e) que mon profil correspond aux attentes de $companyName et je serais ravi(e) de pouvoir échanger avec vous lors d'un entretien pour vous démontrer ma motivation.

Dans cette attente, je vous prie d'agréer, Madame, Monsieur, l'expression de mes salutations distinguées.

${user.name}
${user.email}
${user.phone}
''';
    }

    try {
      final model = GenerativeModel(model: 'gemini-pro', apiKey: _apiKey);
      final prompt =
          '''
      Tu es un expert en rédaction de lettre de motivation.
      Rédige une lettre de motivation professionnelle pour le candidat suivant :
      Nom : ${user.name}
      Titre professionnel : ${user.professionalTitle}
      Compétences : ${user.skills.join(', ')}
      Expériences : ${user.experiences.map((e) => '\${e.title} chez \${e.company}').join(', ')}
      
      Il postule pour l'entreprise "$companyName" au poste de "$jobTitle".
      Notes additionnelles : $additionalNotes
      
      La lettre doit être structurée avec l'objet, des paragraphes clairs, et les salutations d'usage.
      Ne mets pas de balises [Nom du recruteur] si tu ne le sais pas, utilise "Madame, Monsieur,".
      ''';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      return response.text ?? 'Erreur lors de la génération de la lettre.';
    } catch (e) {
      debugPrint('Gemini Error: $e');
      return 'Désolé, une erreur est survenue lors de la connexion à l\'IA. Veuillez réessayer plus tard.';
    }
  }
}
