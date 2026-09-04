# Stratégie RSpec, non-régression et fidélité visuelle

## Décision

RSpec devient le framework de test canonique de SEOS dès le démarrage du code. Aucun lot fonctionnel ne doit être construit avant son installation, afin que tous les générateurs produisent directement des specs et qu'aucune suite Minitest parallèle ne se développe.

État actuel constaté :

- aucune gem RSpec dans le `Gemfile` ;
- arborescence Minitest vide, hors `test_helper.rb` ;
- Capybara et Selenium WebDriver déjà déclarés ;
- aucun test métier existant à migrer ;
- `yarn build` disponible pour le JavaScript, mais le CSS n'est pas encore intégré au bundle esbuild.

RSpec Rails 8.x est la branche correspondant à Rails 8 selon la [documentation officielle de RSpec Rails](https://github.com/rspec/rspec-rails). La version stable exacte doit être résolue et verrouillée par Bundler au moment de F-001 avec Rails 8.1.3.1.

## Installation prévue, non exécutée

Le futur lot F-001 devra :

1. ajouter `rspec-rails` aux groupes développement/test ;
2. ajouter les outils de fixtures/factories, couverture et requêtes externes retenus ;
3. exécuter `bundle exec rails generate rspec:install` ;
4. configurer les générateurs Rails pour RSpec ;
5. conserver Capybara/Selenium pour les system specs JavaScript ;
6. créer le binstub `bin/rspec` si retenu ;
7. retirer le squelette Minitest vide une fois RSpec opérationnel ;
8. faire échouer la CI si une commande de scaffold recrée des tests Minitest.

Commandes de référence futures :

```bash
bundle exec rspec
bundle exec rspec spec/models spec/services spec/policies spec/requests
bundle exec rspec spec/system
bundle exec rspec --tag visual
bundle exec rspec --tag accessibility
yarn build
```

## Arborescence cible

```text
spec/
  factories/
  fixtures/
    files/
    visual/
      default_theme/
  models/
  services/
  policies/
  queries/
  requests/
  routing/
  jobs/
  mailers/
  system/
    visitor/
    member/
    organization/
    partner/
    admin/
    super_admin/
  visual/
  accessibility/
  support/
    authentication_helpers.rb
    role_shared_examples.rb
    visual_regression.rb
    accessibility.rb
    active_job.rb
  rails_helper.rb
  spec_helper.rb
```

Les données de test doivent être minimales, explicites et indépendantes. Les factories ne doivent pas créer silencieusement dix associations ou déclencher des callbacks financiers sans que le scénario le demande.

## Pyramide de tests obligatoire

| Type de spec | Cible | Obligation |
|---|---|---|
| Model | validations, relations, scopes, contraintes | Chaque modèle et chaque invariant local |
| Service | transitions, calculs, idempotence, transactions | Tout objet métier sensible |
| Policy | accès par rôle, propriété, permission | Chaque action et les six audiences |
| Query | filtres, tris, pagination, tableaux admin | Chaque recherche complexe |
| Request | routes, paramètres, statuts, réponses, fuite de données | Chaque endpoint public/protégé/admin |
| Job | retries, idempotence, erreurs, effets asynchrones | Chaque job Solid Queue |
| Mailer | destinataire, contenu minimal, aucune donnée interdite | Chaque e-mail transactionnel |
| System | parcours complet dans un navigateur | Chaque user story et interaction JS critique |
| Visual | comparaison avec la maquette/baselines | Chaque page, viewport, état et thème par défaut |
| Accessibilité | clavier, focus, noms accessibles, contrastes automatisables | Chaque gabarit et parcours majeur |

Les controller specs isolées ne sont pas la stratégie principale. Les request specs vérifient le comportement HTTP réel et les system specs le comportement humain avec Turbo/Stimulus.

## Paquet de tests exigé pour chaque feature

Chaque F-xxx du plan de construction doit livrer :

- au moins une spec de succès métier ;
- chaque erreur métier connue ;
- une policy spec partagée pour visiteur, membre, association, partenaire, admin et super-admin ;
- une request spec par route et méthode ;
- une spec de non-divulgation des champs privés applicables ;
- une system spec du parcours principal ;
- une system spec JavaScript pour chaque interaction Stimulus/Turbo ;
- les specs de jobs/mailers déclenchés ;
- la visual spec des pages ou composants modifiés ;
- un identifiant `US-xx`, `MAQ-xx` ou `F-xxx` dans la description/métadonnée afin de maintenir la traçabilité.

Une feature sans équivalent admin doit démontrer par une spec que l'absence est volontaire. Une feature administrable doit tester lecture, modification permise, action interdite et audit.

## Matrice d'autorisation partagée

Créer des shared examples RSpec pour éviter les oublis :

- `publicly readable` ;
- `member owned resource` ;
- `organization owner/manager/editor permissions` ;
- `admin permission required` ;
- `super admin only` ;
- `sensitive data masked` ;
- `append only resource` ;
- `audited mutation`.

Pour chaque action, tester au minimum : non connecté, mauvais membre, propriétaire, membre d'organisation sans permission, editor, manager, owner, admin sans droit, admin avec droit et super-admin.

## Domaines critiques à couverture renforcée

### Points Services

- aucune route ou modèle d'achat/vente/conversion ;
- somme des écritures égale à zéro ;
- solde jamais négatif ;
- double soumission et concurrence ;
- idempotence par source ;
- opération validée impossible à éditer/détruire ;
- correction par écriture compensatrice ;
- bonus, quêtes et chaînes crédités une seule fois.
- valorisations indicatives versionnées sans endpoint d'achat/conversion ;
- bonus après N échanges et Bronze/Argent/Gold appliqués selon la version référencée ;
- publication concurrente, date d'effet, simulation et rollback sans modifier l'historique.

### Trust Score et parrainage

- 0/1/3/5/10 codes, score attendu 53/58/62/69 ;
- onzième code, doublon, code expiré/réutilisé et auto-parrainage refusés ;
- provisoire → confirmé → objecté/invalidé ;
- un seul parrain principal et 15 PS une fois après qualification ;
- formule bornée, déterministe et reproductible ;
- dilution du parrainage par les échanges ;
- score par tâche jamais influencé par un code ;
- avis double aveugle et paire plafonnée ;
- aucune sanction importante sans revue humaine ;
- recalcul/version/rollback et recours.

### Données privées

- e-mail, téléphone, adresse, coordonnées précises, messages et risque interne absents du HTML/JSON public ;
- média sans EXIF de localisation ;
- révélation admin motivée, temporaire et auditée ;
- export temporaire et purgé ;
- profil public accessible au visiteur avec annonces et Trust Score seulement.

### Administration et organisations

- aucun namespace admin accessible indirectement ;
- partenaire sans accès aux données membres ;
- editor/manager/owner réellement distincts ;
- super-admin seul pour thème, reset global, carte et algorithme Trust ;
- objets append-only sans route update/destroy ;
- actions de masse et exports limités.
- blacklist catégories/termes et traitement contrôlé des annonces existantes ;
- règles de chaîne illimitées/limitées, gains et plafonds réservés au super-admin ;
- aucune politique de conservation personnelle globale à vie.

### SEO, Schema.org et GEO

- canonical, meta et JSON-LD identiques au contenu public visible ;
- `Service` pour une offre, `Offer` uniquement avec une fonction non commerciale explicite validée, `Demand/Service` pour une demande et `ItemList` pour le catalogue ;
- aucune PII dans HTML, Open Graph, JSON-LD ou sitemap ;
- sitemap limité aux annonces actives/indexables avec `lastmod` réel ;
- filtres/tri/carte sans duplication indexable ;
- cycles `published`, `paused`, `closed`, `removed`, fusion/redirection ;
- profil public accessible mais `noindex` au lancement ;
- robots bloquant compte/admin/preview et distinguant recherche/entraînement ;
- blacklist rendant l'annonce non publiable/non indexable ;
- absence de prix EUR Schema.org pour les Points Services.

### Contact, providers et soutien dormant

- visiteur autorisé à écrire à l'équipe, jamais à un annonceur ;
- Devise : inscription, confirmation, récupération, suspension et révocation ;
- Google OmniAuth : succès, refus, state invalide, dissociation et scopes minimaux ;
- Gmail API : succès, quota, timeout, retry idempotent et aucun secret loggé ;
- Geocoder : réponse, quota, panne, cache et coordonnées publiques arrondies ;
- carte Leaflet non chargée si flag faux ;
- Stripe : aucune route/CTA flag faux, webhook signé/idempotent flag actif et aucune écriture PS.

## Tests JavaScript et CSS

### JavaScript

Les interactions présentes dans la maquette doivent être testées dans un navigateur avec JavaScript actif :

- navigation mobile et menu de profil ;
- filtres, tris, pagination Turbo et vue carte ;
- favoris, modales, toasts et consentements ;
- assistant de publication et conservation des étapes ;
- messagerie, notifications et états de chargement ;
- ajout de 0 à 10 codes de parrainage ;
- dashboard membre/organisation/admin ;
- preview, publication et reset du Studio UI ;
- séparateurs organiques animés et fallback reduced-motion.

Une spec système doit d'abord exécuter `yarn build` dans la CI ou dépendre d'un artefact construit. Aucun test ne doit réussir en utilisant un vieux fichier `app/assets/builds/application.js`.

### Contrats CSS

Le thème SEOS par défaut possède des assertions déterministes sur :

- valeurs de tokens ;
- polices/graisses ;
- largeurs de conteneurs et breakpoints ;
- rayons, espacements, ombres et gradients majeurs ;
- états hover/focus/disabled/loading ;
- absence de scroll horizontal ;
- ordre et présence des sections ;
- chargement effectif du CSS produit par esbuild.

Les thèmes personnalisés sont testés contre le schéma et les seuils d'accessibilité, pas contre les pixels de la maquette par défaut.

## Régression visuelle fidèle à la maquette

### Baseline

La maquette `docs/maquette.html` est la référence visuelle initiale. Avant de découper les pages, capturer dans un environnement déterministe les pages/états de la maquette aux largeurs :

- `320`, `375`, `414`, `768`, `1024`, `1280` et `1440px` ;
- zoom normal, plus vérification fonctionnelle à 200 % ;
- états visiteur, membre, Association et admin visibles dans la maquette ;
- menus, modales, filtres, carte, wizard, dashboards et pages légales.

Les fontes et le navigateur doivent être verrouillés dans la CI pour éviter les écarts dus au rendu local.

### Comparaison

Les RSpec system specs capturent les nouvelles pages puis un matcher visuel compare dimension et pixels avec les PNG de référence. Le choix prévu est un comparateur Ruby déterministe fondé sur ChunkyPNG ou équivalent, appelé depuis RSpec.

- objectif : aucune différence intentionnelle pour le thème par défaut ;
- tolérance technique maximale : `0,5 %` des pixels pour l'anticrénelage, jamais pour masquer un décalage de layout ;
- tokens, dimensions critiques et ordre de sections : tolérance zéro ;
- artefacts CI : attendu, obtenu et image diff ;
- toute différence dépassant le seuil fait échouer la CI.

Une baseline n'est jamais actualisée automatiquement. Sa modification exige : décision produit, capture avant/après, revue humaine et motif dans la pull request. Le reset du Studio UI doit toujours revenir à cette référence par défaut.

## Tests du Studio UI et des contenus

- default theme impossible à modifier/supprimer ;
- brouillon isolé des visiteurs ;
- preview signée, sans indexation et sans cache public ;
- publication atomique et invalidation des caches ;
- reset token, composant, page, média, séparateur, thème et site complet ;
- reset créant une nouvelle version sans effacer l'historique ;
- rollback vers une version antérieure ;
- rejet de CSS, JavaScript, SVG ou HTML arbitraire ;
- contraste, alt text, hiérarchie de titres et URL contrôlés ;
- séparateur statique/animé, hauteur réservée, pause hors écran et reduced motion ;
- image supprimée remplacée par le média par défaut ;
- contenu manquant remplacé par le fallback versionné ;
- double publication concurrente et lock optimiste ;
- audit complet de l'auteur, de l'ancienne version et de la nouvelle.

## Tests du feature flag Carte

### Carte activée

- bouton Liste/Carte visible ;
- carte accessible et alternative liste disponible ;
- détail `in_person` ou `hybrid` avec zone publique : carte autorisée et marqueur approximatif uniquement ;
- détail `remote` : aucun conteneur, script, distance ou marqueur, mais bloc « À distance — France » ;
- carte globale : toutes les annonces filtrées présentes, les `remote` dans un panneau sans marqueur et les `in_person/hybrid` reliées à leur marqueur ;
- total global égal à `physiques/hybrides + distantes`, sans double comptage d'une annonce hybride ;
- déplacement du viewport sans disparition des annonces distantes correspondant aux autres filtres ;
- tri de proximité absent pour une annonce `remote` ;
- prestataire chargé après consentement si nécessaire ;
- erreurs réseau sans perte des résultats.

### Carte désactivée

- bouton et conteneur carte absents ;
- aucun script, tuile, cookie ou appel réseau du prestataire ;
- catalogue, recherche par zone/rayon et pagination toujours fonctionnels ;
- liens partagés demandant la carte retombent vers la liste ;
- seul le super-admin peut réactiver ; l'action est auditée ;
- les résultats `in_person`, `hybrid` et `remote` restent tous consultables en liste.

## Couverture et seuils

Les pourcentages ne remplacent pas les scénarios, mais servent de filet :

- 100 % des user stories et lignes de la matrice maquette reliées à une spec ;
- 100 % des actions de policy testées pour leurs rôles applicables ;
- 100 % des transitions Points/Trust/parrainage/modération couvertes ;
- couverture globale cible : au moins 95 % des lignes et 90 % des branches ;
- aucune baisse de couverture acceptée sans justification ;
- domaines critiques : chaque branche métier identifiée possède un exemple, même si l'outil de couverture compte différemment.

Les specs ne doivent pas tester des méthodes privées pour gonfler la couverture. Elles testent le contrat observable, les sorties comptables, les transitions et les droits.

## Pipeline CI prévu

1. installation Ruby/Yarn avec caches verrouillés ;
2. `yarn build` et vérification des artefacts JS/CSS ;
3. préparation de la base de test ;
4. specs rapides : model/service/policy/query/request/job/mailer ;
5. system specs JavaScript ;
6. visual specs et artefacts diff ;
7. accessibility specs ;
8. contrats SEO : canonical, robots, sitemap, JSON-LD et absence de PII ;
9. contrats providers simulés sans appel réel : Gmail, OAuth, géocodage, tuiles et Stripe ;
10. RuboCop, Brakeman et audit des dépendances ;
11. contrôle de couverture et matrice de traçabilité ;
12. échec global dès qu'une étape échoue.

Les tests peuvent être parallélisés par groupe, sans partager les fichiers de capture ni les clés d'idempotence. Les échecs intermittents sont corrigés ; ils ne sont ni relancés jusqu'au vert ni placés durablement en quarantaine.

## Critère de lancement

SEOS n'est pas prêt à déployer tant que :

- une feature F-xxx n'a pas son paquet RSpec complet ;
- le thème par défaut diffère involontairement de la maquette ;
- une interaction Stimulus n'a pas de system spec JavaScript ;
- un rôle manque dans une policy spec ;
- un reset ou un feature flag n'est pas testé dans les deux états ;
- une annonce indexable n'a pas ses contrats canonical/sitemap/Schema.org/GEO ;
- une règle de barème/chaîne/conservation publiée n'a pas simulation, historique et rollback ;
- la suite complète, le build et les audits ne passent pas sur une base vierge.

## Références

- [RSpec Rails — installation, types de specs et system specs](https://github.com/rspec/rspec-rails)
- [RSpec Rails 8 — documentation](https://rspec.info/features/8-0/rspec-rails/)
- [Capybara — documentation officielle](https://github.com/teamcapybara/capybara)
