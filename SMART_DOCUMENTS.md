# SMART_DOCUMENTS.md — Exigences de qualité pour le Smart CV, la lettre de motivation et le portfolio

Ce document cadre la génération des trois livrables documentaires de Kaïro. L'objectif : un rendu qui ressemble à ce qu'un designer professionnel produirait manuellement, pas à un template générique rempli automatiquement.

---

## 1. Règles communes de rendu (CV, lettre, portfolio)

### Typographie
- Une seule famille de police par document, deux graisses maximum (regular + bold/semibold). Pas de mélange de polices "pour faire joli".
- Taille de corps de texte : jamais en dessous de 9.5pt en PDF final (lisibilité à l'impression).
- Interlignage entre 1.15 et 1.4 — jamais serré au point que les lignes se touchent, jamais aéré au point de sembler du remplissage vide.
- Hiérarchie visuelle claire : titre du document > sections > sous-titres > corps de texte, avec une échelle de taille cohérente (ex. 24/14/11/10pt), pas de tailles choisies au hasard.

### Mise en page et pagination
- Une page pour le CV et la lettre de motivation, **sauf** profils avec 10+ ans d'expérience où 2 pages sont acceptables — mais jamais une page à moitié vide suivie d'un débordement de 3 lignes sur une seconde page. Si ça déborde de peu, il faut soit compresser le contenu, soit ajuster les marges/interlignage, jamais laisser un rendu "cassé".
- Marges cohérentes sur toutes les pages (recommandé : 15-20mm), jamais de marge asymétrique non voulue.
- Aucun élément ne doit être coupé à cheval sur un saut de page (une expérience professionnelle ou un paragraphe ne doit jamais être scindé en haut/bas de page).
- Alignement strict des éléments répétés (dates alignées à droite, puces alignées entre elles) — les décalages de pixels sont ce qui trahit un rendu "généré" plutôt que "designé".

### Génération PDF
- Le texte du PDF doit rester du texte sélectionnable/copiable, jamais une image rasterisée de la mise en page (impact direct sur le passage des filtres ATS et sur l'accessibilité).
- Polices embarquées dans le PDF (pas de dépendance à une police système absente chez le destinataire).
- Format A4 par défaut ; Letter en option si on vise un marché nord-américain plus tard.
- QR code : taille minimum garantissant la scannabilité (2x2cm minimum imprimé), placé dans une zone qui ne gêne jamais la lecture du contenu principal.

### Cohérence entre les 4 templates du Smart CV
- **Moderne** et **Créatif** peuvent utiliser de la couleur et des colonnes, mais toujours une seule couleur d'accent + noir/gris pour le texte — jamais plus de 2 couleurs au total.
- **Classique** : zéro couleur d'accent en dehors du noir/gris, structure linéaire, c'est le template "sûr" pour candidatures institutionnelles/administrations.
- **ATS-optimisé** : contrainte stricte — pas de colonnes, pas de tableaux, pas d'icônes, pas d'images, pas d'en-tête/pied de page contenant des infos essentielles (beaucoup de parseurs ATS ignorent ces zones). Titres de section en texte simple et standard ("Expérience professionnelle", "Formation", "Compétences") — pas de titres créatifs ("Mon parcours", "Ce qui me passionne") qui ne seront pas reconnus par le parseur.

---

## 2. Qualité du contenu généré (texte)

### CV
- Verbes d'action en début de ligne pour les expériences ("Piloté", "Conçu", "Augmenté de X%") plutôt que des descriptions passives ("Était responsable de...").
- Prioriser les résultats quantifiés quand l'information existe dans le profil utilisateur (chiffres, %, durée) plutôt que des généralités.
- Ne jamais inventer de chiffres ou de résultats non fournis par l'utilisateur — si l'agent génère une suggestion de formulation, elle doit rester fidèle aux données du profil, jamais enjolivée avec des faits non vérifiés.
- Longueur des puces d'expérience : 1 à 2 lignes maximum chacune, jamais des paragraphes.

### Lettre de motivation
- Structure standard francophone : accroche personnalisée → lien entre le profil et le poste/l'entreprise → valeur ajoutée concrète → formule de politesse standard.
- Personnalisation réelle : si l'utilisateur renseigne le poste/l'entreprise visée, la lettre doit les citer explicitement — jamais une lettre générique avec des champs `[Entreprise]` non remplis dans le rendu final.
- Longueur cible : 250 à 400 mots. Une lettre plus longue signale presque toujours un manque de synthèse.
- Éviter les formulations toutes faites détectées comme génériques par les recruteurs ("Passionné depuis toujours par...", "Je vous prie de bien vouloir agréer...") — proposer des formulations plus directes et spécifiques au profil.

### Portfolio
- Chaque projet affiché doit avoir : titre, rôle de l'utilisateur dans le projet, résultat/impact, et un visuel ou lien — jamais un projet listé sans contexte de contribution.
- Si un visuel de projet est de mauvaise qualité (résolution basse, ratio incohérent avec les autres), l'agent doit le signaler plutôt que de l'intégrer tel quel dans une grille qui sera visuellement cassée.
- Cohérence de ratio d'image dans la grille de portfolio (tout en 16:9 ou tout en carré, jamais mélangé) pour un rendu propre.

---

## 3. Validation avant livraison d'un document généré

Avant de considérer un CV/lettre/portfolio comme "prêt", l'agent doit vérifier :

- [ ] Aucun débordement de texte hors des marges ou des cadres
- [ ] Aucune coupure d'élément à cheval sur deux pages
- [ ] Aucune donnée inventée non présente dans le profil utilisateur
- [ ] Le template ATS ne contient ni colonne, ni tableau, ni icône
- [ ] Le texte du PDF est sélectionnable (pas une image)
- [ ] Cohérence des couleurs/polices avec les règles du template choisi
- [ ] Personnalisation réelle si poste/entreprise renseignés (lettre de motivation)

---

## 4. Point d'attention produit

Si l'utilisateur n'a pas assez d'informations dans son profil (ex. pas d'expérience renseignée), l'agent ne doit **jamais** générer un contenu artificiellement étoffé pour "remplir" le document. Mieux vaut un document court et honnête qu'un document dense mais fabriqué — c'est aussi une question de crédibilité pour l'utilisateur final face à un recruteur.
