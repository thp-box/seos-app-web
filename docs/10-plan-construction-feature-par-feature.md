# Plan de construction feature par feature

## Objectif

Ce document est la dernière passerelle entre la conception et le code. Il ordonne la construction de SEOS des fondations aux finitions, en tranches verticales terminées : données, règles serveur, pages publiques, espace membre, espace organisation, administration, sécurité et tests.

Une feature n'est pas terminée lorsque son modèle ou son écran principal existe. Elle est terminée lorsque toutes les audiences concernées disposent du bon comportement et qu'aucune autre audience ne peut contourner les autorisations.

Documents de référence obligatoires :

- [`02-analyse-maquette-user-stories.md`](./02-analyse-maquette-user-stories.md) pour les 28 user stories ;
- [`03-modele-de-donnees.md`](./03-modele-de-donnees.md) pour les tables et contraintes ;
- [`04-plan-scaffolds-rails-8.md`](./04-plan-scaffolds-rails-8.md) pour les commandes indicatives ;
- [`05-kit-ui-ux.md`](./05-kit-ui-ux.md) pour la fidélité à la maquette ;
- [`07-panel-administration.md`](./07-panel-administration.md) pour les écrans et exceptions CRUD ;
- [`08-systeme-trust-score.md`](./08-systeme-trust-score.md) pour la formule de confiance ;
- [`09-rgpd-profils-publics.md`](./09-rgpd-profils-publics.md) pour la visibilité et la conformité ;
- [`11-strategie-tests-rspec-et-regression.md`](./11-strategie-tests-rspec-et-regression.md) pour la couverture et la non-régression ;
- [`12-studio-ui-contenus-carte-et-separateurs.md`](./12-studio-ui-contenus-carte-et-separateurs.md) pour le Studio, les resets, la carte et les séparateurs.
- [`13-strategie-seo-schema-org-et-geo.md`](./13-strategie-seo-schema-org-et-geo.md) pour les annonces indexables, Schema.org et le GEO.

## Audiences et rôles

| Audience | Nature | Droits généraux |
|---|---|---|
| Visiteur | Non authentifié | Pages publiques, annonces, profils de service, Trust Score, associations et partenaires |
| Membre | `users.role = member` | Profil, annonces, échanges, points, confiance et fonctions communautaires |
| Association | Organisation vérifiée + membership | Espace organisation, équipe, missions et annonces monde autorisées |
| Partenaire | Organisation + partenariat actif + membership | Espace de proposition de contenu partenaire, sans donnée privée membre |
| Administrateur | `users.role = admin` + permissions | Opérations et modération selon permissions accordées |
| Super-administrateur | `users.role = super_admin` | Administration complète, administrateurs, algorithmes et paramètres critiques |

`Association` et `Partenaire` ne sont pas des rôles globaux placés sur `users`. Un même membre reste membre et agit au nom d'une organisation grâce à `organization_memberships` (`owner`, `manager`, `editor`). Un partenariat ne donne jamais accès aux coordonnées, messages, scores internes ou exports de membres.

## Zones de pages

```text
Public
  /
  /annonces
  /annonces/:slug
  /membres/:public_slug
  /associations
  /associations/:slug
  /partenaires
  /partenaires/:slug
  /voyage-solidaire
  /journal
  /legal/*

Compte membre
  /compte/*

Espace organisation
  /organisations/:slug/espace/*

Administration
  /admin/*
  /super_admin/*
```

## Définition de terminé commune

Chaque feature doit satisfaire tous les points applicables :

- migration relue, clés étrangères, index, contraintes et données de démonstration ;
- modèle avec validations utiles sans dupliquer seulement le formulaire ;
- policy/autorisation testée pour les six audiences ;
- action métier dédiée pour les transitions, calculs, points et objets append-only ;
- routes REST et statuts HTTP cohérents ;
- pages desktop/mobile, états vide/chargement/erreur/succès et navigation clavier ;
- équivalent admin livré dans le même lot ;
- données privées absentes du HTML, JSON, logs, analytics et e-mails non autorisés ;
- audit et notification pour toute action sensible ;
- specs RSpec modèle/service/query/policy/requête/job/mailer/système applicables, avec cas positifs et négatifs ;
- test visuel pour tout écran ou composant qui change le rendu du thème par défaut ;
- `yarn build` produisant JS et CSS, `bundle exec rspec`, RuboCop et Brakeman réussis ;
- critères d'acceptation de la user story/maquette reliés au test correspondant.

## Vue d'ensemble de l'ordre

| Phase | Features | Sortie de phase |
|---|---|---|
| 0. Socle | F-001 à F-009 | Application testée, navigable, authentifiée, autorisée, observable et administrable visuellement |
| 1. Découverte | F-010 à F-017 | Visiteur → profil → annonce → publication, séparateurs, carte et SEO/GEO |
| 2. Échange | F-020 à F-024 | Demande, discussion, réalisation, avis et modération |
| 3. Confiance | F-030 à F-033 | Parrainage initial, score explicable et recours humain |
| 4. Points | F-040 à F-043 | Registre, transferts et barèmes versionnés, jamais d'achat de points |
| 5. Engagement | F-050 à F-053 | Quêtes, Top annonces, témoignages, chaînes et soutien dormant |
| 6. Organisations | F-060 à F-062 | Associations, missions, annonces monde et partenaires |
| 7. Finalisation | F-070 à F-073 | RGPD, grand admin, qualité et lancement |

---

# Phase 0 — Fondations

## F-001 — Socle Rails 8, assets et environnement

**Dépendance :** aucune.

| Visiteur | Membre | Association | Partenaire | Admin | Super-admin |
|---|---|---|---|---|---|
| Page d'accueil technique sans erreur | Même rendu après connexion | Sans objet | Sans objet | `/admin` protégé existe | `/super_admin` protégé existe |

À construire : vérifier Rails 8.1, SQLite, Propshaft, Hotwire et esbuild ; imposer l'import CSS depuis `app/javascript`; faire produire JS et CSS par l'unique commande `yarn build`; garder `bin/dev` en watch ; installer/configurer RSpec avant les premiers générateurs ; configurer environnements, credentials, locale française, fuseau horaire, mailer et `/up`.

Tests de sortie : démarrage neuf via `bin/setup`, base préparée, sorties `application.js` et `application.css`, assets précompilés, aucune erreur console, page `/up`, première spec système et erreurs 404/500 propres.

## F-002 — Design system et layouts

**Dépendance :** F-001.

| Visiteur | Membre | Association | Partenaire | Admin | Super-admin |
|---|---|---|---|---|---|
| Header/footer et pages publiques | Navigation compte | Navigation organisation | Navigation organisation limitée | Layout dense avec sidebar | Même layout + zones exclusives |

À construire : référence système immuable `SEOS Default v1`, tokens exacts SEOS, Playfair/DM Sans auto-hébergées, boutons, champs, cartes, badges, modales, toasts, tables, pagination, états vides et responsive. Créer les partials partagés et le lien d'évitement ; icônes SVG cohérentes ; reduced motion.

Tests de sortie : captures/baselines aux largeurs `320`, `375`, `414`, `768`, `1024`, `1280`, `1440`, zoom 200 %, clavier, focus, contrastes et absence de débordement. La baseline n'est jamais mise à jour automatiquement.

## F-003 — Authentification, sessions et récupération

**Dépendances :** F-001, F-002. **Génération :** Devise.

| Visiteur | Membre | Association | Partenaire | Admin | Super-admin |
|---|---|---|---|---|---|
| Inscription, connexion, oubli du mot de passe | Déconnexion, sessions et changement de mot de passe | Connexion comme membre habilité | Idem | Connexion renforcée | Connexion renforcée et récupération contrôlée |

À construire : Devise avec e-mail normalisé/unique, Confirmable, limitation de débit, anti-robot accessible, rotation/révocation de session, mot de passe oublié et journal des sessions. Google OmniAuth est le premier login social avec scopes minimaux. Facebook reste derrière `facebook_login_enabled = false` jusqu'à validation de compatibilité Ruby/Rails.

Tests de sortie : création, confirmation, mauvais mot de passe, jeton expiré/réutilisé, session révoquée, utilisateur suspendu, fixation de session et accès direct interdit.

## F-004 — Rôles, permissions et memberships

**Dépendance :** F-003. **Données :** `users.role`, `admin_permission_grants`, `organization_memberships`.

| Visiteur | Membre | Association | Partenaire | Admin | Super-admin |
|---|---|---|---|---|---|
| Aucun accès protégé | Ses propres ressources | Ressources de son association selon membership | Brouillons de son organisation seulement | Actions selon permission | Gestion rôles, admins et permissions |

À construire : policies centralisées, helpers de navigation, interdiction par défaut, rôles `member/admin/super_admin`, memberships `owner/manager/editor`, permissions admin granulaires et expiration/révocation.

Tests de sortie : matrice positive/négative complète ; un editor ne gère pas l'équipe ; un partenaire ne voit aucune donnée membre ; un admin sans permission reçoit 403/404 approprié ; seul le super-admin promeut un admin.

## F-005 — Socle du panneau d'administration

**Dépendances :** F-002 à F-004.

| Visiteur | Membre | Association | Partenaire | Admin | Super-admin |
|---|---|---|---|---|---|
| Aucun rendu admin | Aucun rendu admin | Aucun rendu admin | Aucun rendu admin | Dashboard, recherche, filtres et sections autorisées | Toutes les sections et gestion admin |

À construire : vrais namespaces, sidebar en accordéons, page standard, tableaux responsives, recherche globale, filtres URL, pagination, vues enregistrées, actions de masse sûres, fil d'audit et réauthentification.

Tests de sortie : aucune route admin publique, permissions par section, filtres persistants, export limité, action idempotente, navigation clavier et mobile.

## F-006 — Audit, stockage, jobs et notifications techniques

**Dépendances :** F-001 à F-005. **Données :** Active Storage, `audit_logs`, `sensitive_data_access_logs`.

| Visiteur | Membre | Association | Partenaire | Admin | Super-admin |
|---|---|---|---|---|---|
| Upload public interdit sauf flux précis | Uploads propres et notifications | Médias organisation | Logo/contenus autorisés | Échecs de jobs et audit selon droit | Audit global et politique de conservation |

À construire : validation MIME/taille/nombre, réencodage et retrait EXIF, Solid Queue, e-mails transactionnels via Gmail API/client Ruby Google, idempotence, journal append-only, masquage des paramètres/credentials sensibles et alertes de panne.

Tests de sortie : faux MIME, fichier trop gros, job rejoué, e-mail échoué/repris, absence de secret dans logs, purge d'un blob orphelin et audit impossible à modifier.

## F-007 — Infrastructure RSpec et non-régression

**Dépendances :** F-001, F-002. **Ordre particulier :** RSpec est déjà installé dans F-001 ; cette feature industrialise la suite avant les modèles métier.

| Visiteur | Membre | Association | Partenaire | Admin | Super-admin |
|---|---|---|---|---|---|
| Parcours public témoin | Session et parcours témoin | Contexte membership témoin | Isolement partenaire témoin | Permission positive/négative témoin | Exclusivité sensible témoin |

À construire : configuration RSpec Rails 8, factories, helpers d'authentification, exemples partagés de policies, drivers système JS, données déterministes, couverture ligne/branche, comparaison visuelle, accessibilité automatisée, parallélisation et pipeline CI. Toute nouvelle feature doit déclarer son paquet de specs avant d'être terminée.

Tests de sortie : la suite part d'une base neuve, exécute unité/requête/job/système/visuel, échoue si les assets sont périmés ou si une baseline change sans revue, et publie des résultats exploitables. Cibles : 100 % des user stories/features/policies/transitions tracées, 95 % des lignes et 90 % des branches au minimum.

## F-008 — Studio des thèmes UI/UX

**Dépendances :** F-002, F-004 à F-007. **Données :** `design_themes`, versions et audits.

| Visiteur | Membre | Association | Partenaire | Admin | Super-admin |
|---|---|---|---|---|---|
| Voit uniquement le thème publié | Idem | Idem dans l'espace organisation | Idem | Consulte état/preview si autorisé | Clone, modifie, valide, publie, rollbacke et reset |

À construire : éditeur allowlisté de couleurs, typographies, espacements, formes, composants et mouvement ; preview desktop/tablette/mobile ; cycle brouillon → validé → publié ; comparaison à `SEOS Default v1` ; reset par token/groupe/composant/thème/site. Aucun champ de CSS, HTML, SVG ou JavaScript libre.

Tests de sortie : permissions des six audiences, bornes de tokens, contraste bloquant, concurrence de publication, cache, invalidation, rollback, reset exact et audit. Après modification, les parcours restent lisibles, sans overflow et respectent reduced motion.

## F-009 — Studio des pages, contenus et médias

**Dépendances :** F-006 à F-008. **Données :** `page_definitions`, `page_versions`, `content_blocks`, `media_assets`, resets.

| Visiteur | Membre | Association | Partenaire | Admin | Super-admin |
|---|---|---|---|---|---|
| Lit seulement la version publiée | Contenus adaptés à la session | Propose ses contenus autorisés | Propose ses brouillons autorisés | Édite/preview selon permission | Définit schémas, publie, rollbacke et reset tout périmètre |

À construire : registre de toutes les pages publiques, compte, organisation, admin, erreurs et e-mails ; champs titre, description, contenu, CTA, image/vidéo, alt, crédit/licence, point focal, SEO, ordre, visibilité et programmation ; médiathèque réutilisable ; reset champ/bloc/média/page/site ; preview par audience. Les templates restent codés, les valeurs sont administrables.

Tests de sortie : brouillon invisible, publication atomique, programmation, média référencé non supprimable, alt requis, URL sûre, preview isolée, cache invalidé, rollback et reset exact sans perte d'historique. Une association ou un partenaire ne publie jamais directement et ne sort pas de son périmètre.

---

# Phase 1 — Découverte, profils et annonces

## F-010 — Accueil, pages explicatives, journal et centre légal

**Dépendances :** phase 0, particulièrement F-009. **Données :** pages/blocs versionnés, `articles`, `legal_document_versions`.

| Visiteur | Membre | Association | Partenaire | Admin | Super-admin |
|---|---|---|---|---|---|
| Accueil, Don, Échange, Points, journal, légal | Même contenu + CTA adaptés | Peut être présenté si publié | Peut être présenté si partenariat actif | Brouillons, aperçu et modération | Publication légale et réglages globaux |

À construire : toutes les sections de la maquette, vidéo Active Storage/HTML5, contenus versionnés, aperçu desktop/mobile, dates de publication, SEO et page Contact publique. Le formulaire Contact écrit uniquement à l'équipe SEOS ; il ne crée ni demande, ni message d'annonce. Aucun HTML/CSS/JS arbitraire dans les blocs CMS.

Tests de sortie : seuls contenus publiés visibles, programmation, archivage, ancienne version légale conservée, médias externes bloqués avant consentement, anti-spam Contact et impossibilité pour un visiteur d'écrire à un annonceur.

## F-011 — Profil privé et profil de service public

**Dépendances :** F-003, F-004, F-006. **Données :** `profiles`, avatar Active Storage.

| Visiteur | Membre | Association | Partenaire | Admin | Super-admin |
|---|---|---|---|---|---|
| Profil public, annonces et Trust public | Édition privée + aperçu visiteur | Profil personnel distinct de l'organisation | Idem | Profil public, privé masqué, actions modération | Révélation motivée et auditée |

À construire : `display_name`, slug public, bio, zone large, langues/compétences, avatar facultatif, coordonnées chiffrées et politique de partage par échange. Créer `/membres/:public_slug` sans annuaire exhaustif exportable.

Tests de sortie : aucune coordonnée dans HTML/JSON/métadonnées ; profil public accessible sans session ; aperçu membre identique ; profil restreint/anonymisé ; révélation admin journalisée.

## F-012 — Catégories et référentiels

**Dépendances :** F-005. **Génération :** scaffold admin `Category`.

| Visiteur | Membre | Association | Partenaire | Admin | Super-admin |
|---|---|---|---|---|---|
| Parcourt catégories actives | Les choisit dans les formulaires | Catégories mission autorisées | Consultation | CRUD, ordre, activation | Fusion/archivage exceptionnel et paramètres sensibles |

À construire : hiérarchie, slugs, ordre, activation, icône/image, catégories sensibles, critères d'avis liés, règle d'héritage Trust et blacklist administrable. Chaque restriction possède catégorie/terme, portée, motif, période et action de revue/pause sur l'existant.

Tests de sortie : slug unique, cycle hiérarchique impossible, catégorie inactive/non autorisée impossible à publier, permissions admin/super-admin, restriction planifiée/expirée, annonce existante mise en revue sans suppression silencieuse et historique conservé.

## F-013 — Catalogue, carte et détail d'annonce

**Dépendances :** F-011, F-012. **Données :** `listings`, médias.

| Visiteur | Membre | Association | Partenaire | Admin | Super-admin |
|---|---|---|---|---|---|
| Recherche, filtres, liste/carte, détail | Favori/contact après authentification | Consulte comme membre | Consulte comme membre | Aperçu public, historique et modération | Paramètres catalogue et pays |

À construire : offres/demandes, trois modes, zone/rayon via Geocoder, carte Leaflet avec fournisseur configurable, distance approximative, à distance, urgence, Top, tri, pagination, état vide, galerie et partage sans traceur. L'adresse exacte n'est jamais envoyée publiquement. Le rendu carte dépend uniquement de `public_map_enabled` et possède toujours une alternative liste complète.

Tests de sortie : combinaisons de filtres, pagination stable, coordonnées arrondies, annonce non publiée inaccessible, carte clavier/alternative liste, états flag on/off et métadonnées SEO sûres.

## F-014 — Publication et gestion de ses annonces

**Dépendances :** F-011 à F-013.

| Visiteur | Membre | Association | Partenaire | Admin | Super-admin |
|---|---|---|---|---|---|
| Redirigé vers inscription | Assistant 4 étapes, brouillon et cycle de vie | Publication propre via espace organisation si autorisée | Pas d'annonce membre au nom du partenariat | Modération, correction limitée, masquage | Publication exceptionnelle au nom d'une organisation |

À construire : intention, mode, estimation points conditionnelle, détails, adresse privée, disponibilité, médias, aperçu, conditions, sauvegarde/reprise, pause/clôture/suppression logique.

Tests de sortie : paramètres sensibles rejetés, propriétaire obligatoire, mode/points cohérents, upload contrôlé, sortie/reprise, autorisations et historique des changements.

## F-015 — Séparateurs organiques de sections

**Dépendances :** F-002, F-009, F-010. **Données :** `section_decorations`.

| Visiteur | Membre | Association | Partenaire | Admin | Super-admin |
|---|---|---|---|---|---|
| Voit les séparateurs publiés | Idem avec reduced motion | Preview de ses pages autorisées | Preview de ses pages autorisées | Configure contenu si habilité | Gère presets, instances, animation et resets |

À construire : plusieurs séparateurs par page/frontière, presets `wave_single`, `wave_double`, `soft_curve`, `asymmetric_blob`, `scallop`, `diagonal_soft`, `mist_fade`, couleurs par tokens, tailles mobile/desktop, inversions et variante stable. Animations `static`, `reveal_once`, `drift_once`, `morph_once`, `ambient_slow`, avec arrêt hors écran et fallback statique.

Tests de sortie : placement/ordre, plusieurs instances, reset, pages sans séparateur, viewports, contrastes adjacents, aucun contenu masqué, aucune secousse de layout, arrêt hors écran, limite d'animations ambiantes et `prefers-reduced-motion` sans mouvement.

## F-016 — Pilotage super-admin de la carte publique

**Dépendances :** F-007, F-008, F-013. **Données :** `feature_flags`, audits.

| Visiteur | Membre | Association | Partenaire | Admin | Super-admin |
|---|---|---|---|---|---|
| Carte ou liste selon flag | Même état global | Même état global | Même état global | Consulte l'état seulement | Active, désactive et reset le flag |

À construire : flag système `public_map_enabled` activé par défaut, écran d'impact, confirmation, changement atomique, invalidation des caches, audit et retour au défaut. Quand il est faux, ne rendre ni bouton, ni conteneur, ni script, ni SDK, ni tuile, ni cookie, ni appel réseau cartographique ; conserver liste, recherche, rayon et distance approximative.

Tests de sortie : policy super-admin, admin refusé, double clic/concurrence, audit, cache multi-session, reset, flag on/off en RSpec système et assertion réseau démontrant l'absence totale du fournisseur lorsqu'il est coupé.

## F-017 — SEO des annonces, Schema.org et GEO

**Dépendances :** F-007, F-009 à F-016. **Données :** `seo_configuration_versions`, état d'indexabilité des annonces.

| Visiteur | Membre | Association | Partenaire | Admin | Super-admin |
|---|---|---|---|---|---|
| Trouve une annonce canonique sans PII | Prévisualise les données indexables de son annonce | Pages publiques indexables autorisées | Fiche publique limitée | Diagnostique/modère indexabilité et erreurs | Publie règles SEO/GEO, Schema.org, crawlers et resets |

À construire : rendu serveur, canonical, titres/descriptions, Open Graph, sitemap index segmenté, `lastmod`, cycle `200/noindex/301/410`, maillage catégories/zones et JSON-LD généré. Offre = `Service`, avec `Offer` seulement si une `businessFunction` non commerciale explicite et fidèle est validée ; demande = `Demand` + `Service`; catalogue = `CollectionPage/ItemList`; profils = `ProfilePage/Person`; organisations/articles selon leur type réel. Aucun JSON-LD libre, prix EUR pour les PS, donnée cachée ou page locale vide. GEO : contenu original structuré, entités `@id` stables, fraîcheur, robots distincts recherche/entraînement, Search Console et mesure des référents génératifs.

Tests de sortie : JSON-LD parseable et égal au visible, canonical unique malgré filtres/carte, sitemap réservé aux actives, aucune PII dans meta/JSON-LD/sitemap, blacklist/noindex, transitions de cycle, profils `noindex`, comptes/admin/previews bloqués, `OAI-SearchBot` distinct de `GPTBot`, carte off sans casser le SEO et aucune utilisation abusive de Google Indexing API.

---

# Phase 2 — Mise en relation et échange

## F-020 — Demandes de service

**Dépendances :** F-013, F-014. **Données :** `service_requests`.

| Visiteur | Membre | Association | Partenaire | Admin | Super-admin |
|---|---|---|---|---|---|
| Se connecte avant demande | Crée, reçoit et suit ses demandes | Agit via un gestionnaire autorisé pour une mission | Sans objet | Consulte pour support/modération | Paramètres et accès exceptionnel |

À construire : demande distincte du message, boîte envoyées/reçues, statuts contrôlés, refus, annulation, délais et notifications. Interdire sa propre annonce.

Tests de sortie : transitions invalides, requête concurrente, annonce fermée, acteur tiers, compteur et filtres de statut.

## F-021 — Messagerie et centre de notifications

**Dépendance :** F-020. **Données :** `messages`, `notifications`.

| Visiteur | Membre | Association | Partenaire | Admin | Super-admin |
|---|---|---|---|---|---|
| Aucun message | Conversations participantes | Conversations liées aux missions autorisées | Seulement contact institutionnel dédié | Contenu masqué, révélation liée à un dossier | Même règle, accès sensible audité |

À construire : messages Turbo, pièces jointes, lecture/non-lu, préférences e-mail, limitation de débit, blocage et signalement. Aucune prévisualisation de conversation en liste admin.

Tests de sortie : participant uniquement, pièce jointe, double envoi, notification idempotente, lecture, préférence, signalement et révélation auditée.

## F-022 — Accord, réalisation, confirmation et litige

**Dépendances :** F-020, F-021.

| Visiteur | Membre | Association | Partenaire | Admin | Super-admin |
|---|---|---|---|---|---|
| Sans objet | Négocie, planifie, réalise, confirme ou conteste | Même cycle pour mission si applicable | Sans objet | Médiation sans se substituer aux confirmations | Règles globales et revue exceptionnelle |

À construire : chronologie, accord sur date/lieu/mode/montant, partage ponctuel de coordonnées, double confirmation, annulation attribuable seulement après revue et dossier de litige.

Tests de sortie : deux confirmations concurrentes, montant changé, absence d'accord, annulation neutre, litige, coordonnée révoquée et chronologie complète.

## F-023 — Avis structurés

**Dépendances :** F-022, F-012. **Données :** `reviews`, `review_criteria`, `review_ratings`.

| Visiteur | Membre | Association | Partenaire | Admin | Super-admin |
|---|---|---|---|---|---|
| Lit les avis publiés | Évalue un échange auquel il participe | Évalue/reçoit au nom du participant réel | Sans objet | Modère sans réécrire les réponses | Versionne les règles sensibles si nécessaire |

À construire : critères communs/par rôle/par catégorie, fenêtre 30 jours, double aveugle 14 jours, texte factuel, réponse, signalement, invalidation Trust motivée.

Tests de sortie : un avis par auteur/échange, non-participant refusé, révélation différée, non applicable, texte retiré mais note conservée/infirmée selon décision.

## F-024 — Favoris, commentaires et signalements

**Dépendances :** F-013, F-021.

| Visiteur | Membre | Association | Partenaire | Admin | Super-admin |
|---|---|---|---|---|---|
| Consulte commentaires, signale via flux protégé | Favoris privés, commentaire et signalement | Modère ses contenus sans masquer un tiers | Commentaire institutionnel si autorisé | File, SLA, action et notification | Politiques, catégories et audit global |

À construire : favoris idempotents, commentaires distincts des avis, réponses éventuelles, statuts de modération, preuves et objectif de traitement.

Tests de sortie : double favori, commentaire supprimé logiquement, signalement cible polymorphe, assignation, échéance et action réversible.

---

# Phase 3 — Parrainage et Trust Score

## F-030 — Parrainage multi-code à l'inscription

**Dépendances :** F-003, F-005. **Données :** `referral_codes`, `referrals`, Trust Event.

| Visiteur | Membre | Association | Partenaire | Admin | Super-admin |
|---|---|---|---|---|---|
| Saisit jusqu'à 10 codes pendant l'inscription | Génère un code, voit ses soutiens et choisit le principal | Aucun privilège automatique | Aucun privilège automatique | Inspecte, invalide avec motif, traite objection | Configure limites/version et exemptions fondatrices |

À construire : codes aléatoires à usage unique, fenêtre de sept jours, 10 parrains distincts, positions, parrain principal, objection 72 h, poids `0,25`, score provisoire et notification.

Règle Points Services : le nouveau membre ne reçoit aucun point. Le parrain principal reçoit `15 PS` une seule fois dans la vie de sa quête après vérification e-mail, 30 jours et deux échanges du filleul avec des non-parrains. Les neuf autres codes alimentent seulement le Trust initial.

Tests de sortie : 0/1/3/5/10 codes, onzième refusé, doublon, expiré, réutilisé, auto-parrainage, concurrence, objection, invalidation et un seul principal.

## F-031 — Moteur Trust global, par tâche et par dimension

**Dépendances :** F-022, F-023, F-030. **Données :** tables `trust_*`.

| Visiteur | Membre | Association | Partenaire | Admin | Super-admin |
|---|---|---|---|---|---|
| Lit le score public autorisé | Voit détail et évolution propres | Aucun score d'organisation dérivé des membres | Aucun accès aux scores internes | Événements, calcul et snapshots en lecture | Crée, simule et active une version |

À construire : normalisation, poids source/auteur/récence/paire/contexte, formule bayésienne, scores catégories/dimensions, confiance statistique, seuils, recalcul asynchrone et snapshots.

Tests de sortie : bornes, déterminisme, idempotence, ordre sans effet, répétition plafonnée, parrainages 53/58/62/69, dilution par échanges, version et retour.

## F-032 — Présentation, explication et recours Trust

**Dépendance :** F-031.

| Visiteur | Membre | Association | Partenaire | Admin | Super-admin |
|---|---|---|---|---|---|
| Score/provisoire, catégories et explication | Événements personnels et contestation | Voit seulement les scores publics nécessaires | Idem | Instruit le recours et corrige la source | Supervise délais et gouvernance |

À construire : composants score, état sans données, marque `provisoire`, nombre de parrains sans identité, confiance du calcul, date/version, explication accessible et parcours de recours humain.

Tests de sortie : nouveau non parrainé, nouveau avec codes, score établi, catégorie sans preuve, recours accepté/refusé, recalcul et aucun signal interne public.

## F-033 — Risque interne et lutte contre la manipulation

**Dépendances :** F-030, F-031, F-005.

| Visiteur | Membre | Association | Partenaire | Admin | Super-admin |
|---|---|---|---|---|---|
| Aucun signal interne | Notification d'une mesure et recours approprié | Aucun accès | Aucun accès | Revue humaine selon permission | Règles, supervision et audit |

À construire : signaux minimisés de rafale, cycles, paires, codes, comptes liés et farming ; priorité de revue ; expiration ; aucune sanction ou baisse publique avant décision humaine.

Tests de sortie : grappes synthétiques, foyer légitime, faux positif, signal expiré, accès restreint, action motivée, recours et AIPD mise à jour.

---

# Phase 4 — Points Services

## F-040 — Comptes et registre append-only

**Dépendances :** F-003, F-005, F-006. **Données :** `point_accounts`, `point_operations`, `point_entries`.

| Visiteur | Membre | Association | Partenaire | Admin | Super-admin |
|---|---|---|---|---|---|
| Aucun solde | Solde et historique propres | Compte organisation seulement si décidé plus tard | Aucun point lié au partenariat | Audit et actions dédiées | Comptes système et règles globales |

À construire : partie double, compte système, somme nulle, idempotence, verrouillage, solde non négatif, libellés et sources. Aucun endpoint d'achat, de vente, de conversion ou de retrait.

Tests de sortie : équilibre, double écriture, concurrence, correction compensatrice, impossibilité update/destroy et absence complète de panier/paiement de points.

## F-041 — Transfert après échange

**Dépendances :** F-022, F-040.

| Visiteur | Membre | Association | Partenaire | Admin | Super-admin |
|---|---|---|---|---|---|
| Sans objet | Confirme montant et transfert | Participant autorisé uniquement | Sans objet | Observe, ne confirme pas à la place | Médiation exceptionnelle auditée |

À construire : montant négocié, double confirmation, solde prévisionnel, débit/crédit atomique, notification et source vers l'échange.

Tests de sortie : solde insuffisant, double clic, deux confirmations, montant modifié, litige, annulation compensatrice et historique identique aux écritures.

## F-042 — Bonus, récompenses et ajustements

**Dépendance :** F-040.

| Visiteur | Membre | Association | Partenaire | Admin | Super-admin |
|---|---|---|---|---|---|
| Sans objet | Reçoit les récompenses prévues une fois | Selon action membre, pas au titre de l'organisation seule | Aucun avantage de partenariat | Ajustement motivé selon permission | Barèmes, gros ajustements et contrôle global |

À construire : récompense de quête d'accueil (valeur maquette 30 PS), autres quêtes, chaîne, parrain principal et série d'échanges via sources idempotentes et référence à la version de règle appliquée ; ajustement avec aperçu d'impact ; seuil éventuel de double validation. Aucun crédit automatique ne doit être présenté comme un achat de points.

Tests de sortie : bonus unique, période mensuelle, parrain principal seul, plafond chaîne, opération rejouée et reversal. Aucun soutien financier ne crédite des Points Services.

## F-043 — Pilotage des valorisations, bonus et niveaux

**Dépendances :** F-005, F-007, F-040 à F-042. **Données :** `point_valuation_versions`, tranches et `engagement_rule_versions`.

| Visiteur | Membre | Association | Partenaire | Admin | Super-admin |
|---|---|---|---|---|---|
| Lit la version indicative publiée | Voit estimation/barème applicable | Idem pour ses membres | Aucun contrôle | Consulte et simule si habilité | Crée, simule, publie, planifie et rollbacke |

À construire : tranches euros → PS purement indicatives, valeurs possibles, cycle après N échanges, récompenses Bronze/Argent/Gold, plafonds et dates d'effet. Les versions publiées sont immuables, non rétroactives par défaut et référencées par chaque calcul/opération. Aucune expression exécutable ni option d'achat/conversion.

Tests de sortie : bornes/trous/chevauchements de tranches, estimation déterministe, version future, deux publications concurrentes, simulation avant/après, opérations historiques inchangées, rollback, permissions et impossibilité de créer paiement/retrait de PS.

---

# Phase 5 — Engagement communautaire

## F-050 — Quêtes, succès et niveaux

**Dépendances :** F-006, F-040, F-042, F-043. **Données :** `achievements`, rewards, `user_achievements`.

| Visiteur | Membre | Association | Partenaire | Admin | Super-admin |
|---|---|---|---|---|---|
| Voit l'explication publique | Progression, preuve, états et récompense | Progression personnelle du gestionnaire seulement | Aucun avantage Trust | CRUD, revue des preuves, attribution via moteur | Version des barèmes et règles globales |

À construire : ponctuel/mensuel/cycle, cibles, preuve, revue, Bronze/Argent/Gold et période unique. Niveaux et points n'entrent pas dans le Trust Score.

Tests de sortie : double soumission, preuve absente, période, barème par niveau, refus/réexamen et récompense idempotente.

## F-051 — Top annonces, urgence, témoignages et partage

**Dépendances :** F-013, F-050. **Données :** `top_listing_requests`, `testimonials`.

| Visiteur | Membre | Association | Partenaire | Admin | Super-admin |
|---|---|---|---|---|---|
| Voit badges et témoignages publiés | Demande Top, soumet témoignage/partage | Demande pour mission autorisée | Propose contenu partenaire via son espace | Éligibilité, revue, ordre et périodes | Politique, garanties et contenus globaux |

À construire : badge urgent avec durée, Top après demande humaine, témoignage écrit/vidéo avec consentement, partage mensuel prouvé, suppression/retrait de publication.

Tests de sortie : période Top, annonce fermée, consentement témoignage, retrait, récompense unique, partage sans traceur. La « garantie du double » reste désactivée tant que son cadre n'est pas validé.

## F-052 — Chaînes d'entraide

**Dépendances :** F-003, F-040, F-042.

| Visiteur | Membre | Association | Partenaire | Admin | Super-admin |
|---|---|---|---|---|---|
| Ouvre un lien limité et s'identifie | Crée, invite, suit et valide | Peut participer comme membre | Sans objet | Inspecte, traite litiges et fraude | Publie longueur, gains, profondeur et plafonds |

À construire : chaîne illimitée par défaut, maillons, contact tiers minimisé, jeton condensé/expirant/unique, retour après authentification et validation atomique. `chain_rule_versions` permet `unlimited` ou `limited`, limite éventuelle, provider seul/derniers N/autres scopes autorisés, gain par validation/maillon et plafonds. Une simulation bloque toute émission maximale incomprise.

Tests de sortie : chaîne dépassant dix maillons sans fin, mode limité à la frontière, jeton expiré/réutilisé, auto-validation, boucle, branche, profondeurs de récompense, gain/plafond, version historique, deux validations concurrentes et information du bénéficiaire.

## F-053 — Soutien financier Stripe dormant

**Dépendances :** F-005 à F-007, F-040 pour prouver l'isolement. **Données :** `financial_contributions`, `payment_events`, flag.

| Visiteur | Membre | Association | Partenaire | Admin | Super-admin |
|---|---|---|---|---|---|
| Aucun parcours tant que flag off | Idem | Aucun droit financier | Aucun droit financier | Lecture/rapprochement si autorisé | Active seulement après validations et pilote le flag |

À construire : architecture Stripe Checkout en mode paiement unique, webhooks signés/idempotents, remboursements et rapprochement, mais `financial_support_enabled = false` par défaut. Le soutien est un don/contribution sans achat, contrepartie, PS, niveau, Trust ou mise en avant. Aucun reçu fiscal sans habilitation confirmée.

Tests de sortie : routes/CTA absents flag off, activation super-admin auditée, montant/currency bornés, événement rejoué, signature invalide, succès/échec/remboursement, aucune écriture dans les comptes PS et aucune promesse fiscale.

---

# Phase 6 — Associations, missions et partenaires

## F-060 — Organisations et équipe

**Dépendances :** F-004, F-006, F-011. **Données :** `organizations`, `organization_memberships`.

| Visiteur | Membre | Association | Partenaire | Admin | Super-admin |
|---|---|---|---|---|---|
| Fiche publique publiée | Demande/reçoit une invitation d'équipe | Gère profil/équipe selon owner/manager/editor | Même socle, droits limités au partenariat | Vérifie, refuse, suspend, restaure | Paramètres, types et actions exceptionnelles |

À construire : création/demande, slug, type, identité légale privée, description publique, membres, invitations, aperçu public, vérification et historique.

Tests de sortie : owner unique ou règle définie, editor limité, invitation expirée, retrait du dernier owner, suspension et aucune fuite du contact légal.

## F-061 — Associations, Voyage solidaire et annonces monde

**Dépendances :** F-060, F-013, F-020. **Données :** missions et candidatures.

| Visiteur | Membre | Association | Partenaire | Admin | Super-admin |
|---|---|---|---|---|---|
| Annuaire, fiche, missions et Voyage | Consulte/candidate | Crée brouillon, gère missions et candidatures | Aucun droit par défaut | Vérifie et modère | Crée/publie une annonce monde au nom d'une association |

À construire : `/associations`, fiche, catalogue Voyage, mission, médias, dates, capacité, hébergement, langues, contribution `0–15 €` par jour, candidature et conversation. La user story 28 est satisfaite par l'action exclusive du super-admin ; l'association vérifiée peut proposer et gérer ses brouillons.

Tests de sortie : organisation non vérifiée, plafond base/serveur, dates, droits membership, candidature doublon, masquage adresse, publication super-admin auditée et feature flag.

## F-062 — Partenariats et pages partenaires

**Dépendances :** F-010, F-060. **Données :** `partnerships`.

| Visiteur | Membre | Association | Partenaire | Admin | Super-admin |
|---|---|---|---|---|---|
| `/partenaires` et fiche publique | Même lecture | Peut aussi avoir un partenariat distinct | Propose ses textes/logo, voit l'aperçu | CRUD, revue, publication, ordre et dates | Types, activation globale et décisions sensibles |

À construire : partenariat institutionnel/opérationnel/technique/soutien, période, contenu public, logo, CTA, ordre, archive et espace brouillon. Aucun annuaire de membres transmis au partenaire ; aucun tracking tiers automatique.

Tests de sortie : partenariat expiré/archivé, brouillon invisible, logo, lien externe sûr, ordre, membre non habilité et absence totale d'accès aux données privées.

---

# Phase 7 — Conformité, grand admin et finitions

## F-070 — Cookies, confidentialité et droits RGPD

**Dépendances :** toutes les features manipulant des données. **Données :** consentements et `data_requests`.

| Visiteur | Membre | Association | Partenaire | Admin | Super-admin |
|---|---|---|---|---|---|
| Préférences cookies et notices | Accès, export, rectification, effacement, opposition | Droits individuels + contact organisation | Droits individuels + contact organisation | Traite les demandes selon permission | Registre, politiques et supervision des délais |

À construire : choix symétrique accepter/refuser, consentement versionné, tableau confidentialité, export temporaire, vérification proportionnée, purge, anonymisation et propagation prestataires. Ajouter `retention_policy_versions` par finalité, simulation de purge, rapport et interdiction d'une conservation personnelle globale à vie.

Tests de sortie : aucun traceur avant consentement, retrait, export expiré, délai admin, effacement partiel expliqué, profil dépublié, aucune durée globale `forever`, règle expirée, purge simulée/exécutée et conservation probatoire minimisée.

## F-071 — Administration complète et pilotage

**Dépendances :** F-005 et toutes les ressources métier.

| Visiteur | Membre | Association | Partenaire | Admin | Super-admin |
|---|---|---|---|---|---|
| Aucun accès | Aucun accès | Son espace séparé | Son espace séparé | Tour de contrôle selon permissions | Vue totale autorisée et gouvernance |

À construire : toutes les sections du document admin, dont Studio UI/contenus, blacklist, barèmes, SEO/GEO, conservation et feature flags, fiche utilisateur 360°, recherche globale, files de travail, indicateurs, exports limités, révélations sensibles, réauthentification, actions de masse sûres et audit.

Règle de fermeture : chaque ressource livrée auparavant doit apparaître dans l'admin en lecture, gestion ou modération selon sa nature. Points, Trust Events, snapshots et audits n'ont jamais de bouton modifier/supprimer.

Tests de sortie : parcours complet de chaque permission, données masquées, motif de révélation, export, opération compensatrice, action de masse, mobile/clavier et double validation sensible.

## F-072 — Sécurité, accessibilité, performance et SEO

**Dépendance :** produit fonctionnel complet.

| Visiteur | Membre | Association | Partenaire | Admin | Super-admin |
|---|---|---|---|---|---|
| Pages rapides, indexation maîtrisée | Sessions et parcours accessibles | Même niveau de qualité | Aucun tracker imposé | Interface dense mais accessible | Rapports techniques et remédiation |

À construire : CSP, en-têtes, rate limits, scans uploads, dépendances, sauvegarde/restauration, requêtes/index, images modernes, cache, budgets JS, Gmail API, Google OAuth, Geocoder/Leaflet, sitemaps des annonces, `noindex` profils initial, Schema.org sans PII, canonical/robots, GEO et WCAG 2.2 AA.

Tests de sortie : Brakeman, audit dépendances, performance des listes, sauvegarde restaurée, Gmail/provider en erreur, carte sans fournisseur, lecteur d'écran, zoom, reduced motion, pages 404/500, canonical/robots/Schema.org, crawlers recherche/entraînement et tentative de scraping limitée.

## F-073 — Recette, données de démonstration et lancement

**Dépendance :** F-001 à F-072.

| Visiteur | Membre | Association | Partenaire | Admin | Super-admin |
|---|---|---|---|---|---|
| Parcours public complet | Don, échange et points de bout en bout | Mission complète | Brouillon → publication partenaire | Modération et support complets | Gouvernance, rollback et incident |

À construire : seeds non production, comptes de chaque rôle, scénarios de démonstration, checklist légale, monitoring, procédure de déploiement/rollback, sauvegarde, support, incident et plan de communication.

Recette finale obligatoire :

1. visiteur → annonce → profil public sans donnée privée ;
2. inscription avec 0 puis 10 codes de parrainage ;
3. membre → publication → demande → messagerie → confirmation → avis ;
4. même échange en Points Services sans aucune possibilité d'achat ;
5. Trust provisoire puis établi, explication et recours ;
6. signalement → revue admin → décision → audit ;
7. association → mission → candidature ;
8. super-admin → annonce monde au nom d'une association ;
9. partenaire → brouillon de page → publication admin ;
10. export/effacement RGPD et purge du fichier temporaire ;
11. super-admin → variante UI → preview → publication → reset exact vers `SEOS Default v1` ;
12. modification/reset d'un titre, d'une description, d'une image et de son alt sur plusieurs pages ;
13. séparateurs statique/animé puis reduced motion et reset ;
14. carte activée puis désactivée sans aucun appel fournisseur, puis restaurée ;
15. annonce offre/demande → canonical → sitemap → JSON-LD sans donnée privée → retrait propre ;
16. super-admin → nouveau barème PS/bonus → simulation → publication → historique inchangé ;
17. chaîne dépassant dix maillons en mode illimité, puis règle limitée testée ;
18. visiteur → Contact équipe, puis tentative interdite de contacter une annonce ;
19. politique de conservation → simulation → purge, sans option globale à vie ;
20. Stripe flag off sans route publique ni écriture PS ;
21. restauration d'une sauvegarde et traitement simulé d'un incident.

La feature et le produit sont prêts seulement si la matrice de rôles, les tests de concurrence, la documentation d'exploitation et les validations juridiques requises sont réellement terminés.

## Ordre pratique d'une branche de feature

Pour chaque identifiant F-xxx :

1. relire la section correspondante et lier user story/maquette ;
2. créer une branche dédiée ;
3. générer uniquement les modèles/scaffolds indiqués ;
4. corriger immédiatement migration, clés, contraintes et namespace ;
5. écrire policy et specs RSpec d'autorisation avant les écrans sensibles ;
6. livrer le parcours public/membre/organisation applicable ;
7. livrer l'écran admin dans la même branche ;
8. ajouter audit, notification, états d'erreur et accessibilité ;
9. exécuter `yarn build`, `bundle exec rspec`, la comparaison visuelle applicable, RuboCop et Brakeman ;
10. cocher les critères de sortie et mettre à jour la matrice si une décision change.

## Décisions fermées et validations externes restantes

Décisions produit fermées : France/français ; Devise + Google login ; Gmail API ; Geocoder + Leaflet ; vidéo interne ; analytics tiers off ; barèmes Points/niveaux administrables ; chaîne illimitée par défaut et configurable ; blacklist ; Contact équipe seulement ; SEO/Schema.org/GEO ; soutien Stripe dormant et séparé.

Les validations restantes ne sont pas des ambiguïtés produit mais des prérequis de mise en production :

- credentials/comptes Google et fournisseur de géocodage/tuiles avec quotas/contrats ;
- vérification de compatibilité avant activation Facebook ;
- confirmation juridique/DPO des durées exactes et validation de l'AIPD Trust ;
- validation de l'entité, de la comptabilité, du vocabulaire « don » et de la fiscalité avant activation Stripe ;
- règle précise de double confirmation du transfert de PS ;
- harmonisation éditoriale du vocabulaire succès/quêtes ;
- décision juridique/budgétaire avant toute « garantie du double » ;
- politique d'âge et de catégories impliquant des publics vulnérables.
