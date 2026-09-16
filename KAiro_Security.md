# 🛡️ KAÏRO 2.0 — SÉCURITÉ ET GOUVERNANCE

La sécurité est la priorité absolue de Kaïro 2.0. Nous traitons des données professionnelles, des PII (Personally Identifiable Information) et nous visons une cible B2B exigeante. La doctrine est : **Secure-by-design, Least privilege, et Defense in depth.**

---

## 1. 🔐 AUTHENTIFICATION & AUTORISATION

### Authentification (Identity)
* **Standardisation** : Firebase Authentication est le seul fournisseur d'identité. 
* **Multi-Facteurs (MFA)** : Obligatoire pour tous les comptes B2B (RH, Admins, Recruteurs). Optionnel pour les Talents.
* **Session Management** : Mise en place d'un mécanisme de révocation de tokens en cas de suspicion de compromission ("Déconnecter tous les appareils").

### Autorisation (RBAC)
* **Zero Trust Frontend** : Le frontend (Flutter ou Web) ne fait que *demander*. L'autorisation réelle est systématiquement évaluée côté backend (Firestore Rules ou Cloud Functions).
* **Multi-Tenancy stricte** :
  - Toute ressource B2B (Job, Application, Candidate note) doit posséder un champ `organizationId`.
  - La vérification d'accès s'assure que le `request.auth.uid` fait partie des membres de cet `organizationId` avec le rôle adéquat.
* **Fin du `isAdmin = true`** : Le flag global est supprimé au profit d'une approche granulaire (`roles: { global: 'user', orgA: 'recruiter' }`).

---

## 2. 🔥 FIREBASE SECURITY RULES

L'approche de développement des règles Firebase bascule en **Deny-by-default**.

* **Tests Obligatoires** : Toute modification des `firestore.rules` doit être accompagnée d'un test automatisé dans la *Firebase Emulator Suite*. 
* **App Check** : Intégration obligatoire de Firebase App Check (Play Integrity pour Android, DeviceCheck/App Attest pour iOS, reCAPTCHA Enterprise pour le Web) pour s'assurer que seules les applications légitimes peuvent interroger la base.

---

## 3. 📂 PROTECTION DES DONNÉES (PII) ET VIE PRIVÉE

### Visibilité du Profil Talent
Contrôle granulaire par l'utilisateur. Niveaux de confidentialité :
1. `PRIVATE` (Visible uniquement par l'utilisateur).
2. `CONNECTIONS_ONLY` (Visible par son réseau direct).
3. `RECRUITERS_ONLY` (Visible uniquement par les comptes certifiés B2B).
4. `PUBLIC` (Indexable).

### Modèles IA & Privacy
* **Sanitization** : Avant d'envoyer un CV à un modèle LLM externe pour analyse, les données nominatives (Téléphone, Email, Adresse physique exacte) doivent être masquées par la Cloud Function.
* **Opt-in** : L'utilisation des données du profil pour entraîner des modèles IA internes est soumise à un consentement explicite.

---

## 4. 🛑 SÉCURITÉ MOBILE (OWASP MASVS)

L'application Flutter doit respecter les standards OWASP pour le mobile :
* **Stockage Sécurisé** : Les tokens d'authentification et clés locales sont stockés via `flutter_secure_storage` (Keystore/Keychain). Jamais dans les `SharedPreferences` en clair.
* **Certificats** : Certificate Pinning si l'application appelle des API REST tierces critiques hors Firebase.
* **Obfuscation** : Le build de release (AAB/IPA) doit inclure l'obfuscation de code (`--obfuscate --split-debug-info`).
* **Protection de l'écran** : Interdiction des captures d'écran sur les vues contenant des données de paiement ou des paramètres de sécurité sensibles (FLAG_SECURE sur Android).

---

## 5. 🛠️ SÉCURITÉ DU CYCLE DE DÉVELOPPEMENT (DevSecOps)

* **Gestion des Secrets** : INTERDICTION FORMELLE de commit des `.env` ou clés d'API en clair.
  - Utilisation de **Google Cloud Secret Manager** pour les Cloud Functions.
  - Injection des variables d'environnement via le CI/CD à la compilation pour Flutter.
* **Analyse Statique (SAST)** : Outils de scan de vulnérabilités intégrés dans la CI (ex: vérification des dépendances `pubspec.yaml` et `package.json` avec `npm audit` / OVS).
* **Audit Logs B2B** : Toute action modifiant une donnée B2B (Embauche, Suppression de candidat, Invitation de membre) est loggée de façon immutable (Timestamp, Acteur, Action, Ressource).

---

## 6. 🛡️ ANTI-ABUS ET VALIDATION

* **Uploads de Fichiers (Storage)** :
  - Un fichier uploadé (ex: CV) est considéré comme **malveillant par défaut**.
  - Validation stricte côté Backend (Storage Rules) : Limite de taille (ex: 5MB), type MIME autorisé (`application/pdf`, `image/jpeg`).
  - Stockage dans des buckets privés; génération d'URLs signées à durée de vie limitée pour la consultation.
* **Rate Limiting** : Limite de requêtes sur les Cloud Functions (via API Gateway ou Cloud Armor) pour contrer le scraping intensif de profils et les attaques Brute Force.
