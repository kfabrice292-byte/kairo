import 'package:flutter/foundation.dart';
import '../models/course_model.dart';

class LearningProvider extends ChangeNotifier {
  final List<CourseModel> _courses = [
    CourseModel(
      id: '1',
      title: 'Réussir son entretien',
      instructor: 'Coach Aminata',
      category: 'Soft Skills',
    ),
    CourseModel(
      id: '2',
      title: 'Les bases de Flutter',
      instructor: 'Dev Academy',
      category: 'Hard Skills',
    ),
    CourseModel(
      id: '3',
      title: 'Optimiser son profil LinkedIn',
      instructor: 'Kairo Team',
      category: 'Carrière',
    ),
    CourseModel(
      id: '4',
      title: 'Prise de parole en public',
      instructor: 'Coach Amadou',
      category: 'Soft Skills',
    ),
  ];

  List<CourseModel> get courses => _courses;
}
