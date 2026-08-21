import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'settings_title': 'Settings',
      'appearance': 'Appearance',
      'theme': 'Theme',
      'light': 'Light',
      'dark': 'Dark',
      'system': 'System',
      'preferences': 'Preferences',
      'language': 'Language',
      'privacy': 'Profile Privacy',
      'public': 'Public',
      'connections': 'Connections',
      'private': 'Private',
      'notifications': 'Notifications',
      'push_notifications': 'Push Notifications',
      'email_notifications': 'Community Emails',
      'about': 'About',
      'help_support': 'Help & Support',
      'privacy_policy': 'Privacy Policy',
      'terms_of_service': 'Terms of Service',
      'account': 'Account',
      'security': 'Password & Security',
      'delete_account': 'Delete my account',
      'logout': 'Log out',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'delete_account_title': 'Delete Account',
      'delete_account_desc': 'This action is irreversible. All your data will be lost. Continue?',
      'logout_title': 'Log Out',
      'logout_desc': 'Are you sure you want to log out?',
    },
    'fr': {
      'settings_title': 'Paramètres',
      'appearance': 'Apparence',
      'theme': 'Thème',
      'light': 'Clair',
      'dark': 'Sombre',
      'system': 'Système',
      'preferences': 'Préférences',
      'language': 'Langue',
      'privacy': 'Confidentialité du profil',
      'public': 'Public',
      'connections': 'Connexions',
      'private': 'Privé',
      'notifications': 'Notifications',
      'push_notifications': 'Notifications Push',
      'email_notifications': 'Emails de communauté',
      'about': 'À propos',
      'help_support': 'Aide & Support',
      'privacy_policy': 'Politique de confidentialité',
      'terms_of_service': 'Conditions d\'utilisation',
      'account': 'Compte',
      'security': 'Mot de passe et Sécurité',
      'delete_account': 'Supprimer mon compte',
      'logout': 'Se déconnecter',
      'cancel': 'Annuler',
      'delete': 'Supprimer',
      'delete_account_title': 'Supprimer le compte',
      'delete_account_desc': 'Cette action est irréversible. Toutes vos données seront perdues. Continuer ?',
      'logout_title': 'Déconnexion',
      'logout_desc': 'Êtes-vous sûr de vouloir vous déconnecter ?',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'fr'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension TranslateExtension on BuildContext {
  String tr(String key) {
    return AppLocalizations.of(this)?.translate(key) ?? key;
  }
}
