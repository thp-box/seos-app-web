# Studio UI, contenus, carte et séparateurs organiques

## Vision

Le thème par défaut doit reproduire fidèlement la maquette SEOS. Le super-admin peut ensuite adapter le kit UI/UX depuis le back-office sans modifier le code, prévisualiser le résultat, publier une version et revenir à tout moment au thème ou contenu d'origine.

Ce Studio ne doit pas devenir un éditeur de code. Il manipule des tokens, presets et emplacements autorisés. Aucun CSS, JavaScript, SVG ou HTML arbitraire n'est saisi dans le back-office.

## Principes non négociables

- `SEOS Default v1` est une version système immuable dérivée de la maquette ;
- le bouton reset clone le défaut dans une nouvelle version, sans détruire l'historique ;
- les routes, permissions, règles Points/Trust et traitements RGPD ne sont pas modifiables depuis le Studio ;
- chaque changement passe par brouillon → preview → validation → publication ;
- toute publication est atomique, auditée et réversible ;
- l'accessibilité peut bloquer la publication ;
- le contenu public possède toujours un fallback système valide ;
- les animations respectent `prefers-reduced-motion` et ne portent aucun contenu essentiel ;
- les assets du thème publié sont produits/chargés sans contourner `yarn build` et Propshaft.

## Permissions

| Action | Admin `content.manage` | Super-admin |
|---|:---:|:---:|
| Modifier texte/image d'une page | Oui, brouillon | Oui |
| Prévisualiser | Oui | Oui |
| Publier contenu courant | Selon délégation | Oui |
| Modifier les tokens UI globaux | Non | Oui |
| Modifier les séparateurs d'une page | Brouillon si délégué | Oui/publier |
| Activer/désactiver la carte | Non | Oui |
| Reset d'un bloc/page | Proposer | Oui/confirmer |
| Reset du thème ou du site entier | Non | Oui + réauthentification |
| Supprimer le défaut système | Jamais | Jamais |
| Saisir du code arbitraire | Jamais | Jamais |

Association et Partenaire peuvent proposer le contenu de leur propre fiche dans leur espace. Un admin/super-admin le publie. Ils n'accèdent ni au thème global, ni aux autres pages.

## Modèle de versions

### Thème système

`SEOS Default v1` contient les valeurs exactes de [`05-kit-ui-ux.md`](./05-kit-ui-ux.md), les assets d'origine autorisés et les presets organiques de base. Il est identifié par `system_default = true` et ne possède aucune route update/destroy.

### Thème de travail

Cycle : `draft` → `validated` → `published` → `archived`.

Une publication précédente reste disponible pour rollback. Un seul thème est publié à un instant donné, protégé par verrouillage et transaction.

### Pages

Chaque route administrable correspond à une `page_definition` immuable côté structure, puis à des `page_versions` de contenu. Une page publiée ne se modifie pas sur place : un brouillon est cloné, édité et publié.

### Reset

Niveaux disponibles :

1. valeur de token ;
2. groupe de tokens ;
3. composant ;
4. bloc de contenu ;
5. image/vidéo ;
6. séparateur ;
7. page entière ;
8. thème entier ;
9. totalité du site administrable.

Chaque reset affiche la différence, les pages touchées et les médias remplacés. Les niveaux 7–9 exigent réauthentification, motif et confirmation explicite. Le reset global crée d'abord un snapshot de configuration et ne modifie ni données membres ni règles métier.

## Kit UI/UX modifiable

### Couleurs

- marque : deep, seos, turq, gold ;
- surfaces : cream, mist, white, footer ;
- texte : ink, muted, texte inversé ;
- sémantiques : danger, success, warning, info ;
- lignes et focus ;
- gradients approuvés.

L'éditeur montre la valeur, le contraste sur chaque surface et les composants affectés. Une paire sous le seuil AA requis bloque la publication ou impose une correction autorisée.

### Typographie

- familles parmi une liste auto-hébergée et approuvée ;
- tailles et interlignes bornés ;
- graisses réellement disponibles ;
- échelle titres/corps/microtexte ;
- tracking des titres/eyebrows ;
- nombres tabulaires admin.

Interdire URL de police distante libre et taille de corps inférieure à 16 px par défaut.

### Formes et matière

- rayons cartes/champs/modales/pills ;
- ombres parmi des presets ;
- largeur et couleur de bordure ;
- densité/espacements bornés ;
- largeur de conteneur dans une plage sûre ;
- gradients et fonds de sections ;
- intensité des formes asymétriques.

### Composants

Le Studio affiche un catalogue vivant : boutons, champs, badges, cartes annonce, profil, Trust Score, tableau, modale, toast, navigation, footer et états vide/chargement/erreur. Chaque modification globale se vérifie sur ce catalogue avant publication.

### Mouvement

- durée courte, normale et longue ;
- courbes d'accélération approuvées ;
- intensité globale `none/subtle/standard` ;
- aucun changement de layout animé ;
- reduced motion donnant un résultat statique complet.

## Contenu administrable de chaque page

### Registre des pages

- Accueil ;
- Don, Échange et Points Services ;
- catalogue et détail d'annonce ;
- profil public ;
- connexion/inscription ;
- publication en quatre étapes ;
- dashboard membre ;
- chaînes et validation bénéficiaire ;
- Voyage solidaire ;
- annuaire/fiches Associations ;
- annuaire/fiches Partenaires ;
- journal, article et centre légal ;
- pages 404, 422, 500 et maintenance ;
- e-mails transactionnels et textes de notifications dans un registre séparé ;
- dashboards organisation/admin pour les textes d'aide, sans modifier leurs règles.

Le registre de livraison doit au minimum déclarer les clés suivantes :

| Groupe | Définitions de page/écran administrables |
|---|---|
| Public principal | `home`, `don`, `exchange`, `points`, `listings_index`, `listing_show`, `public_member_profile` |
| Communauté | `chain_landing`, `chain_validation`, `travel_index`, `travel_show`, `associations_index`, `association_show`, `partners_index`, `partner_show` |
| Éditorial/légal | `journal_index`, `article_show`, `legal_index`, chaque document légal, politique cookies, explication Trust et charte de sécurité |
| Authentification | connexion, inscription, confirmation e-mail, mot de passe oublié/réinitialisé, session expirée et accès refusé |
| Publication membre | introduction et chacune des quatre étapes, aperçu, brouillon repris, succès et erreur |
| Compte membre | aperçu, annonces, demandes, messages, notifications, favoris, portefeuille, Trust/recours, avis, parrainages, quêtes, chaînes, profil, sessions et confidentialité |
| Organisation | aperçu, profil public, équipe, annonces, missions, candidatures, médias et proposition partenaire |
| Administration | dashboard et textes d'aide des sections Communauté, Catalogue, Échanges, Points, Trust, Modération, Engagement, Chaînes, Organisations, Contenus, Vie privée et Plateforme |
| Super-administration | Studio, thèmes, pages, médiathèque, séparateurs, flags, versions, audits, resets, administrateurs et versions d'algorithme |
| Système | `404`, `422`, `500`, maintenance, indisponibilité carte, absence de résultats et service tiers indisponible |
| Communications | vérification, récupération, demande reçue, message, notification, échange, points, Trust/recours, modération, RGPD, organisation et alertes admin |

Chaque définition liste ses slots autorisés, son template codé, ses variantes et ses fallbacks. Lorsqu'une nouvelle route ou un nouvel e-mail est créé, son entrée `page_definition`/registre de communication et ses valeurs système font partie de la Definition of Done de la même feature.

### Variantes et états éditoriaux

Un seul texte ne convient pas à toutes les situations. Chaque slot peut posséder des variantes explicitement prévues :

- visiteur, membre, association, partenaire, admin et super-admin lorsque le message diffère ;
- liste remplie, aucun résultat et premier usage ;
- brouillon, en attente, accepté, refusé, suspendu, archivé ou expiré selon l'objet ;
- chargement, succès, erreur récupérable, erreur définitive et service tiers indisponible ;
- carte activée/désactivée et consentement cartographique absent/accordé ;
- Trust insuffisant, limité, modéré ou solide, sans permettre de modifier la signification métier de ces états.

Chaque variante possède un contenu système de repli et peut être réinitialisée seule. Le Studio ne crée pas un statut métier : il habille seulement les statuts définis et validés par l'application.

### Champs disponibles par bloc

- eyebrow, titre, sous-titre et description ;
- texte riche nettoyé ;
- labels de CTA, destination interne autorisée et style de bouton ;
- image/vidéo, texte alternatif, crédit, point focal et recadrage ;
- fond/variante de surface ;
- ordre, visibilité, date de début/fin ;
- métadonnées SEO et aperçu social ;
- séparateur avant/après ;
- variante de layout parmi les gabarits prévus.

Chaque image/vidéo peut être remplacée ou remise à sa valeur système indépendamment du texte. Chaque titre, description, CTA, alt, crédit, métadonnée SEO, ordre et visibilité possède la même capacité de reset. Pour un champ obligatoire, « vider » restaure le fallback ; il ne publie jamais une page cassée.

Les labels métier critiques comme « non achetable », « données limitées » ou une limite légale sont protégés par validation et ne peuvent pas être remplacés par une promesse contradictoire.

Le Studio permet de réinitialiser titres/descriptions SEO et images sociales. En revanche, canonical, indexabilité et JSON-LD sont calculés depuis la route, le statut et les modèles métier. La preview explique le type Schema.org produit et les erreurs, sans fournir d'éditeur de schéma libre. Voir [`13-strategie-seo-schema-org-et-geo.md`](./13-strategie-seo-schema-org-et-geo.md).

### Médiathèque

- upload contrôlé et réencodé ;
- alt text obligatoire pour une image porteuse de sens ;
- crédit/licence/source ;
- dimensions, ratios et point focal ;
- état brouillon/publié/archivé ;
- usages listés avant remplacement ;
- média par défaut associé à chaque slot ;
- reset d'un média sans supprimer le fichier encore utilisé ailleurs ;
- purge seulement lorsqu'aucune version conservée ne le référence.

## Séparateurs organiques entre sections

Chaque `page_version` peut placer zéro ou un séparateur entre deux slots consécutifs. Plusieurs séparateurs différents sont autorisés sur la même page.

### Presets V1

| Clé | Forme | Usage |
|---|---|---|
| `wave_single` | Vague simple douce | Transition standard |
| `wave_double` | Double vague superposée | Hero/section forte de la maquette |
| `soft_curve` | Courbe large | Pages explicatives |
| `asymmetric_blob` | Masse organique asymétrique | Témoignage ou communauté |
| `scallop` | Petites ondulations | Transition légère |
| `diagonal_soft` | Diagonale arrondie | Variation contrôlée |
| `mist_fade` | Fondu brume sans contour dur | Sections calmes |
| `none` | Aucun décor | Pages fonctionnelles denses |

### Réglages sûrs

- couleur avant/arrière via tokens du thème ;
- hauteur desktop/mobile bornée ;
- flip horizontal/vertical ;
- variante/seed parmi une liste ;
- superposition simple/double ;
- position avant ou après le bloc ;
- `aria-hidden = true` et aucun texte dans le décor ;
- espace réservé avant chargement afin d'éviter le CLS.

### Animation

Presets :

- `static` ;
- `reveal_once` : apparition courte à l'entrée ;
- `drift_once` : léger déplacement puis arrêt ;
- `morph_once` : une transition de forme puis état stable ;
- `ambient_slow` : boucle lente exceptionnelle.

`ambient_slow` est désactivé par défaut, limité à un ou deux décors visibles, mis en pause hors viewport et transformé en `static` sous `prefers-reduced-motion`. Les animations d'entrée restent généralement entre 150 et 450 ms ; aucune animation décorative ne bloque le scroll, la lecture ou le clic.

Le preset définit l'implémentation CSS/Stimulus autorisée. Le super-admin ne saisit pas de keyframes ou de code JavaScript.

## Feature flag Carte

Clé : `public_map_enabled`, valeur par défaut `true` pour refléter la maquette.

### Super-admin

- voit le statut, le fournisseur, les pages affectées et l'impact cookies/réseau ;
- prévisualise les états activé/désactivé ;
- active/désactive après confirmation et motif ;
- action auditée, versionnée et immédiatement réversible ;
- peut remettre la valeur au défaut système.

### Admin

- voit l'état et les incidents de la carte ;
- ne change pas le flag sans permission super-admin ;
- continue à modérer les annonces/localisations depuis les listes.

### Visiteur/membre/organisation

- activée : bouton Liste/Carte, marqueurs approximatifs `in_person/hybrid`, panneau `remote` sans marqueur et alternative liste complète ;
- détail d'annonce : carte uniquement pour `in_person/hybrid` avec zone publique ; bloc « À distance — France » pour `remote` ;
- carte globale : toutes les annonces filtrées restent comptées et consultables, sans attribuer une position artificielle aux annonces `remote` ni compter deux fois les hybrides ;
- désactivée : aucune option carte mais tous les filtres et résultats restent utilisables ;
- aucun script, cookie, tuile ou appel fournisseur n'est chargé quand elle est désactivée ;
- une URL enregistrée en mode carte revient proprement vers la liste.

Le flag n'efface ni latitude/longitude privées ni données de recherche. Il désactive uniquement l'expérience cartographique et le chargement du prestataire. L'éligibilité d'une annonce à un marqueur reste calculée côté serveur ; ni le Studio, ni l'auteur, ni un paramètre d'URL ne peuvent forcer une annonce `remote` sur la carte.

## Écran Studio du super-admin

Navigation :

1. Vue d'ensemble ;
2. Thèmes ;
3. Tokens ;
4. Composants ;
5. Pages ;
6. Médiathèque ;
7. Séparateurs ;
8. Animations ;
9. Feature flags ;
10. Versions et audits ;
11. Reset et rollback.

La preview s'affiche dans un contexte isolé et signé, avec sélecteurs de page, état, audience et viewport. Le super-admin compare défaut, version publiée et brouillon côte à côte. Aucun brouillon n'est indexé ni mis en cache publiquement.

## Publication

1. enregistrer le brouillon avec lock optimiste ;
2. valider schéma, tokens, médias, contrastes, titres, alt et URLs ;
3. exécuter les specs ciblées et générer les previews ;
4. afficher le diff de configuration et de rendu ;
5. demander motif/réauthentification ;
6. publier thème + page versions dans une transaction cohérente ;
7. invalider les caches et notifier les opérateurs ;
8. conserver la version précédente pour rollback.

Le code JS/CSS de l'application reste construit par esbuild. Une publication de thème ne compile pas du code utilisateur : elle change des CSS Custom Properties et des références de presets déjà livrés et testés.

## RSpec obligatoire

Le paquet détaillé figure dans [`11-strategie-tests-rspec-et-regression.md`](./11-strategie-tests-rspec-et-regression.md). Minimum spécifique :

- policy specs de toutes les permissions Studio ;
- request specs des versions, previews, publications, resets et flags ;
- service specs de clone/reset/diff/publish/rollback ;
- system specs JavaScript du Studio ;
- visual specs du défaut et des pages modifiées ;
- request/schema specs des meta, canonical, indexabilité et JSON-LD après publication/reset ;
- deux états complets de la carte ;
- matrice `in_person/remote/hybrid` pour le détail, le catalogue global, les compteurs, filtres, tris et l'absence de faux marqueur ;
- chaque preset organique en statique/animé/reduced motion ;
- concurrence de publication ;
- rejet des entrées arbitraires et médias invalides ;
- audit et restauration du défaut exact.

## Critères de sortie

- Le thème par défaut passe la régression visuelle face à la maquette.
- Toutes les pages du registre sont éditables dans leurs slots autorisés.
- Chaque texte, image, vidéo, CTA, ordre et séparateur possède un défaut restaurable.
- Une page peut utiliser plusieurs formes organiques différentes.
- Une animation ne gêne pas reduced motion et ne provoque pas de CLS.
- La carte se coupe sans laisser le moindre appel vers son fournisseur.
- Une annonce `remote` ne possède jamais de carte individuelle ; elle reste présente dans le panneau distant de la carte globale.
- Les compteurs globaux incluent toutes les annonces filtrées et ne doublonnent pas les annonces hybrides.
- Aucun utilisateur non super-admin ne modifie thème global, flag carte ou reset global.
- Aucun reset n'efface l'historique ou les données métier.
- La version publiée peut être annulée en une opération auditée.
