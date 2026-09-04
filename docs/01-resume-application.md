# Résumé de l'application SEOS

## En une phrase

SEOS est une plateforme francophone d'entraide locale qui permet de proposer ou demander un service selon trois modes — don, échange de compétences ou Points Services — puis de sécuriser la mise en relation, la validation et la réputation des membres.

## Problème traité

Des personnes disposent de temps ou de savoir-faire, tandis que d'autres ont besoin d'une aide ponctuelle. Les plateformes classiques reposent souvent sur l'argent, exposent trop vite les coordonnées personnelles ou n'offrent pas de cadre de confiance suffisant.

SEOS propose un cadre commun :

- rendre visibles les besoins et les compétences ;
- préserver les coordonnées avant accord ;
- organiser les échanges dans une messagerie interne ;
- reconnaître l'entraide avec une réputation et, selon le mode choisi, des Points Services ;
- prolonger un service rendu par une chaîne d'entraide.

## Publics

| Public | Besoin principal | Accès envisagé |
|---|---|---|
| Visiteur | Comprendre SEOS et explorer les annonces | Pages publiques, catalogue et détail public limité |
| Membre | Publier, répondre, échanger, suivre son activité | Espace personnel complet |
| Association vérifiée | Publier des missions solidaires | Espace membre avec permission Association |
| Organisation partenaire | Présenter une coopération avec SEOS | Page publique Partenaire et espace organisation limité si nécessaire |
| Administrateur | Modérer et auditer | Back-office opérationnel |
| Super-administrateur | Administrer les administrateurs et les contenus globaux | Back-office étendu |

Les statuts Association et Partenaire appartiennent à une organisation reliée à un ou plusieurs utilisateurs. Ils ne remplacent pas le rôle système du compte. Une association peut gérer ses missions ; un partenaire ne reçoit aucun accès aux données des membres du seul fait de son partenariat.

Le lancement vise exclusivement la France et une interface française (`fr-FR`). Les autres pays et langues constituent une extension future, pas un comportement caché de la V1.

## Proposition de valeur

### Trois modes d'entraide

1. **Don** : service offert sans contrepartie.
2. **Échange** : compétences ou services échangés selon des modalités librement négociées.
3. **Points Services** : unité interne non achetable, non vendable et non convertible en euros, estimée avant l'échange puis confirmée après le service.

Les Points Services proviennent uniquement des transferts entre membres après échange confirmé et des émissions prévues par les règles de l'application : inscription, quêtes, chaînes ou correction administrative motivée. Les équivalences indicatives, bonus et barèmes de niveau sont versionnés par le super-admin afin d'évoluer sans recoder, mais ne transforment jamais les PS en monnaie achetable ou convertible.

Un soutien financier à SEOS reste totalement séparé et ne donne ni points, ni niveau, ni Trust Score. Une intégration Stripe Checkout peut être préparée derrière un flag désactivé ; elle sert uniquement à un don/contribution volontaire et ne peut être ouverte avant validation juridique, comptable et de l'entité bénéficiaire.

### Confiance et protection

- profils de service publics accessibles aux visiteurs, avec pseudonyme ou prénom + initiale, zone approximative, annonces, avis vérifiés et Trust Score explicable ;
- score de confiance global et par famille de tâches, accompagné d'un niveau de fiabilité du calcul et non d'une promesse de sécurité absolue ;
- avis structurés autorisés uniquement après un échange réellement validé ;
- jusqu'à dix codes de parrainage distincts pouvant former un score global provisoire plus élevé dès l'inscription, avec poids plafonné puis dilué par les échanges réels ;
- messagerie interne avant divulgation volontaire des coordonnées ;
- localisation publique limitée à une commune ou une zone approximative ;
- signalements traités par l'administration ;
- historique de Points Services auditable et non modifiable silencieusement.

L'e-mail, le téléphone, le nom civil complet, l'adresse exacte, les messages, le solde de points, les signalements et les signaux de risque internes ne figurent jamais sur le profil public. Une coordonnée peut seulement être partagée volontairement dans un contexte d'échange protégé et traçable.

### Boucle d'engagement

La maquette ajoute des quêtes, niveaux Bronze/Argent/Gold, récompenses, Top annonces, parrainage et témoignages. Cette boucle est intéressante pour l'activation, mais doit rester secondaire par rapport à l'échange réel et être protégée contre les doubles récompenses et la fraude.

## Parcours principaux

### Découverte publique

Accueil → explication des trois modes → catégories → annonces → détail → inscription ou connexion au moment d'une action protégée. Le visiteur peut contacter l'équipe SEOS via la page Contact, mais ne peut ni écrire à l'annonceur ni créer une demande sans compte.

### Publication

Connexion → intention « proposer » ou « rechercher » → mode d'échange → détails et médias → aperçu → acceptation des règles → publication.

La maquette prévoit quatre étapes et préremplit l'adresse depuis le profil. Seule la zone publique doit apparaître dans l'annonce ; l'adresse exacte reste privée.

### Demande et échange

Détail d'annonce → proposition ou question → conversation → accord sur les modalités → service réalisé → double confirmation → éventuel transfert de points → avis.

La proposition, la réalisation, la confirmation et le transfert sont des états distincts. Un simple clic dans l'interface ne doit jamais débiter immédiatement des points sans opération serveur atomique et idempotente.

### Chaîne d'entraide

Membre A déclare avoir aidé B → lien unique envoyé à B → B s'identifie et valide → récompense attribuée selon les règles → B peut aider C à son tour.

Cette fonctionnalité est distincte des annonces. La chaîne est illimitée par défaut : un nouveau maillon peut toujours prolonger l'entraide. Le super-admin publie des versions de règles permettant, si nécessaire, d'activer une fin, d'en fixer la longueur, de choisir quels maillons sont récompensés et de borner le gain par validation et par membre. Toute configuration est simulée avant activation afin de rendre l'émission maximale compréhensible.

### Mission associative

Association vérifiée → formulaire dédié → contrôle d'une contribution maximale de 15 € par jour → publication durable → retrait par l'association ou l'administration.

La rubrique « Voyage solidaire » est activable globalement par l'administration dans la maquette.

### Administration

Le back-office est une tour de contrôle transverse : utilisateurs et profils publics, annonces, échanges, conversations sous accès motivé, Points Services, Trust Score, parrainages, signalements, quêtes, chaînes, organisations, missions, contenus, conformité, paramètres et audit. L'administration peut gérer presque tout, mais ne peut pas réécrire l'histoire : écritures de points, preuves de confiance, confirmations, messages et journaux d'audit sont corrigés par statut, masquage, décision de modération ou écriture compensatrice, jamais par édition silencieuse.

Le super-administrateur est seul habilité à gérer les administrateurs, les permissions les plus sensibles, les versions de calcul du Trust Score et certains paramètres globaux. Il pilote aussi les barèmes Points/niveaux/chaînes, la carte publique, le SEO/GEO et un Studio versionné permettant de modifier puis réinitialiser le kit UI/UX, les textes, descriptions, CTA, images, SEO et séparateurs organiques de chaque page. Les admins habilités et le super-admin gèrent la blacklist des catégories. Les données personnelles sont masquées par défaut, même dans le back-office.

La carte suit deux règles distinctes. Sur le détail d'une annonce, elle apparaît uniquement si le service comporte une intervention physique (`in_person` ou `hybrid`), possède une zone publique exploitable et si le flag global est actif. Une annonce `remote` affiche « À distance — France » sans carte ni coordonnées. Dans la vue cartographique globale du catalogue, toutes les annonces correspondant aux filtres restent présentes : les services physiques/hybrides portent des marqueurs approximatifs, tandis que les services 100 % à distance occupent un groupe ou panneau « À distance » sans faux point géographique. Le compteur total distingue ces deux ensembles.

Chaque annonce active, autorisée et suffisamment complète possède une URL canonique indexable, un contenu serveur utile, des données Schema.org générées et une entrée de sitemap. Elle contribue ainsi au SEO et au GEO de SEOS sans exposer l'adresse exacte, les coordonnées ou les signaux privés de son auteur. Une annonce trop pauvre, blacklistée ou modérée reste hors index.

## Profil de service public

Le profil public est une page utile avant toute inscription. Il rassemble :

- un identifiant d'affichage non civil et un avatar facultatif ;
- une commune ou zone large, la date d'ancienneté et les langues/compétences choisies ;
- les annonces actives et l'historique agrégé des échanges confirmés ;
- le Trust Score global, ses dimensions pertinentes, sa catégorie de confiance statistique et la version de calcul ;
- les avis structurés publiables, les badges et les catégories dans lesquelles la personne a déjà rendu service ;
- les actions « voir une annonce », « signaler » et « contacter après connexion ».

Ce profil ne donne pas accès aux coordonnées. Son objectif est d'aider à choisir un partenaire d'échange, pas d'exposer la vie privée ni de classer la valeur sociale d'une personne.

## Carte des espaces

| Espace | Écrans visibles dans la maquette |
|---|---|
| Public | Accueil, Don, Échange, Points Services, Annonces, Détail, Chaîne, Voyage solidaire, Centre légal |
| Authentification | Connexion/inscription Devise, Google au lancement ; Facebook prévu mais désactivé |
| Publication | Assistant d'annonce en 4 étapes |
| Membre | Aperçu, annonces, quêtes, portefeuille, chaînes, favoris, messagerie, avis, profil, confidentialité |
| Association | Création d'une mission solidaire |
| Organisations | Annuaire et fiches publiques Associations/Partenaires, espace de gestion selon habilitation |
| Administration | Tour de contrôle complète, Studio UI/contenus, médiathèque, resets et activation de la carte/rubriques |
| Hors maquette mais demandé | Gestion des utilisateurs, audit complet des points, CRUD des succès, journal de bord, création d'administrateurs, commentaires |

## Séquençage conseillé

Les lots ci-dessous définissent un ordre de livraison et non une réduction du produit. Les user stories restent obligatoires et toutes les fonctions de la maquette restent inscrites dans le backlog.

### MVP

- pages publiques et catalogue en liste/carte, avec interrupteur super-admin, marqueurs physiques et résultats à distance séparés ;
- authentification, profils et autorisations ;
- annonces et catégories ;
- demandes de service, conversation et notifications ;
- confirmation d'échange ;
- portefeuille et registre des Points Services ;
- favoris, avis vérifiés et signalements ;
- Trust Score initial, avis structurés et profil de service public ;
- administration des membres, annonces, échanges, confiance et transactions.

### Version suivante

- commentaires publics modérés ;
- quêtes, succès, niveaux et Top annonces ;
- chaînes d'entraide ;
- organisations et missions solidaires ;
- journal de bord ;
- authentification sociale ;
- recherche géographique avancée au-delà du rayon initial.

Ce séquençage réduit le risque : la comptabilité des points, les permissions, la réputation et la modération doivent être solides avant d'activer les mécanismes de récompense les plus faciles à détourner.

## Socle technique déjà choisi

- Rails 8.1 avec vues ERB et conventions REST ;
- Devise pour comptes, confirmations, sessions et récupération ; Google via OmniAuth comme premier login social ;
- Turbo pour la navigation et les mises à jour partielles ;
- Stimulus pour les interactions ciblées : menus, filtres, assistant, galerie, modales et préférences ;
- esbuild pour regrouper le JavaScript **et** le CSS importé depuis le point d'entrée JavaScript ; `yarn build` doit produire les deux ;
- Propshaft pour servir et digérer les assets ;
- Active Storage pour images, vidéos et preuves ;
- Action Text recommandé pour les articles longs du journal de bord ;
- Solid Queue pour les e-mails, notifications et traitements médias asynchrones ;
- Gmail API via le client Ruby Google pour l'envoi transactionnel, secrets hors base ;
- Geocoder pour le géocodage/recherche et Leaflet pour la carte, fournisseur de tuiles configurable ;
- vidéo HTML5 via Active Storage et analytics tiers désactivés au lancement ;
- JSON-LD Schema.org, sitemaps et pages rendues côté serveur pour SEO/GEO ;
- SQLite acceptable au démarrage, sous réserve de garder des transactions courtes et des index adaptés.
- RSpec comme suite canonique, avec tests de règles, permissions, requêtes, jobs, parcours JavaScript et non-régression visuelle de la maquette.

## Indicateurs produit utiles

- délai entre inscription et première action utile ;
- nombre d'annonces actives par zone et catégorie ;
- taux de réponse et délai de première réponse ;
- taux de demandes transformées en échanges validés ;
- taux de litige ou de signalement ;
- couverture et fiabilité statistique du Trust Score par catégorie ;
- taux d'avis réciproques anormaux, de comptes liés et de contestations acceptées ;
- délai de traitement d'une contestation du Trust Score ;
- volume de points émis, transférés et annulés ;
- rétention à 30 jours ;
- proportion d'échanges en don, échange libre et points ;
- accessibilité et performance des parcours clés.
