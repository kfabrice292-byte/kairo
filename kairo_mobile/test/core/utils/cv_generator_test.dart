import 'package:flutter_test/flutter_test.dart';
import 'package:kairo_mobile/core/utils/cv_generator.dart';
import 'package:kairo_mobile/core/models/user_model.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  group('CVGenerator Tests', () {
    test('generateCV completes without error for local destination', () async {
      final user = UserModel(
        uid: '123',
        email: 'test@test.com',
        name: 'John Doe',
        city: 'Ouagadougou',
        photoURL: 'https://example.com/photo.jpg'
      );
      
      expect(() async => await CVGenerator.generateCV(user, template: 'moderne', destination: 'burkina'), returnsNormally);
    });

    test('generateCV completes without error for international destination', () async {
      final user = UserModel(
        uid: '123',
        email: 'test@test.com',
        name: 'John Doe',
        city: 'Ouagadougou',
        photoURL: 'https://example.com/photo.jpg'
      );
      
      expect(() async => await CVGenerator.generateCV(user, template: 'moderne', destination: 'international'), returnsNormally);
    });
  });
}
