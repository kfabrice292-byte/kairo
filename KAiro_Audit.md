# 🕵️‍♂️ KAÏRO 2.0 — AUDIT TECHNIQUE & PRODUIT

*Date de l'audit : Septembre 2026*

## 1. 📊 ÉTAT ACTUEL DU PROJET (Current State)

Kaïro se présente actuellement comme une application hybride composée de deux grands blocs opérationnels :
1. **Kaïro Mobile** : Une application Flutter ciblant les Talents.
2. **Kaïro Web (Backoffice/Pro)** : Une suite de fichiers HTML statiques (`admin.html`, `dashboard.html`, `kairo-pro.html`, `public-profile.html`) qui interagissent avec Firebase via des scripts JavaScript (`api.js`, etc.).

L'application est **fonctionnelle** dans ses cas d'usage principaux : authentification, création de CV, partage de profils (Web/QR), et une brique de paiement local (Ashtech Pay). Cependant, elle présente un assemblage de fonctionnalités "MVP" qui nécessitent une forte structuration pour devenir une plateforme SaaS B2B/B2C scalable.

---

## 2. 🏗️ ARCHITECTURE ACTUELLE

### Frontend (Mobile)
* **Framework** : Flutter (Cross-platform).
* **Navigation** : GoRouter.
* **State Management** : Provider.
* **Organisation** : Dossiers `core`, `screens`, `widgets`. Présence de dette technique liée aux fichiers monolithiques (ex: `portfolio_screen.dart` : 67 000 octets).

### Frontend (Web)
* **Stack** : Vanilla HTML/JS avec Tailwind CSS (CDN/Local).
* **Déploiement** : Firebase Hosting.
* **Problème architectural** : Les pages web (Admin, Dashboard, Recruit) sont des fichiers isolés sans framework SPA (Single Page Application) robuste comme React, Vue ou Angular, rendant le passage à l'échelle très difficile et sujet aux erreurs de synchronisation d'état.

### Backend (Serverless)
* **BaaS** : Firebase (Authentication, Firestore, Storage, Hosting, Cloud Functions).
* **Cloud Functions** : Logique métier en Node.js (ex: webhook de paiement, matching engine). Node.js v22.
* **Database** : Firestore. Modèle de données partiellement dénormalisé mais qui manque de structures strictes (schémas TypeScript partagés).

---

## 3. 🔍 FONCTIONNALITÉS EXISTANTES (Ce qui marche)

* **Authentification** : Inscription/Connexion fonctionnelle (Firebase Auth).
* **Profils Talents** : Saisie d'expériences, compétences, langues, etc.
* **Génération de CV** : Fonctionnalité PDF fonctionnelle.
* **Partage de profil public** : Interface Web de profil accessible via lien/QR.
* **Monétisation** : Intégration Ashtech Pay (Abonnement et Pay-as-you-go).
* **Opportunities** : Système basique d'offres et de candidatures (Postuler).

---

## 4. 📉 CE QUI EST SIMULÉ OU INCOMPLET (Mocks / WIP)

* **Le Backoffice (Admin/Entreprises)** : Les fichiers HTML existent, mais manquent cruellement d'un véritable RBAC (Role-Based Access Control) côté backend. L'admin est géré par un flag rudimentaire (`role == 'admin'`).
* **L'ATS (Applicant Tracking System)** : Le Pipeline de recrutement est soit inexistant, soit très basique (impossible de bouger un candidat de `SCREENING` à `INTERVIEW` de façon auditable et structurée).
* **Le Moteur de Recherche** : Actuellement basé sur des requêtes Firestore basiques, incapable de faire de la recherche full-text floue sans outil externe (comme Algolia ou Meilisearch).
* **Analytics** : Manque d'une couche Data structurée (Events).

---

## 5. ⚠️ DETTE TECHNIQUE & RISQUES DE SÉCURITÉ

### Sécurité (Critique)
* **Firestore Rules** : Les règles actuelles s'appuient sur un champ `role` dans le document utilisateur pour définir l'admin (`isAdmin()`). Cela expose à un risque majeur de *Privilege Escalation* si l'update de l'utilisateur n'est pas blindé. De plus, les règles pour `/opportunities/{id}/applicants` empêchent l'update, déléguant tout à l'API, ce qui est une bonne chose, mais la gestion du multi-tenant (plusieurs entreprises) est quasi inexistante.
* **Secrets** : Fichiers `.env` présents à la racine (bien que potentiellement versionnés via .gitignore, c'est un point d'attention).
* **API et Cloud Functions** : Les requêtes HTTP doivent vérifier rigoureusement l'authentification (App Check est absent des règles visibles).

### Performances & Maintenabilité
* **Fichiers massifs** : Plusieurs écrans Flutter sont beaucoup trop longs et mélangent UI et Logique Métier.
* **Normalisation des données** : Les compétences (Skills) sont probablement de simples strings. Sans référentiel (Taxonomie), les recherches croisées B2B seront inefficaces.
* **Séparation Mobile/Web** : La duplication de logique métier entre le Web (JS) et le Mobile (Dart) va créer un enfer de maintenance.

---

## 6. 🛣️ CHEMIN DE MIGRATION RECOMMANDÉ (Vers 2.0)

Pour évoluer vers Kaïro 2.0, il **NE FAUT PAS** tout réécrire d'un coup.

1. **Harden (Sécurisation)** : Blinder les Firestore Rules et migrer les validations critiques dans les Cloud Functions.
2. **Refactor (Web)** : Migrer les interfaces Web Pro (Dashboard, Admin) vers un framework moderne structuré pour le SaaS (ex: Flutter Web ou Next.js) afin de partager les modèles de données.
3. **Data Model (Normalisation)** : Implémenter le typage fort pour les Compétences, les Offres d'emploi, et le statut des Candidatures (Pipelines).
4. **Scale (Recherche & IA)** : Introduire un vrai moteur de recherche décorrélé de Firestore, et positionner l'IA comme un module isolé.
