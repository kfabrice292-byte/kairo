# 🏛️ KAÏRO 2.0 — ARCHITECTURE CIBLE

Ce document définit l'architecture cible pour faire passer Kaïro d'un MVP monolithique à une infrastructure B2B/B2C modulaire, sécurisée et scalable.

---

## 1. 🌐 ARCHITECTURE HAUT NIVEAU (MACRO)

L'écosystème Kaïro 2.0 sera divisé en 4 grands environnements interconnectés, partageant le même socle de données (Firebase/Cloud) mais avec des interfaces dédiées.

### A. Kaïro Talent (B2C)
* **Application** : Application Mobile Flutter.
* **Cible** : Étudiants, professionnels, freelances.
* **Responsabilité** : Profil, génération de CV, Portfolio, candidatures, alertes, e-learning.

### B. Kaïro Pro (B2B SaaS)
* **Application** : Application Web Desktop-first (SPA - Single Page Application, ex: Next.js ou Flutter Web).
* **Cible** : PME, Grandes Entreprises, RH.
* **Responsabilité** : Multi-tenancy (isolation par entreprise), ATS (Applicant Tracking System), pipelines de recrutement, analytics.

### C. Kaïro Recruit (B2B Agences)
* **Application** : Module spécifique au sein de Kaïro Pro.
* **Cible** : Cabinets de chasse de têtes, agences RH.
* **Responsabilité** : Gestion multi-clients, constitution de viviers (Talent Pools), contrôle granulaire du partage de données.

### D. Kaïro Admin & Intelligence (Interne)
* **Application** : Backoffice sécurisé.
* **Responsabilité** : Modération, gestion de la taxonomie (compétences, métiers), facturation, supervision des modèles IA, metrics de la plateforme.

---

## 2. 🗄️ DATA MODEL (FONDATIONS)

### 2.1. Operational Data (Firestore)
La base de données opérationnelle gère les transactions chaudes.

* **Collections principales** :
  * `users` : Profils unifiés (Auth). Contient un sous-document de rôles (`roles: { organizationId: 'hr_manager' }`).
  * `organizations` : Entreprises et Cabinets (Tenants).
  * `talents` : Données professionnelles structurées (séparées de `users` pour alléger les lectures).
  * `jobs` : Offres d'emploi structurées (salary, remotePolicy, requiredSkills).
  * `applications` : Candidatures (Immutable data, timestampées à chaque étape du pipeline ATS).
  * `skills_taxonomy` : Référentiel normalisé des compétences (géré par Admin).

### 2.2. Analytical & Search Data
* **Moteur de recherche** : Algolia ou Typesense (synchronisé via Cloud Functions). Firestore n'est pas conçu pour des requêtes complexes "full-text".
* **Data Warehouse (Futur)** : BigQuery (via Firebase Extensions). Tout événement (ex: `application_submitted`) est streamé vers BigQuery pour l'analytics B2B (Conversion, Time-to-hire).

---

## 3. 🔒 SÉCURITÉ ET AUTORISATION (RBAC)

Ne jamais faire confiance au frontend. L'autorisation sera gérée selon un modèle **RBAC (Role-Based Access Control) multi-tenant**.

* **Modèle d'accès** :
  - L'utilisateur possède un ID unique (`uid`).
  - Un document de mapping `user_roles/{uid}` contient ses droits par organisation. Ex: `{"orgA": "ADMIN", "orgB": "VIEWER"}`.
* **Firestore Rules** :
  - Les règles vérifient le rôle via des fonctions `get()`.
  - Accès aux données d'une entreprise conditionné par `request.auth.uid in get(/databases/$(database)/documents/organizations/$(orgId)).data.members`.
* **API / Cloud Functions** :
  - Toute action destructive ou complexe (ex: déplacer un candidat dans l'ATS) passe par une Cloud Function.
  - La fonction vérifie le token d'authentification ET le rôle du tenant avant d'exécuter l'action.

---

## 4. 🧠 ARCHITECTURE IA (KAÏRO AI)

L'IA n'est pas un gadget, c'est une couche de service (Micro-service autonome).

* **Principe "Human-in-the-loop"** : L'IA propose, l'humain dispose.
* **Modules isolés** :
  * *CV Coach* : Analyse le CV et génère des suggestions (Cloud Function + LLM API).
  * *Matching Engine* : Calcule la compatibilité Offre ↔ Profil basé sur la taxonomie des compétences (et non un simple texte). Retourne un score explicable (Match strengths, missing requirements).
* **Gouvernance des données** : Les PII (Personal Identifiable Information) sont expurgées avant d'être envoyées aux modèles externes (ex: OpenAI, Claude).

---

## 5. 📱 ARCHITECTURE FLUTTER (KAÏRO TALENT)

Mise en place d'une Clean Architecture stricte pour garantir la testabilité et la maintenabilité.

* **Couches** :
  1. `Presentation` : UI, Widgets, State Management (Provider/Riverpod). Aucune logique métier.
  2. `Domain` : Modèles de données (Entities), Interfaces de Repositories, Cas d'usage (Use cases).
  3. `Data` : Implémentations des Repositories, Data Sources (Firebase, REST API), Sérialisation JSON.
* **Principes** :
  - *Lazy Loading* & *Pagination* systématiques sur les listes (Jobs, Posts).
  - *Offline First* : Utilisation du cache local (Hive ou SQLite) pour les données vitales du profil.
  - Séparation des fichiers monolithiques (Règle d'or : max 300 lignes par fichier UI).

---

## 6. 🚀 INTÉGRATION ET DÉPLOIEMENT CONTINU (CI/CD)

Mise en place de 3 environnements distincts : `dev`, `staging`, `prod`.

* **Pipeline (ex: GitHub Actions)** :
  1. `Lint` (Analyse statique).
  2. `Test` (Tests unitaires, tests d'intégration Flutter).
  3. `Security Scan` (Audit des dépendances).
  4. `Firebase Emulator Tests` (Tests automatisés des règles de sécurité Firestore).
  5. `Build` (APK/AAB pour Android, IPA pour iOS, Web build).
  6. `Deploy` (Firebase Hosting, App Distribution, Play Store/App Store).
