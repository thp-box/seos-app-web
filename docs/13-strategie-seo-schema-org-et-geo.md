# Stratégie SEO, Schema.org et GEO

## Objectif

Chaque annonce publique et active doit devenir une page utile, compréhensible et indexable qui alimente la visibilité organique de SEOS, sans transformer les membres en source de pages artificielles ni exposer leurs données privées.

Le SEO vise les moteurs de recherche classiques. Le GEO (« Generative Engine Optimization ») vise la compréhension et la citation du contenu par les expériences de recherche générative. Pour SEOS, les deux reposent sur le même socle : contenu original, structure technique claire, données exactes, entités stables, fraîcheur et respect des utilisateurs.

Google précise qu'aucune optimisation spéciale n'est nécessaire pour ses fonctions génératives : les bonnes pratiques SEO restent déterminantes. Les fichiers artificiels ou pages créées uniquement pour les IA ne remplacent pas un site public de qualité.

## Décisions de périmètre

- lancement limité à la France et au français (`fr-FR`) ;
- chaque annonce membre `published` et autorisée est candidate à l'indexation ;
- brouillons, annonces en pause, retirées, bloquées ou trop pauvres restent `noindex` et hors sitemap ;
- le profil public reste accessible au visiteur avec annonces et Trust Score, mais conserve le `noindex` recommandé au lancement ;
- aucune coordonnée, adresse exacte, latitude/longitude précise, message, solde, signalement ou score de risque interne n'entre dans le HTML SEO, les métadonnées, les sitemaps ou le JSON-LD ;
- le balisage Schema.org est produit par l'application depuis les données validées ; ni membre ni administrateur ne saisit du JSON-LD libre ;
- la désactivation de la carte n'affecte pas l'indexation des annonces ni leurs localisations publiques approximatives ;
- une annonce `remote` reste indexable comme service disponible à distance sans carte, distance ou coordonnées artificielles ; une annonce `in_person/hybrid` peut exposer seulement sa zone publique dans `areaServed` ;
- aucune promesse de position, de rich result ou de citation par une IA n'est faite.

## Architecture des pages d'annonces

### Une URL canonique par annonce

Format prévu : `/annonces/:slug`, avec un slug lisible, stable, non dérivé d'une donnée privée et complété par un identifiant interne non exposé comme donnée personnelle.

Chaque page possède :

- une URL canonique absolue auto-référente ;
- un `<title>` unique centré sur le service, la catégorie et la zone publique ;
- une meta description factuelle issue d'un résumé contrôlé ;
- un `h1` unique et une structure de titres cohérente ;
- le contenu principal rendu côté serveur, utilisable sans attendre Stimulus ;
- des images indexables seulement si elles sont publiées, pertinentes, réencodées et sans EXIF ;
- des liens internes vers catégorie, zone, mode d'échange, profil public et annonces proches ;
- une date de publication et une date de modification réellement significative ;
- un JSON-LD cohérent avec ce qui est visible à l'écran.

### Critères d'indexabilité

Une annonce est `indexable` uniquement si :

1. son statut est publié et sa période de validité n'est pas terminée ;
2. le compte et le profil public ne sont ni suspendus ni restreints ;
3. titre, description, catégorie, intention, mode et zone/remote sont suffisamment renseignés ;
4. la catégorie n'est pas blacklistée ou soumise à une vérification absente ;
5. le contenu ne contient pas de coordonnées, spam, duplication excessive ou texte interdit ;
6. l'annonce possède une URL canonique et son rendu public retourne `200` ;
7. les données Schema.org générées correspondent exactement au contenu visible.

Une annonce non indexable peut rester accessible aux personnes autorisées sans être envoyée aux moteurs.

## Graphe Schema.org

JSON-LD est le format retenu. Chaque entité possède un `@id` absolu et stable afin que les moteurs puissent relier site, organisation, page, annonce, service, auteur public et fil d'Ariane.

| Page | Types principaux | Rôle |
|---|---|---|
| Accueil | `WebSite`, `Organization`, `WebPage` | Nom et identité officielle de SEOS |
| Catalogue | `CollectionPage`, `ItemList`, `BreadcrumbList` | Liste paginée d'annonces canoniques |
| Annonce « offre » | `WebPage`, `Service`, `BreadcrumbList` ; `Offer` facultatif et encadré | Service proposé par un membre ou une organisation, sans le présenter par défaut comme une vente |
| Annonce « demande » | `WebPage`, `Demand`, `Service`, `BreadcrumbList` | Besoin exprimé, sans le présenter comme une offre commerciale |
| Profil public | `ProfilePage`, `Person` | Identité d'affichage et activité publique minimale |
| Association | `ProfilePage`, `Organization` ou `NGO` si réellement applicable | Fiche publique de l'organisation vérifiée |
| Partenaire | `ProfilePage`, `Organization` | Fiche publique et nature du partenariat |
| Mission | `WebPage` + type métier pertinent ; `Event` seulement si un événement daté est réellement organisé | Éviter un faux `JobPosting` pour une mission non salariée |
| Journal/article | `Article`, `Person` ou `Organization`, `BreadcrumbList` | Contenu éditorial daté et attribué |
| Contact | `ContactPage`, `Organization`, `ContactPoint` | Contact de l'équipe SEOS, jamais celui d'un annonceur |
| Pages explicatives/légales | `AboutPage`, `WebPage` ou `CollectionPage` | Information officielle et versionnée |

### Propriétés d'une offre de service

Le `Service` est l'entité principale et décrit uniquement les données publiques : nom, description, catégorie, zone via `areaServed`, possibilité à distance, image publique, URL et fournisseur public.

`Offer` n'est pas ajouté automatiquement. Schema.org lui attribue une fonction commerciale de vente lorsque `businessFunction` est absent, ce qui décrirait mal un don, un échange ou un transfert de Points Services. Il ne pourra être activé que si la phase d'implémentation valide une `businessFunction` explicite adaptée au service non vendu et un mapping fidèle à chaque mode. À défaut, `Service` seul est plus exact. Ce balisage sémantique ne promet aucun résultat enrichi Google.

Les Points Services ne sont pas une monnaie achetable. Ils ne doivent donc pas être balisés comme un prix en euros ni avec une `priceCurrency`. Les modes `don`, `échange` et `points` utilisent des propriétés additionnelles explicites propres à SEOS, visibles également dans la page.

### Propriétés d'une demande

Une demande utilise `Demand` et place le `Service` recherché dans `itemOffered`, avec la zone publique, la date, la validité et l'URL. Elle ne doit jamais être transformée artificiellement en produit ou en offre payante pour obtenir un rich result.

### Profil et Trust Score

Le profil peut déclarer `ProfilePage` et une `Person` limitée à `display_name`, avatar public, description choisie et zone large. Le Trust Score SEOS ne devient pas automatiquement un `AggregateRating` : ce calcul composite n'est pas une simple moyenne d'avis et Google ne garantit pas de rich result d'avis pour une personne. Les avis structurés restent affichés dans la page, avec leur provenance réelle, sans faux auteur ni note cachée.

## Catalogue, pages locales et anti-duplication

- Le catalogue principal et ses pages paginées possèdent une structure stable.
- Les combinaisons libres de filtres, tris, rayons et vues liste/carte ne créent pas des milliers de pages indexables.
- Les paramètres de tri, vue et carte pointent vers la canonique pertinente.
- La carte globale contient toutes les annonces filtrées dans l'expérience utilisateur, mais ce regroupement ne crée pas une nouvelle URL indexable pour chaque viewport. Les annonces à distance restent des résultats sans marqueur et conservent leur URL canonique propre.
- Une page catégorie/zone dédiée n'est indexée que si elle contient un inventaire réel, un texte utile et une valeur distincte ; aucune page « ville + service » vide ou quasi dupliquée n'est générée.
- Le maillage relie les annonces aux catégories et zones réelles, sans bourrage de mots-clés.
- Les résultats vides et recherches internes restent `noindex`.

## Sitemaps, fraîcheur et cycle de vie

Un index de sitemaps sépare au minimum : pages statiques, annonces, articles, organisations et missions. Seules les URLs canoniques indexables sont incluses. `lastmod` change uniquement lorsqu'un contenu public significatif change.

Cycle attendu :

| État | Réponse/indexation |
|---|---|
| Publiée | `200`, canonical, JSON-LD et sitemap |
| Mise en pause | `200` ou accès membre selon décision, `noindex`, retirée du sitemap |
| Clôturée avec page utile temporaire | `200`, statut clairement visible, `noindex`, propositions actives liées |
| Supprimée définitivement sans remplacement | `410` recommandé |
| Fusionnée/remplacée | `301` vers la nouvelle URL pertinente |
| Suspendue/modérée | `404` public ou page minimale `noindex`, jamais d'explication accusatoire indexable |

La Google Indexing API ne doit pas être détournée pour les annonces SEOS : elle est officiellement réservée aux pages `JobPosting` et aux événements diffusés en direct. Les sitemaps, le maillage et Search Console sont le mécanisme principal.

## GEO : visibilité dans les moteurs génératifs

### Contenu citables et compréhensible

- réponse courte et factuelle au début des pages explicatives ;
- informations structurées en sections nommées : service, zone, modalités, disponibilité, sécurité, mode d'échange ;
- vocabulaire cohérent entre HTML, titres, JSON-LD et liens internes ;
- contenu original du membre conservé, nettoyé et enrichi par des champs structurés, jamais remplacé par du texte SEO automatique générique ;
- date de mise à jour, statut actif et origine du contenu visibles ;
- pages officielles expliquant Points Services, Trust Score, parrainage, sécurité et gouvernance ;
- sources officielles citées dans les articles informatifs lorsque nécessaire ;
- entités SEOS, catégories et organisations reliées par des `@id` stables.

### Accès des crawlers

La politique `robots.txt` distingue les usages :

- autoriser les crawlers de recherche retenus uniquement sur les pages publiques indexables ;
- bloquer `/compte`, `/admin`, `/super_admin`, previews, exports, callbacks, recherches internes et URLs signées ;
- autoriser `OAI-SearchBot` si SEOS souhaite apparaître dans la recherche ChatGPT ;
- décider séparément de `GPTBot`, lié à l'entraînement, car OpenAI documente ces contrôles comme indépendants ;
- ne jamais considérer `robots.txt` comme une protection d'une donnée qui aurait été publiée par erreur ;
- suivre les crawlers dans les logs agrégés sans profiler les visiteurs humains.

`llms.txt` n'est pas un prérequis du lancement. Il pourra être réévalué si un standard interopérable et adopté apparaît, mais ne doit pas retarder les pages canoniques, le contenu utile et les sitemaps.

## Administration SEO/GEO

### Administrateur habilité

- voit les annonces non indexables et la raison ;
- corrige/modère les titres, descriptions, médias et coordonnées accidentelles avec historique ;
- gère les redirections après fusion ou changement de slug ;
- consulte erreurs de sitemap, canonical et Schema.org ;
- peut demander une réévaluation, sans forcer artificiellement l'indexation.

### Super-admin

- configure les gabarits de titres/descriptions et les règles d'indexabilité ;
- active les types Schema.org autorisés et leurs versions ;
- gère domaines canoniques, identité `Organization`, robots et politiques de crawlers ;
- crée les pages locales éditoriales autorisées ;
- pilote Search Console, rapports GEO, redirects globaux et feature flags ;
- remet chaque configuration SEO/GEO au défaut système versionné ;
- ne peut pas injecter de JSON-LD, script ou balise arbitraire sans passage par le code et les tests.

Le Studio permet d'éditer `seo_title`, `seo_description`, image sociale et contenu visible. Les entités/relations Schema.org sont générées depuis les modèles métier pour empêcher une divergence entre contenu et balisage.

## Protection des membres et contenu indexé

Avant publication, le membre est informé qu'une annonce publique peut être copiée/indexée par des moteurs classiques ou génératifs. Il prévisualise exactement les données rendues publiques.

- avertissement anti-coordonnées dans titre, description et images ;
- détection puis revue des e-mails, téléphones, adresses et identifiants externes ;
- localisation limitée à ville/zone/département ou rayon suffisamment large ;
- retrait public et sitemap rapides après fermeture, modération ou exercice d'un droit ;
- procédure de déréférencement lorsque le cache d'un tiers persiste ;
- conditions de publication interdisant contenu copié, trompeur, illégal ou sans droits ;
- blacklist catégories/mots-clés administrable, versionnée et auditée.

## Mesure

Tableau de bord sans promesse de classement :

- annonces publiées, indexables, exclues et raisons ;
- couverture des sitemaps et erreurs Schema.org ;
- pages découvertes/indexées, impressions, clics et requêtes via Search Console ;
- clics organiques vers inscription/contact protégé ;
- fraîcheur moyenne et annonces retirées encore visibles chez un tiers ;
- trafic référent identifiable provenant des moteurs génératifs ;
- crawls par user-agent autorisé, erreurs `4xx/5xx` et budget de crawl ;
- pages locales sans inventaire, contenu dupliqué ou taux de modération élevé.

Les métriques produit internes sont agrégées côté serveur. Aucun outil analytics tiers n'est nécessaire au lancement ; son ajout futur exige finalité, consentement lorsque requis, contrat et feature flag.

## RSpec et recette

- JSON-LD parseable sur chaque type de page et conforme au contrat de type/propriétés ;
- correspondance stricte entre données visibles et données structurées ;
- absence de données privées dans HTML, meta, Open Graph, JSON-LD, sitemap et logs SEO ;
- offre → `Service`, avec `Offer` seulement si sa fonction non commerciale explicite est validée ; demande → `Demand/Service` ;
- aucun prix EUR ou achat associé aux Points Services ;
- canonical unique malgré tri, filtre, pagination et vue carte ;
- sitemap contenant seulement les annonces actives/indexables avec `lastmod` exact ;
- transitions publiée/pause/clôture/suppression/fusion ;
- blacklist empêchant publication et indexation ;
- carte désactivée sans effet sur la page serveur indexable ;
- détail `remote` sans carte ni donnée géographique inventée, et carte globale conservant ce résultat hors marqueurs ;
- profil `noindex` mais accessible au visiteur ;
- robots bloquant comptes, administration et previews ;
- politiques `OAI-SearchBot` et `GPTBot` testées indépendamment ;
- aucune page locale vide ou combinaison de filtre indexable ;
- régression des titres, descriptions, images sociales et données structurées à chaque publication Studio.

## Références officielles

- [Schema.org — Service](https://schema.org/Service)
- [Schema.org — Offer](https://schema.org/Offer)
- [Schema.org — Demand](https://schema.org/Demand)
- [Google Search — principes généraux des données structurées](https://developers.google.com/search/docs/appearance/structured-data/sd-policies)
- [Google Search — ProfilePage](https://developers.google.com/search/docs/appearance/structured-data/profile-page)
- [Google Search — optimisation pour les fonctions d'IA générative](https://developers.google.com/search/docs/fundamentals/ai-optimization-guide)
- [Google Search — créer et envoyer un sitemap](https://developers.google.com/search/docs/crawling-indexing/sitemaps/build-sitemap)
- [Google Search — URLs canoniques](https://developers.google.com/search/docs/crawling-indexing/consolidate-duplicate-urls)
- [Google Search — limites de l'Indexing API](https://developers.google.com/search/apis/indexing-api/v3/quickstart)
- [OpenAI — crawlers de recherche et d'entraînement](https://developers.openai.com/api/docs/bots)
- [CNIL — durées de conservation](https://www.cnil.fr/fr/passer-laction/les-durees-de-conservation-des-donnees)
