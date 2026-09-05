# SEOS France

Plateforme d’entraide locale en Rails 8.1. Le socle comprend désormais les premiers parcours des phases 1 et 2 : profils, annonces, demandes, conversations, accords, avis et modération.

Le périmètre actuel et les compléments à construire figurent dans le [suivi des phases 1 et 2](docs/15-suivi-phases-1-et-2.md). Le [bilan initial du socle](docs/14-analyse-et-suivi-phase-0.md) reste historique. Le [dossier de conception](docs/README.md) reste la référence fonctionnelle.

## Démarrer

Prérequis : Ruby **3.4.7**, Bundler **2.7.2**, Node **24.8.0**, Yarn Classic **1.22.22**, SQLite 3 et libvips.

```bash
bin/setup --skip-server
bin/dev
```

Ouvrir <http://localhost:3000>. `bin/dev` lance Rails et esbuild en watch. `yarn build` reconstruit ensemble le JS, le CSS et les polices locales. Les sorties sont servies et fingerprintées par Propshaft.

En développement, les e-mails sont écrits dans `tmp/mail/`, sans envoi externe. Après inscription, ouvrir le lien de confirmation contenu dans le fichier. Ce répertoire contient des liens privés et reste ignoré par Git. `bin/setup` nettoie `tmp/`, puis reconstruit les assets.

## Accès

- `/auth/inscription`, `/auth/connexion` : création et connexion ; e-mail confirmé obligatoire.
- `/annonces` : catalogue, recherche, carte et détails publics.
- `/compte` : compte personnel, profil, annonces, échanges, favoris et notifications.
- `/journal`, `/decouvrir/:slug`, `/legal/:slug`, `/contact` : contenus publiés et contact équipe.
- `/admin` : dashboard ; listes membres et audit selon permission.
- `/super_admin` : gestion des administrateurs, permissions temporaires et carte publique.
- `/admin/gestion/:kind` : catégories, restrictions, annonces, profils, échanges, signalements, contenus et contacts, selon permission.
- `/organisations/:slug/espace` : espace réservé aux memberships actifs d’une organisation vérifiée ; équipe réservée aux propriétaires/gestionnaires.

### Comptes de démonstration

En développement, `bin/setup` crée les données de démonstration lors de l’initialisation d’une base vide. Pour les ajouter à une base existante ou relancer les seeds :

```bash
bin/rails db:seed
```

| Compte | E-mail | Accès |
| --- | --- | --- |
| Membre | `membre@seos.test` | Compte personnel |
| Super-admin | `superadmin@seos.test` | Administration et gestion des permissions |
| Responsable d’association | `association@seos.test` | Compte personnel, espace et équipe de l’association |

Mot de passe initial des trois comptes : **`SeosDemo2026!`**. Ils sont actifs et déjà confirmés ; connexion sur `/auth/connexion`, sans e-mail à valider.

L’association **Entraide solidaire — Démo** est vérifiée. Son responsable est un membre avec une adhésion propriétaire active ; son espace se trouve sur `/organisations/entraide-solidaire-demo/espace` et est accessible depuis `/compte`.

Les identités de démonstration sont réservées au développement : aucun compte n’est créé en test ou en production. Les seeds ajoutent aussi les profils, quatre catégories, trois annonces et des pages explicatives en développement. Les critères d’avis et le flag carte sont des références chargées dans tous les environnements. Elles peuvent être relancées sans doublons et conservent les mots de passe, rôles, statuts et données déjà modifiés.

### Initialisation manuelle du super-admin

Dans un environnement sans compte de démonstration, pour initialiser le premier super-admin, créer et confirmer un compte puis exécuter :

```bash
EMAIL=adresse-du-compte@example.test bin/rails seos:bootstrap_super_admin
```

La commande refuse de s’exécuter si un super-admin existe déjà. Elle journalise l’initialisation et révoque les sessions du compte. Reconnectez-vous ensuite. Un changement de rôle ultérieur passe par le panneau super-admin et un motif obligatoire.

## Vérifier

```bash
yarn build
yarn build:check
bundle exec rspec
bin/check-exchange-concurrency
bin/rubocop
bin/brakeman --no-pager
bin/bundler-audit
yarn audit
```

`bin/ci` regroupe setup, assets, autoload, analyses et RSpec. La suite couvre les requêtes HTTP, les modèles, les services, les policies, les parcours Chrome, les captures et l’accessibilité. Un build absent, périmé ou altéré fait échouer RSpec. Les générateurs produisent des fichiers `spec/`, pas de suite Minitest.

Chrome for Testing **151.0.7922.77** est verrouillé dans `.chrome-version`. Selenium peut l’installer ; pour utiliser une installation existante, définir `CHROME_BIN` et `CHROMEDRIVER_BIN`. Les captures visuelles supposent Linux et le navigateur verrouillé. La CI installe explicitement Chrome et son driver. Elle archive couverture, captures/diffs et rapport JUnit.

La couverture de la suite complète exige **95 % de lignes et 90 % de branches**. Pour travailler sur une seule spec : `COVERAGE=0 bundle exec rspec spec/requests/authentication_spec.rb` ; ce réglage ne remplace pas la validation complète.

Les références PNG initiales du **socle** sont dans `spec/fixtures/visual/foundations`. Elles couvrent accueil et connexion aux sept largeurs prévues. Elles ne constituent pas encore une comparaison exhaustive à la maquette. Aucune référence existante n’est remplacée par les tests. Pour produire des candidats à examiner :

```bash
COVERAGE=0 CAPTURE_VISUAL_CANDIDATES=1 bundle exec rspec --tag visual
```

Les candidats restent dans `tmp/screenshots/`. Leur adoption demande une revue explicite du rendu et du diff ; le mode capture est interdit en CI.

## Base et sécurité

Le schéma canonique est `db/structure.sql` : il conserve aussi les triggers SQLite qui interdisent de modifier/supprimer l’audit. Les migrations ajoutent clés étrangères, unicités et contraintes de rôles/statuts. Les données de développement restent dans `storage/`.

Les sessions sont limitées à 30 minutes d’inactivité et 12 heures au maximum. L’administration exige une confirmation du mot de passe datant de moins de 15 minutes. Les mots de passe changés et les changements de rôle révoquent les sessions. Les jetons de session sont stockés sous forme de condensat ; les agents utilisateurs sont résumés sans conservation de l’IP.

Les images passent par un contrôle MIME/taille, réencodage et retrait des métadonnées, puis une route autorisée `/medias/:id`. Les routes génériques Active Storage restent fermées. La carte publique utilise Leaflet dans un bundle distinct, uniquement lorsque le flag est actif. `MAP_TILE_URL` remplace le fond OSM par défaut. Aucun OAuth, analytics ou Stripe n’est chargé.

## Suite du chantier

La [phase 3](docs/17-suivi-phase-3.md) ajoute le parrainage, le moteur Trust versionné, les recours humains et la revue interne des signaux. Entrées : `/compte/confiance`, `/confiance`, `/admin/confiance`. Les seeds préparent `v1.0` en brouillon : simulation, seconde approbation et calcul en ombre précèdent toute activation publique. Aucun point n’est crédité ; le registre appartient à la phase 4. Redémarrer `bin/dev` après migration pour recharger routes et filtres de paramètres. Les recalculs nécessitent les jobs ; `bin/rails runner 'TrustMaintenanceJob.perform_now'` permet un passage local explicite.

Restent notamment Google OmniAuth, Gmail API avec réconciliation des envois, la vidéo, les outils admin avancés et les Studios complets F-008/F-009. Les compléments propres aux phases 1 et 2 sont détaillés dans leur suivi. L’inscription n’enregistre pas encore d’acceptation de CGU versionnées : les documents légaux et la politique d’âge restent à valider et intégrer. Cette tranche est destinée au développement, pas à une ouverture en production.
