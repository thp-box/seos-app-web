# Analyse de la maquette et des user stories

## Conclusion générale

La maquette est une excellente vision de produit, mais pas encore une spécification exécutable. Elle simule un grand nombre d'états côté navigateur et va nettement plus loin que les user stories. Les fondations métier sont cohérentes — entraide, confidentialité, trois modes d'échange, confiance — mais les règles financières, les rôles et certains parcours critiques doivent être explicités avant de créer la base.

## Règle de couverture retenue

- Chaque user story est obligatoire : elle doit être reliée à un écran, une règle serveur et au moins un critère d'acceptation.
- Chaque fonctionnalité observée dans la maquette reste incluse dans la feuille de route, même si elle est planifiée après le premier lancement.
- Une contradiction ne conduit pas à supprimer une source. Elle est résolue par une décision produit documentée.
- Décision déjà actée : un visiteur peut ouvrir le profil de service public d'un membre, consulter ses annonces et son Trust Score ; ses coordonnées et données privées restent invisibles.

## Points forts de la maquette

- Proposition de valeur comprise dès le hero.
- Trois modes d'échange clairement différenciés.
- Catalogue riche : recherche, filtres, tri, liste/carte et état vide.
- Publication guidée en quatre étapes avec aperçu.
- Très bon niveau de réassurance : confidentialité, vérification, avis, signalement et contenu légal.
- Espace membre complet et lisible.
- Direction artistique humaine, organique et reconnaissable.
- Premiers traitements RGPD rendus visibles dans l'interface.
- Responsive prévu à `1040 px`, `820/900 px` selon les sections et `720 px`.

## Limites structurelles de la maquette

- Toutes les pages sont dans un seul document et la navigation change uniquement l'état JavaScript : il n'existe ni URLs réelles, ni historique navigateur fiable, ni contrôle serveur.
- Les soldes, permissions, validations, récompenses et statuts sont modifiés dans le navigateur ; ils ne constituent donc pas des règles sécurisées.
- Plusieurs filtres sont seulement décoratifs. Les boutons rapides filtrent, mais pas toutes les cases, fourchettes et options affichées.
- Les connexions sociales, vidéos, envois, traitements de signalements et demandes RGPD sont simulés.
- Le back-office visible ne couvre pas toute l'administration demandée.
- La maquette est initialisée comme si Camille était connectée, ce qui masque certains états visiteur.
- Des images Unsplash et Google Fonts distants sont utilisés ; les médias définitifs, licences et choix de consentement restent à établir.

## Couverture détaillée des user stories

| # | User story synthétisée | Couverture maquette | Analyse |
|---:|---|---|---|
| 1 | Comprendre immédiatement l'offre | Forte | Hero, trois modes et présentation vidéo donnent une lecture rapide. |
| 2 | Voir les pages publiques | Forte | Plusieurs pages publiques existent, mais sans vraies routes. |
| 3 | Consulter les annonces | Forte | Catalogue, catégories, recherche, filtres, tri, carte et état vide. |
| 4 | Voir le détail d'une annonce | Forte | Galerie, description, modalités, membre, avis et actions. |
| 5 | Ne pas voir les coordonnées de l'annonceur | Partielle | Le téléphone est masqué, mais la règle exacte de déverrouillage doit être décidée. |
| 6 | Ne pas voir les informations personnelles privées | Couverte après arbitrage | Le visiteur peut voir un profil de service, ses annonces et son Trust Score, mais jamais e-mail, téléphone, adresse exacte, nom civil complet ou données internes. |
| 7 | S'inscrire | Forte | Formulaire, bonus annoncé, CGU, newsletter facultative et CAPTCHA simulé. |
| 8 | Se connecter et se déconnecter | Forte | Connexion et menu profil ; récupération de mot de passe et sécurité des sessions absentes. |
| 9 | Créer une annonce | Forte | Assistant complet en quatre étapes. |
| 10 | Modifier ou supprimer son annonce | Partielle | Modification et réactivation visibles ; suppression absente. |
| 11 | Envoyer une demande de service | Forte | Proposition et question depuis le détail, mais le cycle de statuts n'est pas défini. |
| 12 | Suivre les demandes envoyées | Faible | Messagerie présente, aucune liste explicite des demandes et de leurs statuts. |
| 13 | Recevoir une notification | Partielle | Badges de compteur, pas de centre de notifications ni préférences. |
| 14 | Effectuer une transaction en points | Forte visuellement | Simulation du débit et du solde ; sécurité serveur et double confirmation à construire. |
| 15 | Voir son historique d'échange | Partielle | Historique du portefeuille et activité récente, mais pas d'historique métier complet. |
| 16 | Voir « Mon profil » | Forte | Profil, avatar, coordonnées, bio et droits RGPD ; les réglages doivent distinguer profil de service public et données privées. |
| 17 | Administrer les annonces | Partielle | Top annonces et signalements visibles ; CRUD/modération complet absent. |
| 18 | Administrer les utilisateurs | Absente | Aucun écran de liste, suspension, vérification ou historique utilisateur. |
| 19 | Auditer les transactions de points | Absente | Le membre voit son historique, mais aucun journal d'audit administrateur. |
| 20 | Super-admin = permissions admin | Absente | Aucun rôle ni contrôle d'accès réel dans la maquette. |
| 21 | Super-admin crée des administrateurs | Absente | Parcours à ajouter et à sécuriser fortement. |
| 22 | Voir ses succès en cours/réalisés | Forte, vocabulaire différent | La maquette parle de « quêtes » et de niveaux ; décider si succès et quêtes sont identiques. |
| 23 | Admin CRUD des succès | Absente | Récompenses montrées côté membre, pas de gestion côté admin. |
| 24 | Super-admin crée des articles | Absente | Aucun journal de bord dans la maquette. |
| 25 | Commenter une annonce | Absente | Les avis sur le membre existent, mais pas les commentaires d'annonce. |
| 26 | Mettre une annonce en favori | Forte | Action sur les cartes et espace Favoris. |
| 27 | Créer une chaîne d'entraide | Forte | Création du lien, validation bénéficiaire et suivi de chaîne. |
| 28 | Super-admin crée des annonces monde pour les associations | Partielle et contradictoire | La maquette permet aux associations vérifiées de publier des missions, après accès accordé par l'admin. |

## Fonctionnalités présentes dans la maquette mais absentes des user stories

- recherche géographique, rayon, vue carte et mode à distance ;
- niveaux Bronze, Argent et Gold ;
- récompenses variables selon le niveau ;
- Top annonces avec validation humaine ;
- témoignages écrits et vidéo ;
- parrainage et partage social mensuel ;
- profils et organisations vérifiés ;
- avis après échange ;
- signalement avec objectif de traitement sous 48 heures ;
- activation globale de la rubrique Voyage solidaire ;
- contribution de mission associative plafonnée à 15 € par jour ;
- consentement cookies granulaire ;
- export, rectification, effacement, limitation, opposition et retrait du consentement ;
- newsletter facultative ;
- promesse de 30 PS à l'inscription, à matérialiser comme une quête d'accueil unique plutôt que comme un achat ou un crédit sans action ;
- bonus récurrent après une série de cinq échanges ;
- badge urgent et demande de mise en avant.

Ces éléments font partie du périmètre à concevoir. Leur présence ne suffit toutefois pas à valider leur formule, leur sécurité ou leur base juridique : ces règles doivent être explicitées avant développement.

Le parrainage de la maquette est enrichi par une décision produit : un nouveau membre peut présenter jusqu'à dix codes distincts. Tous contribuent de manière égale au score global provisoire, mais un seul parrain principal peut être associé à la quête/récompense afin de ne pas multiplier l'émission de Points Services.

## Exigences complémentaires désormais actées

- `SEOS Default v1` reproduit exactement la maquette et reste la référence immuable de l'application.
- `yarn build` est l'unique build applicatif attendu pour produire le JavaScript et le CSS ; toute stratégie laissant le CSS hors de ce build est écartée.
- RSpec est installé avant les générateurs métier et couvre l'intégralité des features, rôles, transitions, cas concurrents, comportements JavaScript et régressions visuelles.
- Le super-admin dispose d'un Studio allowlisté pour modifier le kit UI/UX, les textes, descriptions, CTA, images, SEO et décoration de chaque page, avec preview, version, publication, rollback et reset.
- Les resets peuvent viser un champ, bloc, média, séparateur, page, thème ou le site entier ; ils recréent une version depuis le défaut et n'effacent pas l'historique.
- Plusieurs séparateurs organiques peuvent être placés entre les sections d'une page, en statique ou via des animations prédéfinies compatibles reduced motion.
- Le super-admin peut activer/désactiver la carte. Lorsqu'elle est désactivée, aucun contrôle, SDK, script, tuile, cookie ni appel réseau du fournisseur cartographique n'est chargé ; le catalogue en liste reste complet.
- Une carte sur la page d'une annonce est possible uniquement pour un service en présentiel ou hybride et avec une zone publique valide. Une annonce 100 % à distance ne reçoit aucune coordonnée ou marqueur artificiel.
- La carte globale conserve néanmoins toutes les annonces filtrées dans l'expérience : marqueurs approximatifs pour le présentiel/hybride, panneau « À distance » pour les annonces distancielles et compteurs séparés dont la somme égale le total.
- Aucun éditeur ne permet d'injecter du CSS, JavaScript, HTML ou SVG arbitraire depuis le back-office.
- Les annonces actives, autorisées et suffisamment complètes alimentent le SEO via des URLs canoniques, sitemaps, contenu serveur et JSON-LD Schema.org, sans donnée privée ; les autres restent `noindex`.
- Le GEO repose sur ce même contenu original et structuré ; aucune page ou fichier artificiel créé seulement pour les moteurs génératifs.
- La V1 est française, en français (`fr-FR`), avec Devise pour l'authentification et Google comme premier fournisseur social.

## Matrice d'autorisation cible

| Action | Visiteur | Membre | Association vérifiée | Admin | Super-admin |
|---|:---:|:---:|:---:|:---:|:---:|
| Lire pages et annonces publiques | Oui | Oui | Oui | Oui | Oui |
| Ouvrir un profil public, ses annonces et son Trust Score | Oui | Oui | Oui | Oui | Oui |
| Voir une coordonnée privée | Non | Après accord | Après accord | Motif de modération audité | Motif de modération audité |
| Créer/modifier ses annonces | Non | Oui | Oui | Modération | Modération |
| Supprimer sa propre annonce | Non | Oui, suppression logique | Oui | Oui | Oui |
| Demander un service / écrire à une annonce | Non, connexion requise | Oui | Oui | Oui | Oui |
| Contacter l'équipe SEOS | Oui, formulaire public protégé | Oui | Oui | Oui | Oui |
| Confirmer un échange et noter | Non | Participant uniquement | Participant uniquement | Non à la place du membre | Non à la place du membre |
| Transférer des points | Non | Participant et solde suffisant | Participant et solde suffisant | Ajustement séparé et audité | Ajustement séparé et audité |
| Publier une mission solidaire | Non | Non | Oui | Modération | Modération |
| Gérer catégories, quêtes et signalements | Non | Non | Non | Oui | Oui |
| Créer un administrateur | Non | Non | Non | Non | Oui |
| Publier le journal de bord | Non | Non | Non | Selon décision | Oui selon user story |

## Règles métier à conserver côté serveur

### Annonces

- Une annonce appartient à un membre et à une catégorie.
- Son intention est `offre` ou `demande`.
- Son mode est exactement `don`, `échange libre` ou `points`.
- Son mode de réalisation est exactement `in_person`, `remote` ou `hybrid` et ne doit pas être confondu avec son mode d'échange.
- Une estimation en points est interdite pour les modes don et échange libre.
- Une adresse exacte ne doit jamais être rendue dans le HTML public.
- L'éligibilité à un marqueur est calculée côté serveur : `in_person`/`hybrid` + zone publique valide + carte globale active. Le membre ne peut pas forcer un marqueur.
- Seul le propriétaire ou un rôle de modération peut modifier l'annonce.
- Une suppression utilisateur doit être logique si l'annonce a déjà participé à un échange, un signalement ou une transaction.

### Demande de service

- Une demande relie le demandeur, le propriétaire et l'annonce.
- Le propriétaire ne peut pas demander sa propre annonce.
- Les transitions doivent être contrôlées : proposée → acceptée/refusée → planifiée → réalisée → confirmée/contestée → clôturée.
- Une conversation et ses participants sont dérivés de la demande, pas d'un identifiant transmis librement par le navigateur.

### Points Services

- Les montants sont des entiers ; aucun flottant.
- Les Points Services ne s'achètent pas, ne se vendent pas et ne sont jamais la contrepartie d'un soutien financier à SEOS.
- Le montant final peut différer de l'estimation affichée.
- Aucun débit avant confirmation du service et du montant final selon la règle à valider.
- Le solde ne peut pas devenir négatif.
- Chaque opération possède une clé d'idempotence pour empêcher le double clic ou la relance d'un job.
- Une transaction validée n'est jamais éditée ni supprimée ; une correction crée une écriture compensatrice.
- Bonus, quêtes, chaînes et ajustements d'administration passent par le même registre auditable.
- La grille indicative euros → PS et les bonus/niveaux sont des versions configurées par le super-admin, simulées, datées et non rétroactives par défaut.

### Avis et commentaires

- Un avis concerne un échange validé et ne peut être créé que par un participant.
- Une seule évaluation structurée par auteur et par échange ; elle porte sur des faits observables et des dimensions liées à la tâche.
- Les avis des deux parties restent masqués jusqu'à la seconde réponse ou la fin d'un délai afin de réduire la notation de représailles.
- Le score public et le risque de modération interne sont deux sorties différentes ; le second n'est jamais affiché comme un jugement public.
- Un commentaire d'annonce est différent d'un avis et nécessite ses propres règles de modération.

### Chaînes

- Le lien de validation est unique, limité dans le temps, stocké sous forme de condensat et utilisable une seule fois.
- La validation du bénéficiaire et les récompenses doivent être atomiques.
- Les bénéficiaires non inscrits doivent recevoir une information RGPD dès le premier contact.
- La chaîne n'a pas de fin par défaut. Une version super-admin choisit `unlimited` ou `limited`, la limite éventuelle, les bénéficiaires récompensés, le gain par validation/maillon et les plafonds par membre.
- Toute version de récompense doit être simulée et testée sur émission non bornée, répétitions, branches, auto-validation et concurrence avant activation.

### Administration

- Toute action sensible produit un journal d'audit : auteur, cible, action, date, motif et métadonnées utiles.
- L'élévation vers administrateur est réservée au super-administrateur et exige une réauthentification.
- Les ajustements de points passent par une opération dédiée, motivée et compensable.
- Les coordonnées et autres données personnelles sont masquées par défaut ; leur révélation exige une permission, un motif et une trace d'accès.
- Un administrateur peut modérer ou rectifier par une action métier, mais pas éditer directement une écriture de points, une preuve de score ou un journal d'audit.
- Les actions de masse destructrices sont limitées, confirmées et réversibles lorsque c'est possible.
- Le Studio modifie uniquement des valeurs et presets autorisés ; le défaut système, les templates et l'historique ne sont jamais écrasés.
- Publication, rollback, reset et changement du flag carte sont réservés au super-admin, réauthentifiés selon impact et audités.
- Les admins habilités et le super-admin gèrent une blacklist de catégories/mots-clés avec motif, portée, dates, traitement des annonces existantes et audit.
- Le super-admin versionne les barèmes Points/niveaux/chaînes ; il ne peut jamais transformer les PS en produit achetable.
- L'administration SEO/GEO contrôle indexabilité, sitemaps, données structurées et crawlers sans permettre de JSON-LD libre.

## Arbitrages actés et validations restantes

1. **Contact visiteur — arbitré** : un visiteur ne contacte jamais un annonceur et ne crée aucune demande/message d'annonce. Il peut uniquement contacter l'équipe SEOS depuis la page Contact, avec anti-spam et notice de confidentialité.
2. **Profil public — arbitré** : le profil de service, ses annonces et son Trust Score sont publics ; e-mail, téléphone, adresse exacte, nom civil complet, messages, solde, signalements et score de risque restent privés. La matrice détaillée figure dans `09-rgpd-profils-publics.md`.
3. **Confirmation des points** : la maquette parle de validation par les deux membres, mais ne montre qu'un bouton de rétribution. Définir qui confirme quoi et dans quel ordre.
4. **Barèmes PS — arbitré** : équivalence indicative euros → PS, valeurs autorisées et textes d'aide appartiennent à une version super-admin. Une modification ne recode pas l'application, n'est pas rétroactive et ne crée jamais une possibilité d'achat/conversion.
5. **Bonus et niveaux — arbitré** : fréquence après N échanges, montants Bronze/Argent/Gold, plafonds et dates d'effet sont configurés/versionnés par le super-admin avec simulation et audit.
6. **Chaînes — arbitré** : longueur illimitée par défaut. Le super-admin peut publier une règle limitée ou illimitée, définir la limite éventuelle, le gain par validation/maillon, la profondeur récompensée et les plafonds. Une alerte interdit une configuration dont l'émission maximale n'est pas comprise.
7. **Succès ou quêtes** : harmoniser le vocabulaire, la récurrence, les preuves et la validation.
8. **Annonces monde — arbitré** : le super-admin peut créer et publier au nom d'une association afin de satisfaire la user story. Une association vérifiée peut préparer et gérer ses brouillons/missions, sous modération ; elle ne reçoit pas le pouvoir exclusif de publication globale.
9. **Garantie du double** : elle apparaît dans le HTML initial puis est supprimée par JavaScript. Elle ne doit pas être promise sans règles juridiques, budget et processus de médiation validés.
10. **Conservation — « à vie » refusé comme règle globale** : les données restent actives selon leur finalité puis sont supprimées, anonymisées ou archivées de façon restreinte. Les durées exactes et l'AIPD Trust doivent être validées avant production ; aucune valeur illimitée n'est autorisée par le Studio.
11. **Mineurs** : âge minimal et éventuel consentement parental non définis.
12. **Territoire — arbitré** : lancement en France uniquement, interface et contenus en français (`fr-FR`). Les autres pays/langues exigent une future version.
13. **Catégories sensibles — arbitré** : blacklist administrable par les admins habilités et le super-admin ; motif, période, portée et sort des annonces existantes sont obligatoires.
14. **Prestataires — arbitré pour V1** : Devise ; Gmail API via client Google Ruby ; Google OmniAuth en premier ; Geocoder + Leaflet et fournisseur de tuiles configurable ; vidéo Active Storage/HTML5 ; analytics tiers désactivés au lancement. Facebook reste prévu mais flaggé off tant que la compatibilité Ruby/Rails n'est pas validée.
15. **Soutien financier — arbitré** : don/soutien seulement, jamais achat. Intégration Stripe Checkout planifiée derrière `financial_support_enabled = false`, sans PS, niveau, Trust ou contrepartie et sans promesse fiscale avant validation de l'entité.
16. **Identité — arbitré pour la V1** : aucune pièce d'identité n'est collectée. Les badges indiquent uniquement le contrôle réellement effectué (`e-mail vérifié`, `téléphone vérifié`). Les catégories trop sensibles pour fonctionner avec ce niveau d'assurance peuvent être blacklistées ; la promesse « profils vérifiés » de la maquette doit être reformulée.

## Critères d'acceptation transverses

- Toutes les autorisations sont testées côté serveur, y compris par requête directe.
- Les écrans possèdent des URLs REST réelles et supportent précédent/suivant.
- Les formulaires affichent erreurs et instructions au niveau du champ.
- Chaque action longue ou asynchrone affiche un état en cours, réussi ou échoué.
- Les données privées ne sont jamais incluses dans le HTML public, même masquées en CSS.
- Les actions financières et de récompense sont atomiques et idempotentes.
- Les listes d'administration sont paginées, filtrables et auditables.
- Chaque user story possède un identifiant de traçabilité dans le backlog et aucun élément de maquette n'est supprimé sans décision produit explicite.
- Le Trust Score affiche ses principales sources, son niveau de confiance statistique, sa date de calcul et un accès à la contestation.
- Aucune suspension, limitation de contact ou autre décision à effet important ne repose uniquement sur un calcul automatisé non réexaminable.
- Les parcours clavier, lecteur d'écran et mobile sont validés avant mise en ligne.
- Les specs RSpec couvrent chaque transition de statut, chaque rôle, chaque cas de double soumission et les parcours JavaScript critiques.
- Le thème par défaut est comparé à la maquette aux largeurs `320`, `375`, `414`, `768`, `1024`, `1280` et `1440px` ; aucun changement de baseline n'est automatique.
- Les éditions et resets Studio sont testés à chaque granularité, avec historique, cache, concurrence et permissions.
- La carte est testée activée/désactivée, y compris l'absence de toute requête fournisseur lorsqu'elle est coupée, l'absence de carte sur une annonce `remote`, le marqueur approximatif d'une annonce `in_person`/`hybrid` et la présence de toutes les annonces dans les résultats de la carte globale.
- Toute annonce indexable possède canonical, sitemap et JSON-LD sans donnée privée ; les variantes de filtre ne créent pas de pages dupliquées.
