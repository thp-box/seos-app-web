# SEOS France

Plateforme d’entraide locale en Rails 8.1. Les livraisons des phases 0 à 7 couvrent profils, annonces, échanges, confiance, Points Services, organisations et outils d’administration.

Le [reste à faire et à vérifier](docs/23-reste-a-faire-et-verifier.md) décrit les limites actuelles. Le [dossier de conception](docs/README.md) regroupe les spécifications et suivis de livraison.

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

La [phase 4 — Points Services](docs/18-suivi-phase-4.md) fournit `/compte/points`, `/points-services` et `/admin/points` : registre en partie double, transfert à la seconde confirmation, accueil de 30 PS à valider, récompenses avec preuves, ajustements prévisualisés et barèmes versionnés. Les seeds préparent les références sans créditer les comptes. `PointMaintenanceJob` assure le rattrapage via le worker ; les quêtes et chaînes complètes sont désormais raccordées par la phase 5.

La [phase 3](docs/17-suivi-phase-3.md) ajoute le parrainage, le moteur Trust versionné, les recours humains et la revue interne des signaux. Entrées : `/compte/confiance`, `/confiance`, `/admin/confiance`. Les seeds préparent `v1.0` en brouillon : simulation, seconde approbation et calcul en ombre précèdent toute activation publique. Le registre des points est désormais fourni par la phase 4. Redémarrer `bin/dev` après migration pour recharger routes et filtres de paramètres. Les recalculs nécessitent les jobs ; `bin/rails runner 'TrustMaintenanceJob.perform_now'` permet un passage local explicite.

Le [Studio admin](docs/24-studio-mon-site-et-kit-maquette.md) offre un accueil commun sur `/admin`, avec des menus selon les permissions. Le super admin dispose de **Personnalisation** : création guidée de pages, contenu par parties, haut et bas du site, images et kit UI/UX issu de la maquette. Un aperçu et un récapitulatif précèdent la mise en ligne. Les validations de lancement et les compléments métier restent suivis dans la checklist, notamment les CGU versionnées et la politique d’âge.

La [phase 5 — Engagement communautaire](docs/19-suivi-phase-5.md) ajoute les quêtes, Top annonces, témoignages écrits/vidéo et chaînes d’entraide : `/compte/engagement`, `/compte/chaines`, `/temoignages`, `/admin/engagement`. Le module Stripe de `/admin/soutien` reste désactivé par défaut. FFmpeg et FFprobe sont nécessaires au traitement vidéo et sont inclus dans le Dockerfile.

La [phase 6 — Organisations, Voyage et partenariats](docs/20-suivi-phase-6.md) ajoute `/compte/organisations`, `/compte/candidatures`, `/associations`, `/voyage-solidaire`, `/partenaires` et `/admin/organisations`. Les seeds préparent une mission et un partenariat en brouillon pour l’association de démonstration. Les annonces monde restent publiées exclusivement par le super-admin.

### Phase 7 : confidentialité et pilotage

Après `bundle install`, `bin/rails db:migrate`, `bin/rails db:seed` et `yarn build`, redémarrer l’application et les workers. Nouveaux espaces : `/compte/confidentialite`, `/admin/confidentialite`, `/admin/operations`, `/admin/studio` et `/preferences-confidentialite`.

Les comptes locaux `admin@seos.test` et `partenaire@seos.test` complètent les trois comptes existants, avec `SeosDemo2026!`. L’admin reçoit des droits de démonstration limités à 30 jours ; le partenaire possède une organisation en attente de revue. Aucun de ces comptes n’est créé en production.

Voir [le suivi de phase 7](docs/21-suivi-phase-7.md) et [le guide d’exploitation](docs/22-exploitation-et-recette.md) pour Google/Gmail, sauvegardes, recette et limites de lancement. Le logiciel livré ne vaut pas validation juridique des durées de conservation ou de l’ouverture au public.
