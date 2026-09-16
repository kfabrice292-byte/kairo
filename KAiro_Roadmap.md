# 🗺️ KAÏRO 2.0 — ROADMAP PRODUIT & TECHNIQUE

Ce document découpe la migration et le développement de Kaïro 2.0 en phases séquentielles. La priorité est de **ne pas casser l'existant**, d'assurer la robustesse des fondations, puis de scaler.

---

## 🛑 PHASE 0 : AUDIT & SÉCURISATION IMMÉDIATE (En cours)
*Objectif : Stopper la dette technique critique et verrouiller le backend.*
* **Tâches** :
  * [x] Création des documents d'audit (Audit, Architecture, Security, Roadmap).
  * [ ] Revue et réécriture des **Firestore Rules** en `deny-by-default`.
  * [ ] Audit des dépendances Flutter et Node.js (Mise à jour des packages critiques).
  * [ ] Suppression et rotation de tout secret exposé (ex: `.env`).
  * [ ] Mise en place du CI/CD basique (Lint, Tests unitaires sur les PR).

---

## 🏗️ PHASE 1 : FOUNDATION (Les Fondations de la Plateforme)
*Objectif : Mettre en place l'architecture de données et le RBAC B2B.*
* **Data Model V2** : Structuration stricte des collections (`users`, `organizations`, `talents`, `jobs`).
* **Multi-Tenancy & RBAC** : Définition des rôles (OWNER, ADMIN, RECRUITER) et isolation des données d'entreprise dans Firebase.
* **Taxonomie (Skills)** : Création du référentiel normalisé de compétences. Fini le texte libre, place aux entités relationnelles.
* **Refactor Flutter (Core)** : Nettoyage de l'architecture mobile existante (`core/`). Introduction d'un conteneur d'injection de dépendances et de tests automatisés.

---

## 📱 PHASE 2 : KAÏRO TALENT (L'App B2C)
*Objectif : Solidifier l'expérience Candidat/Freelance sur Mobile.*
* **Profil Structuré** : Le profil redevient la source de vérité absolue (plus riche que le PDF).
* **Refactor UI/UX** : Allègement des vues massives (ex: `portfolio_screen.dart`), application du Design System unifié.
* **Offline-First** : Implémentation du cache local pour une utilisation fluide même avec une mauvaise connectivité.
* **Gamification légère** : Jauge de complétion du profil professionnelle.

---

## 🏢 PHASE 3 : KAÏRO PRO (L'Espace B2B SaaS)
*Objectif : Offrir un vrai ATS aux entreprises (Web).*
* **Migration Web** : Passage des fichiers statiques actuels (`dashboard.html`, `kairo-pro.html`) vers une SPA moderne (React/Next.js ou Flutter Web).
* **ATS (Applicant Tracking System)** : Gestion du pipeline de recrutement (NEW → SCREENING → INTERVIEW → HIRED).
* **Gestion d'équipe** : Invitations de collaborateurs (RH, Managers) avec rôles granulaires.
* **Dashboard Opérationnel** : Métriques de recrutement de base.

---

## 🤝 PHASE 4 : KAÏRO RECRUIT (Agences & Chasseurs de Têtes)
*Objectif : Permettre aux cabinets de gérer plusieurs clients.*
* **Espace Cabinet** : Interface permettant de basculer entre plusieurs entités clientes.
* **Talent Pools (Viviers)** : Création et gestion de listes de candidats (Shortlists).
* **Contrôle de partage** : Partage sécurisé et limité dans le temps des profils candidats aux clients finaux.

---

## 📈 PHASE 5 : DATA & ANALYTICS
*Objectif : Rendre la plateforme Data-Driven.*
* **Event Pipeline** : Instrumentation de l'application (Clics, Vues, Postulations) envoyée vers un stockage analytique (BigQuery).
* **Dashboards B2B Avancés** : Funnel de recrutement, Time-to-hire, Source de conversion.
* **Exports** : Génération de rapports CSV/Excel propres pour les RH.

---

## 🧠 PHASE 6 : INTELLIGENCE & IA
*Objectif : Ajouter une couche de recommandation à forte valeur ajoutée.*
* **Search Engine** : Implémentation d'Algolia/Typesense pour des recherches multicritères ultra-rapides.
* **Matching Transparent** : Score de compatibilité Offre/Candidat explicable (Matching strengths/weaknesses).
* **IA Coach** : Agent conversationnel asynchrone aidant le talent à améliorer son CV.

---

## 🌐 PHASE 7 : ÉCOSYSTÈME & API
*Objectif : S'interfacer avec le monde.*
* **API Publique V1** : Sécurisée via clés API, pour permettre aux grandes entreprises de brancher leur propre SIRH ou ATS (ex: Workday, SAP).
* **Connecteurs** : Intégration calendrier (Google/Outlook) pour les entretiens, Visioconférence (Zoom/Meet).
* **Import de données en masse** : Processus d'ingestion de CSV pour onboarder rapidement les entreprises.
