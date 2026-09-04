# Kit UI/UX SEOS

## Statut

Ce kit reprend la **direction visuelle effective de la maquette**, y compris les règles ajoutées plus bas dans le document qui surchargent les styles initiaux. Les recommandations d'accessibilité sont séparées des valeurs déjà présentes afin de préserver la fidélité tout en identifiant ce qu'il faut corriger.

## Signature visuelle

SEOS combine :

- un bleu profond institutionnel pour la confiance ;
- un bleu vif et un turquoise pour l'action et la proximité ;
- un or chaud pour la récompense et les appels à l'action ;
- des fonds crème et brume, plus humains qu'un blanc clinique ;
- des titres éditoriaux en sérif et un texte fonctionnel sans sérif ;
- de grandes découpes ondulées et des rayons asymétriques ;
- des photos de personnes en situation d'entraide ;
- une densité aérée et des cartes généreuses.

Le thème livré par défaut, nommé `SEOS Default v1`, doit rester chaleureux, associatif et crédible. Il ne faut pas remplacer sa palette par une palette SaaS générique, ni mélanger les formes organiques avec des composants très anguleux. Ce thème système est immuable : le super-admin peut publier une variante versionnée depuis le Studio, puis revenir au défaut exact sans altérer la référence.

## Contrat de fidélité maquette → application

La maquette n'est pas une simple inspiration. Elle devient la référence visuelle du thème par défaut pour les pages, états et composants qu'elle montre. L'intégration doit préserver les dimensions, rythmes, typographies, couleurs, rayons, découpes, densités, comportements responsive et mouvement observés, puis ajouter les états fonctionnels absents du prototype sans en changer la signature.

La validation s'effectue sur quatre niveaux :

1. inventaire de chaque section et composant de `maquette.html` ;
2. comparaison visuelle de référence aux largeurs `320`, `375`, `414`, `768`, `1024`, `1280` et `1440px` ;
3. parcours RSpec système avec JavaScript pour menus, modales, filtres, carte, Studio et animations ;
4. vérification accessibilité, contenus dynamiques, états vides/erreur et absence de débordement.

Les écarts intentionnels nécessaires à l'accessibilité doivent être listés et approuvés. Une baseline visuelle ne doit jamais être régénérée automatiquement pour faire passer un test.

## Couleurs exactes

| Token de la maquette | Valeur | Usage |
|---|---:|---|
| `deep` | `#004961` | Navigation, panneaux foncés, titres d'action, confiance |
| `seos` | `#0092C5` | Marque, sélection, liens et accents |
| `turq` | `#21A2AF` | Catégories, validation douce, matière organique |
| `gold` | `#CDAE4F` | CTA principal, points, niveau, récompense |
| `cream` | `#FBFAF4` | Fond principal |
| `mist` | `#EEF7F9` | Sections alternées et surfaces secondaires |
| `ink` | `#173947` | Texte et titres sur fond clair |
| `muted` | `#64767D` | Texte secondaire |
| `line` | `#D9E4E6` | Bordures et séparateurs |
| `white` | `#FFFFFF` | Cartes et texte inversé |
| `danger` | `#DC674F` | Urgence, signalement, erreur |
| `ok` | `#2E956D` | Succès, crédit et validation |

### Couleurs secondaires réellement utilisées

- Footer : `#002F40`.
- Bleu profond alternatif : `#003B50`, `#005970`, `#075F74`, `#076A80`, `#08738D`.
- Fond danger doux : `#FFF0ED` avec texte `#A94030`.
- Fond points doux : `#FFF8DF`.
- Fond succès doux : `#F1FAF5`.
- Accent clair sur fond sombre : `#8EDEE7` ou `#9DE0E7`.

### Gradients de composants

| Composant | Gradient |
|---|---|
| CTA or | `135deg, #E1C969 0%, #CDAE4F 52%, #B99638 100%` |
| CTA bleu | `135deg, #28B8C1 0%, #0092C5 60%, #08728F 100%` |
| CTA profond | `135deg, #086A82 0%, #004961 72%` |
| Carte portefeuille | `145deg, #004961, #08778F` |
| Section francophone | `180deg, #004961, #005970 15%, #08738D 48%, #076A80 72%, #004961` |
| Hero | radial turquoise + `135deg, #003B50, #004961 58%, #075F74` |

## Contraste mesuré

| Paire | Ratio approximatif | Lecture |
|---|---:|---|
| `ink` sur `cream` | `11.73:1` | Excellent |
| `muted` sur `cream` | `4.53:1` | Conforme AA pour texte normal, sans marge |
| blanc sur `deep` | `9.88:1` | Excellent |
| `deep` sur `gold` | `4.59:1` | Conforme AA |
| `ink` sur `gold` | `5.70:1` | Conforme AA |
| blanc sur `seos` | `3.55:1` | Réservé au grand texte ou à l'UI ; insuffisant pour petit texte normal |
| `seos` sur `cream` | `3.39:1` | Insuffisant pour petit texte normal |
| `turq` sur blanc | `3.06:1` | Insuffisant pour petit texte normal |
| `danger` sur blanc | `3.44:1` | Insuffisant pour petit texte normal |
| `#A94030` sur `#FFF0ED` | `5.47:1` | Conforme AA |

Le bleu SEOS et le turquoise peuvent rester des accents, bordures ou fonds de grands boutons. Pour les petits libellés, utiliser `deep`/`ink` ou assombrir une variante dédiée sans changer la couleur de marque originale.

## Typographie exacte

| Usage | Police | Graisses |
|---|---|---|
| Titres `h1`, `h2`, `h3` | Playfair Display | 600, 700, italique 600 |
| Corps, interface, formulaires | DM Sans | 400, 500, 600, 700 |

Échelles de la maquette :

- `h1` principal : `clamp(3rem, 6.2vw, 6.2rem)`, interligne `.97`, approche `-.045em` ;
- `h1` de page informative : `clamp(3rem, 5vw, 5rem)` ;
- `h1` de sous-page : `clamp(2.8rem, 5vw, 5rem)` ;
- `h2` : `clamp(2.1rem, 4vw, 4rem)`, interligne `1.04`, approche `-.035em` ;
- `h3` de base : `1.35rem` ;
- texte courant : base navigateur `16px`, interligne `1.7` ;
- texte hero : `1.1rem` ;
- eyebrow : `.76rem`, graisse 800, capitales, espacement `.16em` ;
- microtexte : `.76rem` minimum actuel.

Règle : Playfair Display donne le ton éditorial ; DM Sans reste obligatoire pour boutons, données, tableaux et longs paragraphes fonctionnels.

## Architecture CSS/JavaScript attendue

Le CSS et le JavaScript de production partagent le même point d'entrée esbuild. La cible documentaire est la suivante :

```text
app/javascript/application.js
app/javascript/stylesheets/application.css
app/javascript/stylesheets/foundations/*
app/javascript/stylesheets/components/*
app/javascript/stylesheets/layouts/*
app/javascript/stylesheets/pages/*
app/javascript/controllers/*_controller.js
app/assets/builds/application.js
app/assets/builds/application.css
```

`application.js` importe la source CSS. Une exécution propre de `yarn build` doit donc produire les sorties JS et CSS dans `app/assets/builds`. Propshaft sert ensuite ces sorties. Il ne doit exister ni seconde feuille applicative concurrente sous le même nom logique, ni style critique recopié dans les vues.

Stimulus porte seulement les comportements : navigation mobile, accordéons, modales, aperçu média, filtres, carte, prévisualisation du Studio et séparateurs animés. Turbo conserve les parcours serveur et les états de formulaire. Les tokens modifiables par le Studio sont exposés sous forme de propriétés CSS validées ; aucun CSS, HTML, SVG ou JavaScript libre saisi en administration n'est exécuté.

## Grille et espacements

- Conteneur desktop : `min(1240px, 100% - 40px)`.
- Conteneur mobile : `min(1240px, 100% - 24px)`.
- Sections standards : `92px` vertical ; accueil final : environ `105px` ; mobile : `66–84px` selon section.
- Espacement de section head : `36px`.
- Gaps principaux : `18`, `20`, `22`, `24`, `30`, `34`, `42`, `48`, `58`, `72` et `76px`.
- Cartes : padding courant `22–34px`.
- Formulaires : grille deux colonnes, gap `16px`, une colonne sous `720px`.
- Recherche hero : colonnes `1.4fr 1fr auto`, une colonne sous `720px`.

Échelle de spacing à utiliser dans les nouveaux composants : `4, 8, 10, 12, 14, 16, 18, 20, 24, 28, 32, 36, 48, 64, 80, 92`. Les valeurs plus grandes sont réservées aux découpes organiques et héros.

## Rayons, bordures et ombres

### Base

- Rayon générique : `26px`.
- Boutons et pills : `999px`.
- Champs : `12px`.
- Notices : `14px`.
- Modales et grands panneaux : `24–34px`.
- Ombre principale : `0 18px 50px rgba(0, 73, 97, .10)`.
- Ombre carte légère : `0 10px 28px rgba(0, 73, 97, .06)`.
- Bordure standard : `1px solid #D9E4E6`.

### Formes organiques

Les rayons asymétriques sont une signature, mais doivent rester concentrés sur les grandes cartes, portraits, héros et séparateurs. Exemples effectifs :

- carte d'annonce impaire : `26px 42px 25px 36px` ;
- carte d'annonce paire : `42px 25px 38px 24px` ;
- carte de quête : `28px 16px 26px 18px` ;
- témoignage : `60px 28px 52px 34px` ;
- panneau rejoindre : `74px 34px 82px 38px` ;
- carte légale : `34px 20px 34px 20px`.

Ne pas attribuer une forme différente à chaque petit contrôle : cela réduirait la cohérence et la lisibilité.

### Séparateurs organiques entre sections

Une page peut placer plusieurs séparateurs, chacun rattaché à une frontière de section et choisi parmi une bibliothèque maîtrisée : `wave_single`, `wave_double`, `soft_curve`, `asymmetric_blob`, `scallop`, `diagonal_soft`, `mist_fade` ou `none`. Chaque instance peut définir couleurs par tokens, hauteur desktop/mobile, inversion horizontale/verticale et variante déterministe.

Animations autorisées : `static`, `reveal_once`, `drift_once`, `morph_once` et, exceptionnellement, `ambient_slow`. Une animation ne transporte aucune information, ne bloque pas le scroll, s'arrête hors écran et devient statique sous `prefers-reduced-motion`. Limiter à un ou deux séparateurs ambiants visibles simultanément. Les courbes et keyframes restent codées et testées ; le super-admin ne choisit que des presets sûrs.

## Composants

### Boutons

Base exacte : rayon pill, padding `13px 21px`, graisse 800, gap `8px`, transition `.2s`, déplacement hover `-2px`. Variantes : or principal, bleu, profond, clair, outline, danger et bloc.

États obligatoires à ajouter : `hover`, `focus-visible`, `active`, `disabled`, `loading` et succès/échec si action asynchrone. Le libellé ne doit pas changer la largeur brutalement pendant le chargement.

### Champs

- hauteur produite par padding `11px 13px` ;
- bordure `line`, fond blanc, texte `ink`, rayon `12px` ;
- label visible au-dessus, graisse 900, environ `.75rem` ;
- aide sous le champ ;
- erreur sous le champ et reliée par `aria-describedby` ;
- validation de préférence à la sortie du champ, puis au submit.

Les champs obligatoires doivent être indiqués. Les placeholders ne remplacent jamais les labels.

### Cartes d'annonce

Anatomie : média → badge Offre/Demande/Urgent/Top → favori → catégorie → titre → résumé sur deux lignes → membre vérifié et note → zone/distance/distance possible → mode ou points → CTA.

Desktop : média à `34%`, contenu flexible, hauteur minimale `238px`. Mobile final : vignette `112px` + contenu, hauteur minimale `220px`. Vérifier à `320–375px` que le titre, la note et le CTA ne débordent pas.

### Profil de service public

Le profil consultable par un visiteur reste fidèle au détail d'annonce : grand en-tête organique, avatar facultatif, `display_name`, zone large, ancienneté, badges littéraux, Trust Score, annonces et avis structurés.

- CTA principal : « Voir ses annonces » ou « Se connecter pour contacter » ;
- aucune place réservée à l'e-mail, au téléphone ou à l'adresse exacte ;
- aperçu membre « Ce que voit un visiteur » identique au rendu public ;
- signalement accessible sans présenter le profil comme suspect ;
- mobile : score, identité d'affichage et CTA avant les sections longues.

### Trust Score

Le score n'est pas une simple étoile moyenne ni une jauge spectaculaire. Son composant contient :

- `Indice de confiance SEOS`, score entier ou état « données insuffisantes » ;
- libellé `Données limitées/modérées/solides`, nombre d'échanges et partenaires ;
- barres sobres par dimension/catégorie avec valeur textuelle ;
- date de mise à jour et lien « Comment est-il calculé ? » ;
- action de contestation dans l'espace du propriétaire.

Les dimensions ne sont pas uniquement colorées. Une valeur faible n'emploie pas un vocabulaire accusatoire comme « personne dangereuse ». Les signaux de risque interne n'ont aucun composant public.

### Parrainages à l'inscription

L'inscription propose un bloc facultatif « Des membres vous font confiance ? » : un champ de code, un bouton d'ajout et une liste de 0 à 10 codes validés. Chaque ligne affiche seulement `Code accepté · parrain n°N`, jamais l'identité ou les coordonnées d'un parrain sans accord.

- compteur `3/10 codes` et possibilité de retirer avant validation finale ;
- explication : les codes augmentent seulement le score global provisoire ;
- aperçu dynamique indicatif : `3 parrainages → score provisoire estimé 58/100` ;
- mention permanente `données limitées · aucun échange confirmé` ;
- aucune promesse de compétence, aucun badge par tâche et aucun Point Service attribué au nouveau membre ;
- état code invalide, expiré, déjà utilisé, appartenant au même parrain ou plafond atteint ;
- les parrains restent anonymes sur la page publique, où seul le nombre confirmé apparaît.

### Pills et badges

- Pills de filtre : bordure `line`, fond blanc, padding `10px 16px`, état actif bleu SEOS et texte blanc.
- Badge d'annonce : petit, uppercase, graisse 900, espacement `.08em`.
- Urgent : fond danger et texte blanc ; prévoir texte ou icône en plus de la couleur.
- Points : fond jaune doux, disque or, texte profond.

### Navigation

- Hauteur desktop minimale `86px`, mobile `72px`.
- Fond bleu profond ou transparent en superposition du hero.
- Liens centrés, annonce mise en valeur en or.
- Profil connecté réduit à un avatar `48px`, badge de trois notifications et menu `290px`.
- Logo final visible dans la maquette : image de `108 × 38px`, `92 × 33px` sur mobile.

Le bouton menu mobile est visible mais n'a pas de comportement dans la maquette. Son panneau, son focus, sa fermeture par Échap et son piège de focus éventuel font partie de l'implémentation obligatoire.

### Assistant de publication

Stepper quatre étapes : Intention → Échange → Détails → Aperçu. Une étape active et les précédentes utilisent le bleu SEOS. Sur mobile, les étapes deviennent défilables.

À conserver : retour arrière, valeurs déjà saisies, aperçu de localisation masquée et explication du calcul des points. À ajouter : erreurs par étape, sauvegarde en brouillon, confirmation de sortie et reprise.

### Tableaux et listes d'administration

Fond blanc, lignes séparées, texte `.82rem`, cellules `14px`. Tous les tableaux doivent être dans un conteneur scrollable ou devenir des cartes sur mobile ; seule la table légale possède déjà ce wrapper dans la maquette.

Le grand panneau admin conserve les mêmes tokens mais augmente la densité : sidebar `deep`, fond `mist`, cartes blanches, CTA or, Playfair uniquement pour les titres de page et DM Sans pour les données. Cible : densité `8/10`, variance `3/10`, mouvement `2/10`.

- filtres et tri reflétés dans l'URL ;
- actions de masse visibles seulement après sélection ;
- colonnes prioritaires sur mobile et équivalent accessible de toute visualisation ;
- données privées masquées, avec parcours distinct de révélation ;
- actions destructrices avec résumé d'impact, motif et confirmation ;
- nombres tabulaires pour points, scores et tableaux financiers ;
- courbes simples pour les tendances et barres pour les comparaisons, pas une accumulation de jauges.

La spécification complète est dans [`07-panel-administration.md`](./07-panel-administration.md).

### Studio UI/UX et contenus

Le super-admin dispose d'un Studio cohérent avec le panneau admin pour :

- créer une variante à partir de `SEOS Default v1` ;
- modifier les tokens autorisés, prévisualiser desktop/tablette/mobile et publier une version ;
- gérer titre, description, CTA, images, texte alternatif, ordre, visibilité, SEO et séparateurs de chaque page déclarée ;
- remettre à zéro un champ, un bloc, un média, un séparateur, une page, un thème ou le site entier ;
- comparer la version active avec le défaut et restaurer/rollbacker une version antérieure.

Le reset recrée une version à partir de la référence système : il ne détruit pas l'historique. Preview, validation, publication et reset sont audités. Les valeurs non conformes au contraste, les alt absents et les configurations hors bornes empêchent la publication. La spécification fonctionnelle complète figure dans [`12-studio-ui-contenus-carte-et-separateurs.md`](./12-studio-ui-contenus-carte-et-separateurs.md).

### Carte publique activable

La vue carte reste un mode du catalogue, jamais l'unique moyen d'accéder aux annonces. Le super-admin contrôle le flag versionné `public_map_enabled`, activé par défaut. Lorsqu'il est désactivé, l'onglet carte, son conteneur, le script du fournisseur, les tuiles, cookies et requêtes réseau associées sont totalement absents ; liste, filtres géographiques et distances approximatives restent disponibles. L'administration ordinaire peut consulter l'état mais pas le changer.

Le mode de réalisation est visible par un libellé et une icône, jamais par la couleur seule : `Sur place`, `À distance` ou `Hybride`.

- Sur un détail d'annonce, le bloc carte n'existe que pour `Sur place` ou `Hybride`, avec une zone publique valide. `À distance` le remplace par un bloc « Disponible à distance partout en France ».
- Une annonce hybride peut avoir un marqueur approximatif et le badge `À distance possible`.
- La carte globale garde le catalogue complet : son rail de résultats contient toutes les annonces filtrées. Les annonces physiques/hybrides sont reliées à un marqueur ; les annonces 100 % à distance sont regroupées dans une section sticky/repliable « À distance », sans marqueur inventé.
- L'en-tête annonce `N résultats · X sur place/hybrides · Y à distance`, avec `X + Y = N`. Un filtre peut masquer un groupe, sans modifier le total avant filtre.
- Le survol ne constitue jamais l'unique interaction : carte et rail sont synchronisés au focus clavier, au clic et à la sélection tactile. Le panneau distant reste utilisable sans la carte.
- Déplacer la carte peut proposer « Rechercher dans cette zone » uniquement pour les annonces physiques/hybrides ; les résultats distants restent présents selon les autres filtres et ne sont pas éliminés par le viewport.
- Proximité et distance ne sont jamais calculées pour une annonce `remote`. Son tri utilise pertinence, disponibilité ou fraîcheur.

### SEO, Schema.org et GEO dans l'interface

La fidélité visuelle ne doit pas produire un HTML décoratif incompréhensible. Chaque page conserve un `h1`, des sections nommées, de vrais liens, des listes sémantiques, des images avec alt et son contenu principal rendu côté serveur. Les titres visibles, descriptions, catégories, zones et dates doivent correspondre aux métadonnées et au JSON-LD généré.

Une annonce montre clairement : offre ou demande, service, catégorie, zone publique, mode, disponibilité, statut et date. Ces blocs structurés améliorent simultanément la lecture humaine, l'accessibilité, le SEO et le GEO. Aucun texte invisible, répétition artificielle de ville/service ou bloc uniquement destiné aux crawlers.

Le Studio affiche une preview Search/social et un diagnostic Schema.org, mais ne permet ni JSON-LD ni balise libre. La stratégie détaillée figure dans [`13-strategie-seo-schema-org-et-geo.md`](./13-strategie-seo-schema-org-et-geo.md).

### Modale, toast et cookies

- Modale : backdrop, panneau centré, fermeture visible, fermeture par Échap et restitution du focus.
- Toast : zone `aria-live`; ne doit pas être le seul endroit où une erreur de formulaire apparaît.
- Cookies : panneau fixe bleu très profond, trois choix au même niveau, personnalisation par finalité et choix réversible.

## Motifs par page

| Page | Motif principal |
|---|---|
| Accueil | Hero photo + recherche + double vague or/crème, alternance de sections ondulées |
| Pages Don/Échange/Points | Split texte/photo sombre, vague de sortie, trois étapes |
| Catalogue | Sous-hero sombre, recherche, sidebar filtres, résultats ou carte |
| Détail | Galerie et contenu à gauche, panneau d'action sticky à droite |
| Authentification | Split photo/quote et formulaire |
| Dashboard | Sidebar profonde sticky et panneaux de contenu |
| Profil public | En-tête membre + confiance + annonces + avis, sans coordonnées |
| Administration | Sidebar profonde en accordéons + espace de travail dense et auditable |
| Chaînes | Explication + création, puis ligne horizontale de maillons |
| Voyage solidaire | Hero éditorial et grille de missions |
| Association | En-tête organisation, badge vérifié, présentation et missions actives |
| Partenaires | Annuaire de logos éditorialisé puis fiche de partenariat sans données membres |
| Contact | Formulaire adressé uniquement à l'équipe, notice de confidentialité et aucune action vers un annonceur |
| Centre légal | Navigation sticky et cartes documentaires |

## Responsive exact

### Jusqu'à `1040px`

- navigation principale masquée et bouton mobile affiché ;
- sidebar catalogue/dashboard repasse dans le flux ;
- dashboard, détail, sécurité, soutien, chaîne et panneau d'inscription passent à une colonne ;
- catégories en deux colonnes ;
- missions en deux colonnes ;
- quêtes en deux colonnes.

### Jusqu'à `820–900px`

- centre légal en une colonne ;
- navigation légale horizontale défilable ;
- section francophone empilée.

### Jusqu'à `720px`

- conteneur avec marges de `12px` ;
- recherches en une colonne ;
- presque toutes les grilles en une colonne ;
- formulaires en une colonne ;
- photo d'authentification masquée ;
- catégories encore en deux colonnes de `150px` ;
- cartes d'annonce en format vignette ;
- quêtes en une colonne ;
- hero d'accueil autour de `1010px` à cause de la recherche et de la vague ;
- menu profil fixé à `12px` des bords.

Points de test minimaux : `320`, `375`, `768`, `1024`, `1280` et `1440px`, plus zoom navigateur à `200%`.

La suite visuelle ajoute explicitement `414px`, utilisé pour couvrir les grands mobiles. Les captures de référence du thème système sont testées par RSpec ; les thèmes personnalisés sont testés sur leurs invariants de grille, contraste, lisibilité, overflow et reduced motion, sans exiger qu'ils soient pixel-identiques au défaut.

## Mouvement

- transitions de boutons et menus : `200ms` ;
- apparition des slides hero : fondu `1s`, rotation toutes les `4.8s` ;
- zoom média : `350–450ms` ;
- respiration organique : `8–9s`.

La maquette coupe déjà les animations du hero et de l'orbe avec `prefers-reduced-motion`, mais il faut aussi neutraliser fondu, zoom, scroll animé et transitions non essentielles. Aucun contenu indispensable ne doit dépendre d'une animation.

## Iconographie et médias

La maquette utilise des glyphes texte et des emoji (`⌕`, `⌖`, `♡`, `⚑`, `🤝`, etc.). Pour la production :

- employer une seule bibliothèque SVG outline ou des icônes SVG internes ;
- garder un libellé visible ou un `aria-label` précis ;
- conserver un trait et une taille cohérents ;
- réserver l'emoji à du contenu expressif, pas à l'interface ;
- extraire le logo base64 de la maquette vers un asset versionné ;
- auto-héberger les médias finaux et documenter droits/crédits ;
- servir images responsives WebP/AVIF avec dimensions réservées pour éviter le CLS ;
- ne charger une vidéo externe qu'après consentement si un tiers est impliqué.

## Audit UX/accessibilité prioritaire

### Critique avant intégration

1. Aucun style `focus-visible` global n'est défini.
2. Les boutons icône font `42 × 42px`, sous la cible recommandée de `44 × 44px`.
3. Le menu mobile n'est pas fonctionnel.
4. Plusieurs petits textes bleus/turquoise sur fond clair n'atteignent pas `4.5:1`.
5. Les tables d'administration risquent un débordement mobile.
6. Les contrôles de formulaire n'indiquent pas systématiquement les champs obligatoires ni les erreurs locales.
7. La hiérarchie de titres doit être revue une fois les pages séparées.
8. Il manque un lien « Aller au contenu ».
9. La modale doit gérer focus initial, tabulation, Échap et retour du focus.
10. Le carrousel hero doit pouvoir être arrêté ou ne pas gêner la lecture.
11. Le Trust Score doit rester compréhensible sans couleur et ne jamais masquer l'incertitude statistique.
12. Toute révélation de donnée admin doit annoncer la finalité, la durée et la journalisation avant l'action.

### Important

- Ne pas utiliser uniquement la couleur pour urgence, sélection, progression ou crédit/débit.
- Ajouter le nombre de résultats dans une zone annoncée après filtrage.
- Exposer l'état ouvert/fermé des accordéons et menus.
- Préserver le bouton retour du navigateur avec de vraies URLs.
- Afficher skeleton ou statut de chargement pour carte, filtres, messages et upload.
- Prévoir des états vides pour favoris, demandes, messages, avis, points et chaînes.
- Montrer clairement quand une information exacte devient visible et à qui.

## Checklist de fidélité

- [ ] Palette exacte et usages sémantiques respectés.
- [ ] Playfair Display uniquement pour la tonalité éditoriale, DM Sans pour l'interface.
- [ ] Largeur maximale `1240px`.
- [ ] Alternance crème/brume/bleu et séparateurs organiques présents.
- [ ] CTA principal or, actions secondaires bleu profond.
- [ ] Cartes blanches, bordure bleutée légère, ombres sobres.
- [ ] Photos humaines liées à une action réelle d'entraide.
- [ ] Trois modes d'échange identifiables sans ambiguïté.
- [ ] Mobile testé sans perte d'action ni scroll horizontal involontaire.
- [ ] Focus, contraste, clavier et reduced motion corrigés.
- [ ] Aucun détail privé présent dans le DOM public.
- [ ] Profil public testable en visiteur avec annonces et Trust Score, sans coordonnées.
- [ ] État « données insuffisantes » conçu sans pénaliser visuellement un nouveau membre.
- [ ] Panneau admin fidèle à SEOS mais suffisamment dense pour les grandes listes.
- [ ] `yarn build` produit bien `application.js` et `application.css` depuis les sources partagées.
- [ ] Baselines du thème `SEOS Default v1` validées aux sept largeurs prévues et jamais remplacées automatiquement.
- [ ] Studio limité aux tokens/presets autorisés, avec preview, version, audit, publication et resets granulaires/globaux.
- [ ] Titres, descriptions, CTA, images, alt, SEO, ordre et séparateurs de toutes les pages déclarées sont administrables et réinitialisables.
- [ ] Chaque séparateur fonctionne en statique, dans ses animations autorisées et en reduced motion.
- [ ] Carte désactivée : aucun contrôle, script, cookie, tuile ou appel fournisseur n'est émis, sans casser la liste.
- [ ] Specs RSpec modèle/requête/policy/système/visuelles reliées à chaque comportement UI dynamique.
- [ ] Chaque annonce possède un contenu serveur sémantique identique à ses métadonnées/JSON-LD, sans texte SEO caché.
- [ ] Preview SEO/social et raison d'indexabilité visibles dans le Studio/admin, sans édition de schéma libre.
