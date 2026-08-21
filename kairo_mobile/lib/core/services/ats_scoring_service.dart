import '../models/user_model.dart';

class AtsScoringService {
  static Map<String, dynamic> evaluateCV(UserModel user) {
    int score = 0;
    List<String> feedback = [];

    // 1. Informations de base (20 points)
    if (user.name.isNotEmpty && user.professionalTitle.isNotEmpty && user.email.isNotEmpty) {
      score += 20;
    } else {
      feedback.add("Les informations de base (Nom, Titre, Email) sont incomplètes.");
      score += 10;
    }

    // 2. Biographie / Résumé (15 points)
    if (user.bio.isNotEmpty) {
      if (user.bio.length > 50) {
        score += 15;
      } else {
        score += 5;
        feedback.add("Votre résumé est trop court. Essayez d'atteindre au moins 3 à 4 phrases impactantes.");
      }
    } else {
      feedback.add("Il manque un résumé (Bio) pour introduire votre profil.");
    }

    // 3. Expériences (30 points)
    if (user.experiences.isNotEmpty) {
      if (user.experiences.length >= 2) {
        score += 30;
      } else {
        score += 15;
        feedback.add("Ajoutez plus d'expériences professionnelles si possible.");
      }
      // Vérifier si les expériences ont des descriptions
      bool hasDescriptions = user.experiences.any((e) => e.description.length > 20);
      if (!hasDescriptions) {
        score -= 5;
        feedback.add("Détaillez davantage les missions et résultats de vos expériences.");
      }
    } else {
      feedback.add("Vous n'avez ajouté aucune expérience professionnelle.");
    }

    // 4. Formations (15 points)
    if (user.educations.isNotEmpty) {
      score += 15;
    } else {
      feedback.add("N'oubliez pas d'ajouter votre parcours académique.");
    }

    // 5. Compétences (20 points)
    if (user.skills.length >= 5) {
      score += 20;
    } else if (user.skills.isNotEmpty) {
      score += 10;
      feedback.add("Ajoutez au moins 5 compétences pour passer les filtres ATS.");
    } else {
      feedback.add("Les compétences sont cruciales pour les recruteurs. Ajoutez-en.");
    }

    // Calcul final
    if (score > 100) score = 100;
    if (score < 0) score = 0;

    String grade = "Basique";
    if (score >= 80) grade = "Excellent";
    else if (score >= 60) grade = "Intermédiaire";

    if (feedback.isEmpty && score >= 80) {
      feedback.add("Votre profil est parfaitement optimisé pour les recruteurs !");
    }

    return {
      'score': score,
      'grade': grade,
      'feedback': feedback,
    };
  }
}
