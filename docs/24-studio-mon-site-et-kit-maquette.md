# Studio admin : pages et apparence du site

Livraison du 7 septembre 2026. Complète le Studio partiel de la phase 7. Les données et versions déjà présentes sont conservées ; aucune publication ni modification de la base de développement n’est effectuée par cette livraison.

## Accès et utilisation

Le menu du compte propose une seule entrée **Studio admin**. L’accueil et la sidebar affichent les outils autorisés pour la personne connectée. **Personnalisation** est réservée au super admin ; un administrateur ordinaire conserve ses outils métier selon ses permissions. L’ancienne adresse de l’accueil super admin redirige vers cet accueil commun.

### Modifier ou créer une page

1. Ouvrir **Personnalisation → Pages et sections**, puis **Modifier cette page** sur la page souhaitée.
2. Pour une nouvelle page, cliquer sur **Créer une page**, saisir son **Nom**, puis **Créer et écrire le contenu**. Son adresse est générée automatiquement ; elle n’est pas encore publique.
3. Modifier une partie à la fois avec **Modifier le contenu**. Les champs permettent de changer les textes, photos, descriptions alternatives et destinations de boutons. Un texte libre peut rester sans bouton : l’option **Ajouter un bouton (facultatif)** est repliée.
4. Cliquer sur **Enregistrer le contenu** pour revenir à la composition, ou **Enregistrer et voir le résultat** pour passer directement à la vérification.
5. **Ajouter une partie à la page** propose les modèles avec une explication. Les commandes de déplacement, duplication et retrait sont regroupées à part. **Options de présentation** contient le masquage et les décorations.

L’écran principal explique le parcours en trois étapes : choisir une page, modifier son contenu, vérifier et mettre en ligne. Une page vide ne peut pas être publiée depuis ce parcours.

### Modifier les éléments communs et l’apparence

- Les cartes **Haut du site** et **Bas du site** expliquent les éléments partagés : logo, menu, coordonnées et liens utiles. Pour ajouter un lien, remplir la dernière ligne et enregistrer ; pour le retirer, vider ses deux champs.
- **Bibliothèque d’images** permet d’importer un JPEG/PNG/WebP nettoyé ou de réutiliser les photos de la maquette. Une image importée devient publique uniquement lorsqu’une version publiée la référence dans une partie visible ou un logo.
- **Personnalisation → Kit UI/UX** contient les réglages regroupés par couleurs, écriture, formes et espaces, animations et vagues. Les libellés décrivent le résultat visuel. Les exemples issus de la maquette sont disponibles dans une rubrique repliée. Les réglages globaux contrôlent aussi la hauteur, la forme, la durée et l’amplitude des vagues ; l’arrêt des animations et la préférence système de mouvement réduit sont respectés.

### Vérifier et mettre en ligne

1. Enregistrer les changements, puis ouvrir **Voir le résultat**.
2. Choisir la **Page à vérifier** et un aperçu **Téléphone**, **Tablette** ou **Ordinateur**. **Continuer les modifications** permet de revenir à l’éditeur.
3. Relire le récapitulatif : la mise en ligne concerne toutes les modifications de cette copie, y compris les autres pages et les réglages communs.
4. Cliquer sur **Mettre en ligne**. Une confirmation annonce que les visiteurs peuvent voir les changements. Aucun motif technique ni validation intermédiaire n’est demandé à la cliente ; le serveur vérifie le contenu, le contraste, l’intégrité et l’état de la publication, puis valide et publie dans une seule transaction. Si une autre publication a eu lieu depuis l’ouverture de l’aperçu, il faut rouvrir celui-ci.

**Retrouver une ancienne sauvegarde**, replié en bas de l’écran d’entrée, permet de consulter une copie ou de la reprendre pour la vérifier avant publication.

Sur une page éditoriale publique, le super admin dispose également du bouton **Modifier cette page**. Les annonces, échanges, comptes, paiements et autres parcours métier gardent leurs contrôleurs et autorisations propres. Le journal et les textes légaux restent accessibles via **Journal, textes légaux et contenus éditoriaux**, dans leur éditeur versionné existant.

Chaque enregistrement crée une nouvelle proposition ; une publication existante ne peut être réécrite. Les onglets ouverts sur deux versions créent deux branches distinctes : il faut choisir la proposition à publier dans l’historique, elles ne fusionnent pas automatiquement.

## Fidélité et provenance

La seule source visuelle du kit est [`maquette.html`](./maquette.html), empreinte SHA-256 :

`83338c404d00e98d13c5722b1cd8fc17f1b234a14cd1d58eaab9954d68c436ce`

- 14 écrans de référence : accueil, don, échange, points, catalogue, détail, publication, authentification, espace membre, chaîne, voyage, administration, validation de chaîne, centre légal.
- 17 sections éditoriales extraites de l’accueil et des trois pages d’échange, plus un bloc texte/bouton pour les contenus libres.
- Les 28 blocs CSS du fichier source, leurs formes organiques, styles de cartes, boutons et points de rupture sont conservés dans une feuille à portée limitée.
- 45 références de photos sont copiées dans `app/assets/images/maquette/`. Leur correspondance exacte avec les URL du prototype figure dans `config/studio/maquette.json`.
- DM Sans, Playfair Display et le logo utilisent les ressources locales existantes. Les couleurs principales du CSS source sont reliées aux variables éditables du thème.

La capture `config/studio/rendered-maquette.html` conserve aussi les vagues SVG, illustrations et composants que le JavaScript du prototype ajoute au chargement. Elle se régénère avec `CHROME_BIN=… CHROMEDRIVER_BIN=… bundle exec ruby scripts/render-maquette.rb` ; tous les accès réseau du navigateur sont bloqués pendant cette capture. Son empreinte source est contrôlée avant extraction.

Le script `ruby scripts/extract-maquette.rb` régénère le catalogue et la feuille `maquette.css`. Il se lance à la racine du dépôt, conserve les images déjà téléchargées, et télécharge une image source seulement si elle manque. Il faut ensuite exécuter `yarn build`. Le fichier source n’est jamais modifié par le Studio.

**« Issu de la maquette » décrit la provenance, pas une certification d’identité pixel par pixel.** Le prototype contient du JavaScript de simulation, des données personnelles fictives et des actions non branchées. Les adaptations suivantes sont explicites :

- les écrans du kit sont inertes, dans une iframe privée ; leurs chiffres et personnes sont signalés comme démonstrations ;
- les sections publiques de catégories, annonces et témoignages utilisent les données réellement publiées, leurs règles de visibilité et de consentement ; les faux témoignages et compteurs de chaîne ne sont pas publiés ;
- la recherche de l’accueil utilise un formulaire GET réel vers le catalogue ; les boutons publics utilisent des routes Rails ou les liens HTTPS choisis par l’éditrice ; le JavaScript du prototype n’est pas exécuté côté application publique ;
- les styles inline deviennent des classes pour respecter la CSP, les images distantes deviennent locales et les identifiants SVG sont isolés entre sections dupliquées ;
- les pages métier ne sont pas remplacées par les écrans de démonstration du kit. Le kit permet d’en examiner les composants ; changer le fonctionnement de ces parcours reste un développement métier.

Les styles globaux modifiables sont les contrôles affichés dans le kit : il ne s’agit pas d’un éditeur de CSS/JavaScript libre. Les textes, images et liens des sections se modifient dans **Pages**. Les photos de témoignages vidéo du prototype ne publient pas une vidéo réelle : la destination du bouton se configure et les vidéos métier conservent leur circuit de consentement et de modération.

## Publication et protections

- Autorisation serveur super admin pour le compositeur, le chrome et le kit. Les permissions historiques de consultation/édition du Studio restent appliquées à l’ancien espace.
- Brouillons privés, réauthentification de l’administration, protection CSRF et absence de cache des aperçus.
- Données déclaratives validées : types de sections, tailles, identifiants uniques, champs connus, images locales/importées et URL du site ou HTTPS. Aucun HTML, CSS ou script fourni par l’éditrice n’est interprété.
- Insertion des textes via les setters DOM avec échappement. Les templates HTML sont des fichiers de référence versionnés dans le dépôt.
- Validation du contraste des couples de couleurs déjà contrôlés par le Studio, puis vérification du digest avant publication. Cette vérification ne remplace pas la recette de tous les contrastes sur une photo ou de chaque combinaison personnalisée.
- Les textes factuels repris du prototype — vérification d’identité, délais de modération, règles de récompense notamment — doivent être relus par l’éditrice avant publication pour correspondre au service réellement proposé.
- Retour au défaut par zone, par page, pour le kit ou pour l’ensemble du site via le Studio historique. Aucun reset n’efface l’historique.
- Une page personnalisée est publiée sous `/pages/:slug`. Les pages explicatives conservent `/decouvrir/:slug`. Les nouvelles pages publiées entrent dans le sitemap.

## Vérification

Les tests couvrent la composition, les autorisations, la publication et les resets, l’échappement, les références médias privées, les pages personnalisées, les contenus éditoriaux existants, les sections dynamiques et les écrans de référence. Les scénarios navigateur suivent la modification de l’accueil et du kit, ainsi que la création d’une page à partir de son nom jusqu’à sa publication. Ils vérifient l’aperçu, le débordement horizontal à 375/1440 px et l’accessibilité de l’éditeur et de l’écran de vérification.

Résultats du 7 septembre 2026 : **296 exemples RSpec, 0 échec** (seed 49637), couverture **98,91 % des lignes / 91,50 % des branches**. RuboCop : 316 fichiers sans infraction restante. Brakeman : 0 avertissement / 0 erreur. Chargement Zeitwerk, build des assets et contrôle de fraîcheur réussis. Le harnais SQLite de concurrence et de sauvegarde/restauration passe dans une base isolée. La précompilation de production réussit ; les assets de développement sont ensuite reconstruits. Les captures de recette sont dans `tmp/screenshots/site-*` ; les références visuelles historiques ne sont pas remplacées automatiquement.

## Organisation de la navigation administrative

La sidebar regroupe les outils sous Personnalisation, Communauté, Annonces et échanges, Confiance et finances, Gestion du site et Administration. Une catégorie sans lien autorisé n’est pas affichée. La rubrique de la page courante s’ouvre automatiquement. Une seule catégorie peut être ouverte à la fois : ouvrir une autre catégorie ferme la précédente, au clic comme au clavier. Le lien actif est mis en évidence. Sur mobile et tablette, toute la navigation se replie également.

Les onglets de Personnalisation ont des écrans d’entrée distincts et conservent le même brouillon lorsqu’on passe des pages au kit. Ouvrir un onglet ne crée aucune version. L’historique et la reprise d’une ancienne version conservent l’onglet choisi.

Recette de la navigation : **300 exemples RSpec, 0 échec** (seed 32712), couverture 98,92 % des lignes et 91,61 % des branches. Contrôles clavier, accessibilité et débordement à 375, 768 et 1440 px. Captures : `tmp/screenshots/admin-navigation-{375,768,1440}.png`.


## Recette du parcours guidé et de l’accueil commun

Après la simplification du Studio admin : **305 exemples RSpec, 0 échec** (seed 19899), couverture **98,87 % des lignes / 90,91 % des branches**. Les contrôles ciblés comptent 32 exemples réussis : séparation des permissions, redirection de l’ancien accueil, création de page sans adresse technique, bouton facultatif, publication atomique, refus des aperçus obsolètes et parcours navigateur jusqu’à la confirmation de mise en ligne. L’écran de vérification permet de choisir la page et de revenir à l’élément édité.

RuboCop : 320 fichiers sans infraction. Brakeman : 0 avertissement et 0 erreur. Contrôle de fraîcheur des assets et `git diff --check` réussis. Captures du parcours : `tmp/screenshots/studio-admin-{content,review}-{375,1440}.png`.
