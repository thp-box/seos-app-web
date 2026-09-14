# Phases 1 et 2 — Découverte et premiers échanges

Chantier du 5 septembre 2026, engagé à la demande de poursuivre après le socle. Le code permet maintenant de parcourir les annonces, publier un profil et une annonce, envoyer une demande, discuter, convenir d’un accord, confirmer le service et déposer des avis. Il contient les contrôles d’accès et les écrans de modération correspondants.

Ce document distingue les parcours exécutables de la définition de terminé exhaustive du [plan initial](10-plan-construction-feature-par-feature.md). Les phases 0, 1 et 2 ne sont pas déclarées intégralement terminées : le Studio complet, certaines fonctions éditoriales et les intégrations de production restent à construire.

## Périmètre effectivement codé

| Feature | Disponible | Compléments du plan initial |
|---|---|---|
| F-010 | Pages explicatives, journal, documents légaux versionnés, brouillon privé, publication immédiate/programmée super-admin, Contact réservé à l’équipe et anti-spam | Toutes les sections éditoriales de la maquette, vidéo interne, registre complet du Studio, archivage éditorial, contenus juridiques validés et conservation/purge |
| F-011 | Profil public pseudonyme/zone/bio/compétences/langues, avatar réencodé ; coordonnées chiffrées, partage volontaire par échange ; restriction et révélation motivée auditée | Présentation des futurs scores et badges des phases suivantes |
| F-012 | Catégories hiérarchiques, activation, catégories sensibles, restrictions par catégorie/terme avec périodes, traitement de l’existant et audit | Fusion exceptionnelle, édition des critères d’avis par catégorie, héritage Trust versionné |
| F-013 | Recherche, filtres, tri, pagination, commune/rayon, liste/carte, détail, galerie, distances approximatives ; distanciel conservé sans marqueur | Top annonces dépend de la phase 5 ; optimisation SQL du filtrage des grandes volumétries |
| F-014 | Assistant quatre étapes, brouillon/reprise, images contrôlées, publication/pause/clôture/retrait ; attribution serveur au membre ou à une association vérifiée dont il est membre actif | Suppression individuelle des photos, estimation calculée par barèmes de phase 4, publication exceptionnelle super-admin |
| F-015 | Sept presets décoratifs statiques autorisés dans les versions de contenu, plusieurs instances, hauteurs réservées, pas de SVG libre | Placement par frontière/bloc, couleurs/tailles pilotées par Studio, animations et resets granulaires |
| F-016 | Flag carte par défaut actif ; modification et reset super-admin, motif, audit, verrou optimiste ; retrait des assets et conteneurs lorsqu’il est coupé | Écran de configuration détaillée du fournisseur dans le Studio |
| F-017 | Rendu serveur, canonical, métadonnées, JSON-LD généré Service/Demand/CollectionPage/ProfilePage, sitemap, 404/410, profils et espaces privés noindex, politiques distinctes OAI-SearchBot/GPTBot | Configuration SEO versionnée, sitemaps segmentés, redirections d’anciens slugs, diagnostic détaillé et intégration Search Console |
| F-020 | Demande distincte du message, envoyées/reçues, filtres, délai de 14 jours, refus/annulation, unicité d’une demande ouverte, notifications | Configuration des délais par super-admin et relances métier |
| F-021 | Conversations participantes, Turbo, images privées, lecture/non-lu, déduplication d’envoi, notifications, préférence e-mail, blocage, signalement, accès support lié à un dossier et audité | Rafraîchissement temps réel des messages entrants et transport Gmail API du socle |
| F-022 | Propositions d’accord versionnées et chiffrées, date/lieu/mode/PS ou contrepartie, deux acceptations, partage/révocation de coordonnées, deux confirmations, annulation neutre, dossier de litige et chronologie immuable | Paramétrage des règles, attribution éventuelle d’une faute après procédure de revue |
| F-023 | Avis après réalisation, unicité, fenêtre 30 jours, double aveugle 14 jours ou deux avis, cinq critères de référence, notes/NA, réponse, texte masquable et invalidation motivée | Éditeur versionné des règles et projection vers le futur moteur Trust |
| F-024 | Favoris privés idempotents, commentaires publics distincts des avis, retrait logique, signalement protégé et polymorphe, assignation, échéance 72 h, décision/audit/notification, restauration | Réponses de commentaires en arborescence, configuration SLA et alertes d’escalade |

Les annonces d’association sont créées depuis son espace. Les interlocuteurs d’un échange restent les deux personnes identifiées lors de la demande ; les parcours spécifiques aux missions et partenaires appartiennent à la phase 6.

## Invariants et choix techniques

- Les espaces privés utilisent les sessions révocables existantes et `Cache-Control: no-store`. Un super-admin n’est pas automatiquement participant d’une conversation.
- Téléphones/adresses, messages, termes d’accord, détails d’événements, précisions de signalements et demandes Contact sont chiffrés par Active Record Encryption. Les vues publiques utilisent des champs explicitement choisis, sans sérialisation générique de modèle.
- Les textes sont rendus comme texte échappé. Les contenus CMS ne peuvent pas injecter de balise, script, pixel distant ou JSON-LD arbitraire. Les biographies et textes publics refusent les formats usuels d’e-mail/téléphone ; cela ne remplace pas une revue des informations personnelles saisies librement.
- Les images JPEG/PNG/WebP sont limitées à 5 Mo et 20 millions de pixels, vérifiées par contenu, réencodées en JPEG de 1 600 pixels maximum et dépouillées de métadonnées. Le téléchargement passe par une autorisation liée au modèle ; aucun endpoint générique Active Storage n’est ouvert.
- Les restrictions actives rendent immédiatement les annonces non publiques. Le job récurrent applique la mise en revue/pause à l’existant ; l’expiration d’une restriction ne republie pas automatiquement les annonces retenues.
- Un masquage administratif pose un blocage de modération distinct du statut. Le propriétaire ne peut pas le lever par édition ou republication.
- `with_lock`, les verrous optimistes et les contraintes uniques protègent les transitions et doublons. L’historique des échanges et les contenus publiés sont protégés aussi par des triggers SQLite.
- Modifier les termes d’un accord remet les deux acceptations et partages de coordonnées à zéro. Aucune confirmation de service n’est substituée par un administrateur. Aucun débit ou crédit de PS n’est effectué dans ce lot.
- Les e-mails de notification n’incluent aucun extrait de conversation ni coordonnée de l’autre membre. Le job vérifie la préférence, l’état du compte et `emailed_at`, puis utilise un Message-ID stable. Un crash entre l’acceptation par le transport et l’enregistrement local peut encore produire un doublon : la réconciliation avec le fournisseur Gmail reste un sujet du socle.

## Carte et géocodage

Leaflet est dans un point d’entrée JS/CSS distinct, inclus uniquement par les pages qui rendent une carte. Quand `public_map_enabled` est faux, aucun conteneur, bouton, SDK ou tuile n’est demandé. Les annonces à distance restent dans les résultats et ne sont jamais géocodées ; les marqueurs des autres annonces représentent la commune, avec des coordonnées arrondies à deux décimales.

Le géocodage passe par Geocoder et la BAN/Géoplateforme, limité au type `municipality`. Il ne reçoit jamais `address_line`. Les recherches sont mises en cache 30 jours. La carte utilise par défaut les tuiles standard OpenStreetMap, avec attribution et cache navigateur ; `MAP_TILE_URL` permet de changer de fournisseur. En test, le fond distant est vide par défaut pour éviter un accès extérieur. Une panne de fond de carte laisse la liste disponible.

Le [guide Leaflet](https://leafletjs.com/reference.html), le [code officiel Geocoder](https://github.com/alexreisner/geocoder) et la [politique des tuiles OSM](https://operations.osmfoundation.org/policies/tiles/) servent de références d’intégration. Le fournisseur doit être confirmé pour la charge et les conditions d’exploitation visées avant ouverture publique.

## Reprendre localement

```bash
bundle install
yarn install --frozen-lockfile
bin/rails db:prepare
bin/rails db:seed
yarn build
bin/dev
```

Les trois comptes de démonstration documentés dans le README sont conservés. Les seeds ajoutent leurs profils, quatre catégories et trois annonces ; les identifiants existants et les données déjà éditées ne sont pas écrasés. Les cinq critères d’avis et le flag carte sont des références disponibles dans tous les environnements ; les identités et annonces de démonstration restent réservées au développement.

Points d’entrée : `/annonces`, `/compte/profil/edit`, `/compte/annonces`, `/compte/echanges`, `/compte/notifications`, `/admin/gestion/annonces`, `/admin/gestion/contenus`, `/admin/gestion/signalements`, `/super_admin/carte/edit`.

En développement, les e-mails restent des fichiers sous `tmp/mail`. En production, préserver les clés de chiffrement `active_record_encryption` dans les credentials et leurs sauvegardes avec la base. Les clés locales sont dérivées du secret applicatif ; le changer rend les valeurs privées précédemment chiffrées illisibles. Les tâches récurrentes nécessitent un worker Solid Queue opérationnel.

## Vérification

Les specs ajoutées couvrent les modèles et règles, les transitions d’échange et leur rejouabilité, l’isolation HTTP, le CMS, la modération, la carte, les uploads, les notifications et les parcours Chrome. Les pages catalogue/détail/profil/contact sont vérifiées aux sept largeurs et à 200 % de zoom. La [revue explicite des références PNG](16-revue-visuelle-decouverte.md) décrit les changements attendus avant leur adoption.

La commande `bin/check-exchange-concurrency` prépare une base SQLite neuve isolée, puis exécute de vrais threads avec connexions distinctes : création simultanée d’une demande, confirmations simultanées et double envoi de message. Les trois vérifications passent. Elle fait partie de `bin/ci`.

Recette locale :

- **148 exemples RSpec, 0 échec**, seed `44022`, incluant navigateur, accessibilité et les 16 comparaisons PNG.
- **99,73 % des lignes** (1125/1128) et **95,06 % des branches** (462/486), seuils du projet conservés.
- **59 exemples métier/requête/job supplémentaires exécutés sur une base SQLite neuve**, préparée depuis `structure.sql` avec les références des seeds : 0 échec.
- Les quatre parcours navigateur ont été rejoués après ajout de la vérification de la carte active puis désactivée : 0 échec, aucune erreur console de la carte et aucun chargement de ressource cartographique lorsqu’elle est coupée.
- Vérification concurrente par connexions SQLite distinctes : réussie.
- Seeds relancées sans mutation de l’existant : trois utilisateurs, trois profils et trois annonces publiques ; les deux annonces sur place/hybrides ont une commune géocodée, l’annonce à distance n’a pas de coordonnées.
- RuboCop et Zeitwerk : réussis. Brakeman : 0 avertissement et 0 erreur. Audits Bundler/Yarn : aucune vulnérabilité signalée.
- Précompilation des assets en production : réussie, y compris les bundles carte JS/CSS et leurs images. Assets de production locaux nettoyés via `assets:clobber`, puis build de développement restauré et vérifié.
- Rapport JUnit de la suite : `tmp/rspec-phase-1-2.xml`. Couverture : `coverage/index.html`.

La recette couvre ce code, pas les compléments fonctionnels encore listés dans le tableau. Le workflow GitHub Actions est configuré mais n’a pas été déclenché à distance.
