# Dossier de conception SEOS

Engagement, chaînes et soutien dormant : [suivi de la phase 5](./19-suivi-phase-5.md).

Registre et barèmes Points Services : [suivi de la phase 4](./18-suivi-phase-4.md).

État du chantier confiance et parrainage : [suivi de la phase 3](./17-suivi-phase-3.md).

Ce dossier transforme la maquette et les user stories existantes en une base de travail exploitable pour construire l'application Rails. Il s'agit de la spécification établie le 4 septembre 2026. Le code a commencé depuis : voir le [suivi des phases 1 et 2](./15-suivi-phases-1-et-2.md) pour l’état actuel de livraison, et le [bilan initial du socle](./14-analyse-et-suivi-phase-0.md) pour son historique.

## Sources analysées

- [`maquette.html`](./maquette.html) : prototype interactif et direction artistique.
- [`user-story.md`](./user-story.md) : exigences fonctionnelles obligatoires et fil rouge du produit.
- Le squelette Rails existant : configuration, `Gemfile`, `package.json`, `Procfile.dev`, layout et pipeline d'assets.
- Le panneau d'administration de [`THP-Lab/template-marketplace`](https://github.com/THP-Lab/template-marketplace), étudié comme référence d'organisation et non comme code à recopier.

## Hiérarchie des exigences

1. Les user stories sont des exigences à ne pas oublier : chacune doit conserver une trace dans le backlog et un critère d'acceptation, même si elle est livrée dans un lot ultérieur.
2. Toutes les fonctionnalités visibles dans la maquette appartiennent au périmètre produit. Une priorité P1/P2 organise leur livraison ; elle ne les annule pas.
3. Les précisions produit consignées dans ce dossier arbitrent les ambiguïtés entre les deux sources. C'est notamment le cas du profil public : il reste consultable par un visiteur, mais sans coordonnées privées.
4. Les recommandations techniques et juridiques restent à valider avant implémentation lorsqu'elles engagent le budget, un prestataire ou la conformité.

## Décisions produit consolidées

- Les Points Services ne peuvent être ni achetés, ni vendus, ni convertis en euros : ils circulent entre membres ou proviennent des bonus/quêtes/chaînes prévus par SEOS.
- Un nouveau membre peut saisir jusqu'à dix codes de parrains distincts pendant son inscription ou ses sept premiers jours.
- Chaque code valide pèse `0,25` dans le score global provisoire : 1, 3, 5 et 10 codes produisent environ 53, 58, 62 et 69/100, toujours avec la mention « données limitées ».
- Les parrainages n'affectent aucun score de compétence ; leur poids se dilue automatiquement avec les échanges réels.
- Un seul parrain principal peut terminer la quête de parrainage et recevoir `15 PS`, une seule fois, après qualification du nouveau membre.
- Les profils, annonces, associations et partenaires possèdent des pages publiques dédiées ; aucune de ces pages ne rend les coordonnées privées visibles.
- `SEOS Default v1` est le reflet exact et immuable de la maquette ; le super-admin peut publier des variantes UI/contenus puis réinitialiser chaque périmètre vers cette référence.
- Le super-admin peut activer/désactiver toute l'expérience cartographique ; désactivée, elle ne charge aucune ressource ni requête du fournisseur. Une carte sur le détail d'une annonce est réservée aux services `in_person` ou `hybrid`. La carte globale conserve toutes les annonces dans ses résultats, mais les annonces `remote` n'obtiennent jamais de faux marqueur.
- RSpec est la suite canonique de toutes les features, y compris autorisations, concurrence, JavaScript et non-régression visuelle.
- Une seule commande `yarn build` doit produire les sorties JavaScript et CSS de l'application.
- Toutes les annonces actives et sûres alimentent le SEO/GEO via URL canonique, sitemap et JSON-LD Schema.org généré, sans donnée privée.
- Lancement France/français ; Devise, Gmail API, Google OmniAuth, Geocoder/Leaflet et vidéo interne retenus ; analytics tiers désactivés.
- Valorisation PS, bonus/niveaux et chaînes sont versionnés par le super-admin ; chaîne illimitée par défaut.
- Le visiteur contacte uniquement l'équipe ; la blacklist catégories est administrable ; Stripe reste dormant et totalement séparé des PS.
- Aucune conservation globale de données personnelles « à vie » : une politique par finalité doit être juridiquement validée.

## Documents produits

1. [`01-resume-application.md`](./01-resume-application.md) — vision, publics, proposition de valeur, périmètre et parcours.
2. [`02-analyse-maquette-user-stories.md`](./02-analyse-maquette-user-stories.md) — audit de couverture, incohérences, règles métier et décisions à prendre.
3. [`03-modele-de-donnees.md`](./03-modele-de-donnees.md) — schéma relationnel proposé, contraintes, statuts et sécurité des données.
4. [`04-plan-scaffolds-rails-8.md`](./04-plan-scaffolds-rails-8.md) — ordre de construction, générateurs recommandés et stratégie Rails 8/esbuild.
5. [`05-kit-ui-ux.md`](./05-kit-ui-ux.md) — design system fidèle à la maquette, composants, responsive et audit d'accessibilité.
6. [`06-backlog-features.md`](./06-backlog-features.md) — inventaire des fonctionnalités, priorités, critères de sortie et risques.
7. [`07-panel-administration.md`](./07-panel-administration.md) — grand back-office, navigation, permissions, matrices CRUD et garde-fous.
8. [`08-systeme-trust-score.md`](./08-systeme-trust-score.md) — score de confiance par type de tâche, calcul, parrainage, avis structurés et anti-fraude.
9. [`09-rgpd-profils-publics.md`](./09-rgpd-profils-publics.md) — visibilité visiteur/membre/admin, profil public et cadre RGPD/CNIL.
10. [`10-plan-construction-feature-par-feature.md`](./10-plan-construction-feature-par-feature.md) — ordre de chantier prêt à coder, avec données, pages, rôles et critères de sortie pour chaque feature.
11. [`11-strategie-tests-rspec-et-regression.md`](./11-strategie-tests-rspec-et-regression.md) — architecture RSpec, matrices de tests, couverture, CI et régression visuelle.
12. [`12-studio-ui-contenus-carte-et-separateurs.md`](./12-studio-ui-contenus-carte-et-separateurs.md) — édition UI/contenus, versions, resets, carte activable et séparateurs organiques.
13. [`13-strategie-seo-schema-org-et-geo.md`](./13-strategie-seo-schema-org-et-geo.md) — SEO des annonces, Schema.org, sitemaps, canonical, GEO, crawlers et confidentialité.

## Niveaux de certitude

Les documents utilisent trois niveaux pour ne pas confondre démonstration et décision produit :

- **Obligatoire** : explicitement demandé dans les user stories.
- **Inclus par la maquette** : présent dans le prototype et donc à prendre en compte, avec une règle métier encore à préciser si nécessaire.
- **Recommandé / à arbitrer** : proposition de conception à confirmer avant développement.

## Photo technique au 4 septembre 2026 (avant implémentation)

| Élément | État constaté |
|---|---|
| Framework | Rails `8.1.3.1` verrouillé dans `Gemfile.lock` |
| Ruby | `3.4.7` |
| Base de données | SQLite en développement, test et production |
| Assets | Propshaft `1.3.2` |
| JavaScript | Hotwire, Turbo, Stimulus et esbuild `0.28.2` |
| Node / Yarn | Node `24.8.0`, Yarn Classic `1.22.22` |
| Build actuel | `yarn build` compile le JavaScript vers `app/assets/builds` |
| Développement | `bin/dev` lance Rails et `yarn build --watch` |
| CSS actuel | CSS natif servi par Propshaft, sans bundler CSS configuré |
| Tests actuels | RSpec absent ; squelette Minitest sans test métier |
| Cible assets | CSS importé par le point d'entrée JS ; `yarn build` produit JS + CSS |
| Cible tests | RSpec Rails 8, système JS, autorisations, régression fonctionnelle et visuelle |
| Domaine applicatif | Aucun modèle métier ni route métier pour le moment |

## Ordre de validation conseillé

Avant de générer le code, valider successivement :

1. les décisions bloquantes restantes dans l'analyse fonctionnelle ;
2. les critères de calcul, d'affichage et de contestation du Trust Score ;
3. la matrice de visibilité des profils et des coordonnées ;
4. le périmètre MVP du backlog sans supprimer les lots ultérieurs ;
5. le vocabulaire métier et le modèle de données ;
6. la stratégie d'authentification, d'autorisation et d'accès administrateur ;
7. le contrat CSS/JS esbuild et les baselines visuelles ;
8. la stratégie RSpec, les seuils de couverture et la revue des baselines ;
9. les schémas du Studio, les granularités de reset, les presets organiques et le flag carte ;
10. les règles des Points Services et des chaînes d'entraide ;
11. la stratégie SEO/Schema.org/GEO et le cycle d'indexation des annonces ;
12. les versions de valorisation, bonus, niveaux et règles de chaîne ;
13. les contenus juridiques, l'AIPD, les durées de conservation, les prestataires et les prérequis Stripe.

Une fois ces points arbitrés, le plan de scaffolds peut servir de checklist d'implémentation.

Le démarrage du code doit suivre les phases et identifiants du plan feature par feature, de F-001 à F-073 avec les identifiants volontairement non continus. Une feature est livrée verticalement avec son équivalent visiteur, membre, association, partenaire, admin et super-admin applicable ; elle ne doit pas être reportée dans un « admin à faire plus tard ».
