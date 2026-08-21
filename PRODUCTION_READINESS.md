# PRODUCTION_READINESS.md — Exigences de qualité de production pour KAÏRO (hors génération IA)

Ce document couvre tout ce qui fait qu'une app Flutter/Firebase est prête pour la production : performance, stabilité, tests, monitoring, et publication. Il complète AGENTS.md, SECURITY.md et SMART_DOCUMENTS.md.

---

## 1. Performance

### Listes et feed
- Toute liste (feed, chat, notifications, opportunités) doit être paginée — jamais un `.get()` qui charge toute une collection Firestore d'un coup. Utiliser `startAfter`/curseurs Firestore avec une taille de page raisonnable (15-25 éléments).
- Utiliser `ListView.builder` (ou équivalent lazy) partout où une liste peut dépasser 20 éléments — jamais de `Column` avec `.map()` sur une liste potentiellement longue.
- Mise en cache des images réseau (`cached_network_image` ou équivalent) — jamais de rechargement réseau à chaque scroll/rebuild.

### Rebuilds inutiles
- Vérifier qu'un `Provider.of` ou `Consumer` n'entraîne pas de rebuild de tout un écran quand une seule petite partie change (utiliser `Selector` ou découper les widgets en composants plus fins).
- Le chat temps réel et les notifications (mise à jour fréquente) sont les zones les plus à risque de rebuilds en cascade — à surveiller en priorité.

### Démarrage de l'app
- Le splash screen ne doit pas dépendre d'un appel réseau bloquant avant de décider de la redirection — prévoir un état de chargement local, timeout, et fallback si Firebase est lent à répondre.
- Temps de démarrage à froid ciblé : sous 2-3 secondes sur un appareil milieu de gamme.

---

## 2. Fiabilité et gestion des erreurs

- Toute opération réseau (Firestore, upload d'image, envoi de message) doit avoir une gestion explicite des cas d'échec : pas de réseau, timeout, permission refusée — jamais un simple crash silencieux ou un état de chargement infini.
- Mode dégradé hors ligne : au minimum, l'utilisateur doit pouvoir consulter le contenu déjà chargé (feed, profil, messages) sans connexion, avec un indicateur clair "vous êtes hors ligne" plutôt qu'un écran blanc ou une erreur brute.
- Aucune exception non interceptée ne doit remonter jusqu'à un crash visible pour l'utilisateur — encapsuler les appels réseau/Firebase dans des try/catch avec message utilisateur clair (pas de stack trace affichée).

---

## 3. Tests

- Chaque nouvelle fonctionnalité livrée par l'agent doit inclure au minimum :
  - Un test unitaire pour toute logique métier non triviale (calcul, validation, transformation de données).
  - Un test de widget pour les écrans critiques (login, création de post, candidature, génération de CV).
- Avant toute livraison touchant à l'authentification ou aux règles Firestore, exécuter les tests dans l'émulateur Firebase local plutôt que sur la base de production.
- Les régressions détectées lors de tests précédents ne doivent jamais être retestées manuellement seulement "à l'œil" — un test automatisé doit être ajouté pour éviter la réapparition du bug.

---

## 4. Monitoring et observabilité

- Intégrer un outil de suivi des crashs (Firebase Crashlytics) dès le début — sans ça, l'équipe découvre les bugs de production via les avis 1 étoile sur les stores, ce qui est trop tard.
- Journaliser les erreurs réseau et Firestore (sans logger de données personnelles sensibles) pour pouvoir diagnostiquer un problème signalé par un utilisateur.
- Suivre au minimum : taux de crash, temps de démarrage, taux d'échec des requêtes Firestore critiques (candidature, envoi de message).

---

## 5. Accessibilité et compatibilité

- Contraste texte/fond suffisant (respecter les ratios WCAG AA autant que possible) — particulièrement important pour le template Créatif du Smart CV et le mode sombre.
- Tailles de police et zones tactiles (boutons, icônes) suffisamment grandes pour rester utilisables sur les appareils d'entrée de gamme les plus courants en Afrique de l'Ouest, souvent avec des écrans plus petits et moins denses.
- Tester sur au moins un appareil bas/moyen de gamme réel (pas seulement un émulateur haut de gamme) avant chaque publication majeure — les performances perçues varient énormément selon le matériel.

---

## 6. Publication (App Store / Play Store)

- Versionnement cohérent (semver) à chaque publication, avec changelog associé.
- Permissions demandées à l'app (caméra, stockage, contacts éventuellement) : demander uniquement ce qui est réellement utilisé, et au moment où l'utilisateur en a besoin (permission contextuelle), pas toutes au démarrage.
- Politique de confidentialité à jour et cohérente avec les données réellement collectées (obligatoire pour la publication sur les stores).
- Déploiement progressif (staged rollout) recommandé pour toute mise à jour majeure touchant à l'auth, aux paiements, ou aux règles Firestore — jamais un déploiement à 100% des utilisateurs d'un coup pour un changement sensible.

---

## 7. Checklist avant chaque publication en production

- [ ] Listes critiques (feed, chat, notifications) paginées et testées avec un volume réaliste de données
- [ ] Gestion du mode hors ligne vérifiée sur les écrans principaux
- [ ] Crashlytics (ou équivalent) actif et remonte bien les erreurs de test
- [ ] Tests automatisés passants pour les écrans critiques
- [ ] Testé sur au moins un appareil bas/moyen de gamme réel
- [ ] Permissions demandées limitées au strict nécessaire
- [ ] Changelog rédigé et version incrémentée correctement
