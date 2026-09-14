# Espace utilisateur — reprise de la maquette

La présentation de l’espace personnel reprend les cartes blanches arrondies, les titres serif, les accents dorés et bleus et les proportions du dashboard de `maquette.html`. La navigation conserve les catégories exclusives repliables demandées précédemment. Le Studio admin garde son propre habillage.

## Rubriques

- **Aperçu** : solde disponible, niveau et progression fondés sur les transferts éligibles du membre, dernier échange, chaîne accessible et cinq dernières écritures comptabilisées. Lire cet écran ne crée aucun portefeuille et n’accorde aucune récompense.
- **Annonces** : aperçu des quatre premières annonces publiques, tableau de toutes les annonces avec leurs actions existantes. Les brouillons et annonces non publiques restent dans le tableau. L’assistant de création conserve ses quatre étapes.
- **Quêtes** : grille illustrée avec les photographies locales de la maquette, icônes configurées par l’administration, progression et récompense indicative suivant le niveau et le barème. Les validations, plafonds et règles métier restent applicables. Les illustrations ne sont pas des preuves de réalisation.
- **Témoignages** : page distincte `/compte/temoignages`, accessible dans la sidebar. Elle regroupe le formulaire écrit/vidéo, le suivi des décisions et le retrait du consentement. Les quêtes et les preuves de récompenses restent dans « Mes quêtes ». Les anciens envois de témoignages à `/compte/engagement` restent compatibles et redirigent vers cette nouvelle page.
- **Portefeuille** : solde dans l’en-tête, historique compact et daté, lien vers les échanges, accueil explicite et formulaire de preuve repliable.
- **Chaînes** : participants réels et services confirmés dans la liste ; parcours visuel des services dans le détail. La création d’invitation privée reste une action explicite.
- **Favoris** : cartes des annonces disponibles et bouton de retrait.
- **Échanges** : liste des demandes et filtres ; détail avec navigation entre les conversations, messages alignés selon l’auteur et formulaire d’envoi. Accord, réalisation, avis et médiation restent accessibles sous la messagerie.
- **Avis reçus** : nouvelle entrée de navigation qui regroupe les avis déjà révélés du membre connecté. Aucun avis différé ni avis destiné à un tiers n’est exposé. Les réponses passent par l’échange existant.
- **Profil et paramètres** : aperçu d’avatar, formulaire public/privé organisé en colonnes, liens vers les droits, cookies et identifiants. Les données privées ne sont pas rendues publiques pour copier la maquette.
- **Autres fonctionnalités** : notifications, sessions, organisations, candidatures, confiance/parrainage, soutien et confidentialité utilisent le même habillage de titres, cartes, formulaires et actions. L’édition des identifiants rejoint le layout du compte ; inscription et connexion restent publiques.

## Adaptation et limites

Les valeurs de démonstration des captures (128 PS, avis 4,8/5, vues des annonces, distances et badges de messages) ne sont pas inventées. L’aperçu propose le dernier échange réel plutôt qu’une fausse recommandation géolocalisée. La progression du niveau dépend des échanges en Points Services, pas du solde. Les règles de progression cumulative des quêtes sont conservées.

Les formulaires, permissions et transitions serveur sont conservés. Aucun changement de schéma ni migration nécessaire. Les photos existantes sont servies par les routes média autorisées. Les animations respectent la réduction des mouvements et n’atténuent pas le contraste des textes.

## Vérification

Les tests dédiés `account_dashboard_spec` couvrent le rendu des rubriques, l’absence de crédit à la lecture, la confidentialité des avis, les écrans à 375 et 1440 pixels, l’accessibilité, les cartes avec photos et l’envoi réel d’un message. Les captures de contrôle sont dans `tmp/screenshots/dashboard-*`. Compléter ces tests par les suites compte, points, engagement, échanges et authentification lors d’une modification de ce parcours.
