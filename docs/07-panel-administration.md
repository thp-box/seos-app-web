# Grand panneau d'administration SEOS

## Vision

Le back-office SEOS est une tour de contrôle complète, pas une collection de scaffolds sans cohérence. Il doit permettre de trouver, comprendre et administrer presque tous les objets de la plateforme, tout en empêchant la réécriture silencieuse des éléments probants : opérations de points, événements de confiance, confirmations, messages et journaux d'audit.

Objectifs :

- répondre rapidement aux membres et traiter les signalements ;
- comprendre l'historique complet d'une annonce, d'un échange ou d'un compte ;
- administrer le catalogue, les contenus et les mécanismes d'engagement ;
- superviser les Points Services, le Trust Score et les anomalies ;
- exécuter les demandes RGPD et prouver les accès sensibles ;
- déléguer sans donner à chaque administrateur tous les pouvoirs ;
- rendre toute action sensible attribuable, motivée et, si possible, réversible.

## Référence étudiée : Template Marketplace

Le dépôt [`THP-Lab/template-marketplace`](https://github.com/THP-Lab/template-marketplace) a été étudié en lecture seule, sur le [commit `91d5206`](https://github.com/THP-Lab/template-marketplace/commit/91d52064704ef5e08a6cd5b1102d8b5ac182055b) du 17 juin 2026.

Bonnes idées à reprendre :

- sidebar pilotée par les données et regroupée en accordéons ;
- composants communs de page, navigation et pagination admin ;
- recherche, remise à zéro des filtres et listes paginées ;
- tableaux responsives avec lignes de détail ;
- réorganisation manuelle des contenus ;
- couverture large : utilisateurs, produits, commandes, événements, blocs d'accueil, partenaires, pages légales et paramètres de société.

Améliorations nécessaires pour SEOS :

- toutes les routes sous de vrais namespaces `Admin::` et `SuperAdmin::` ;
- permissions granulaires, pas un seul booléen administrateur ;
- informations personnelles masquées par défaut ;
- motif, réauthentification et audit pour chaque révélation sensible ;
- opérations financières, événements de confiance et logs strictement non éditables ;
- actions métier explicites à la place d'un CRUD générique ;
- couverture de tests d'autorisation et de non-régression pour chaque rôle.

## Rôles et permissions

Les rôles produit restent `member`, `admin` et `super_admin`. À l'intérieur du rôle admin, des permissions permettent de limiter les responsabilités sans créer immédiatement de nouveaux rôles publics.

Association et Partenaire sont des contextes d'organisation obtenus par membership et statut vérifié, pas des valeurs supplémentaires de `users.role`. Ils possèdent leur propre espace et restent entièrement séparés du back-office.

Permissions proposées :

- `users.read`, `users.moderate`, `users.sensitive_data_reveal` ;
- `listings.manage`, `exchanges.read`, `messages.reveal` ;
- `categories.restrict`, `seo.read`, `seo.manage` ;
- `reports.manage`, `organizations.verify` ;
- `points.audit`, `points.adjust`, `points.reverse` ;
- `trust.review`, `trust.appeals`, `trust.algorithm_simulate` ;
- `engagement.manage`, `chains.manage` ;
- `content.manage`, `legal.manage` ;
- `studio.read`, `studio.content.manage`, `studio.theme.manage`, `studio.preview` ;
- `privacy.manage`, `exports.sensitive` ;
- `settings.manage`, `audit.read`.

Le super-admin possède les permissions nécessaires mais conserve des actions exclusives : créer/révoquer un administrateur, modifier ses permissions, activer une version de calcul du Trust Score, publier les versions de valorisation PS/bonus/niveaux/chaînes, publier/réinitialiser un thème, exécuter un reset Studio global, activer/désactiver la carte publique ou le soutien Stripe dormant, gérer les secrets par la configuration de déploiement, publier une politique de conservation juridiquement validée et déclencher certains exports globaux.

### Matrice de principe

| Action | Admin habilité | Super-admin | Garde-fou |
|---|:---:|:---:|---|
| Lire les listes métier | Oui | Oui | Permission de section |
| Modifier un contenu éditorial | Oui | Oui | Historique des versions |
| Suspendre/restaurer un compte | Oui | Oui | Motif, durée, notification, audit |
| Révéler e-mail/téléphone/adresse | Selon permission | Oui | Masqué, motif, réauthentification, audit |
| Lire une conversation | Selon permission | Oui | Incident ciblé, motif, journal d'accès |
| Ajuster des points | Selon permission | Oui | Opération compensatrice, double confirmation |
| Modifier une écriture de points validée | Jamais | Jamais | Append-only |
| Modifier un événement Trust validé | Jamais | Jamais | Invalidation motivée + nouvel événement |
| Activer un nouvel algorithme Trust | Non | Oui | Simulation, approbation, snapshot, retour possible |
| Prévisualiser les contenus et thèmes | Selon permission | Oui | Aucun impact public avant publication |
| Publier/réinitialiser le thème ou le site | Non | Oui | Version, validation, réauthentification, snapshot et audit |
| Activer/désactiver la carte publique | Non, lecture seule | Oui | Flag versionné, confirmation, audit et test d'absence réseau |
| Gérer la blacklist de catégories | Selon permission | Oui | Motif, période, impact existant, preview et audit |
| Publier barème PS/bonus/chaîne | Non | Oui | Simulation, date d'effet, non-rétroactivité et rollback |
| Publier politique de conservation | Non | Oui | Aucune durée globale à vie, revue juridique/DPO et simulation |
| Piloter SEO/GEO/Schema.org | Selon permission en brouillon | Oui | Schémas allowlistés, diff, validation et audit |
| Activer le soutien Stripe | Non | Oui | Flag off par défaut, cadre juridique/comptable et double validation |
| Gérer les administrateurs | Non | Oui | Réauthentification forte et audit |
| Supprimer un journal d'audit | Jamais | Jamais depuis l'UI | Conservation contrôlée hors CRUD |

## Navigation principale

### 1. Vue d'ensemble

- indicateurs : inscriptions, membres actifs, annonces, demandes, échanges terminés, taux de litige ;
- santé des Points Services : émission, circulation, corrections, soldes atypiques ;
- Trust Score : couverture, profils avec données insuffisantes, recours, alertes à revoir ;
- files de travail : signalements arrivant à échéance, demandes RGPD, organisations en attente ;
- état opérationnel : jobs en erreur, e-mails échoués, stockage, dernière sauvegarde vérifiée ;
- journal des actions récentes de l'administrateur.

Les cartes montrent le nombre exact et une évolution. Les tendances utilisent une courbe simple ; les comparaisons d'objectifs utilisent des barres, jamais une collection de jauges décoratives.

### 2. Communauté

- utilisateurs, profils privés et profils de service publics ;
- statuts, rôles, permissions et sessions ;
- méthodes vérifiées : e-mail/téléphone, sans prétendre à une identité légale ;
- parrains multiples, codes à usage unique, positions 1–10, parrain principal, objections, qualification et éventuelle récompense ;
- favoris, notifications et préférences ;
- fermeture, restriction, anonymisation et historique.

### 3. Annonces et catalogue

- annonces, brouillons, médias, catégories et sous-catégories ;
- intentions, modes d'échange, urgences, zones et disponibilité à distance ;
- demandes Top annonce, périodes de mise en avant et historique ;
- commentaires, favoris et contenus signalés ;
- recherche des besoins les plus fréquents pour la future zone « demandes les plus recherchées ».
- blacklist des catégories/termes, dates, motifs, annonces impactées et décision de revue/pause ;
- indexabilité SEO de chaque annonce, canonical, sitemap, JSON-LD et éventuelles erreurs de contenu privé.

### 4. Échanges et conversations

- demandes envoyées/reçues et chaque transition de statut ;
- modalités, montants proposés/acceptés, confirmations et contestations ;
- conversations et pièces jointes, masquées jusqu'à une révélation autorisée ;
- avis structurés, délai double aveugle, réponses et modération ;
- chronologie unifiée d'un échange.

### 5. Points Services

- comptes et soldes ;
- opérations, écritures, sources, clés d'idempotence et corrections ;
- récompense de quête d'accueil, autres quêtes, chaînes et ajustements ;
- vues de rapprochement : somme des écritures, compte système, écarts impossibles ;
- export ciblé et opération compensatrice.
- versions de valorisation indicative euros → PS et tranches ;
- simulation avant publication, date d'effet, règles historiques et rollback ;
- aucun contrôle permettant de vendre, acheter, retirer ou convertir des PS.

Le formulaire d'ajustement demande cible, montant, sens, catégorie de motif, justification et ticket éventuel. Il affiche l'impact avant confirmation et ne modifie jamais le passé.

### 6. Confiance et sécurité

- profils Trust globaux et par catégorie ;
- dimensions, niveau de confiance statistique, nombre d'éléments et date de calcul ;
- événements ayant contribué au résultat et facteurs de plafonnement ;
- avis structurés, recommandations et parrainages ;
- comparaison du poids des parrainages avec celui des échanges et invalidations motivées ;
- signaux d'anomalie internes, regroupements suspects et revue humaine ;
- contestations, explications communiquées et décisions ;
- versions d'algorithme : brouillon, simulation, approbation, activation, retrait ;
- comparaison d'une version candidate avec la version active par cohortes.

### 7. Modération

- signalements avec priorité, échéance, attribution et statut ;
- cibles : profil, annonce, commentaire, avis, message, organisation, mission ou chaîne ;
- preuves, décisions, avertissements, suspensions et restaurations ;
- historique des actions et notification au membre ;
- listes de termes/comportements à revoir, sans publication automatisée d'une accusation.

### 8. Engagement

- quêtes/succès, critères, récurrence, preuves et ordre ;
- barèmes Bronze/Argent/Gold et versions ;
- progressions, soumissions, revues et récompenses ;
- témoignages écrits/vidéo et partage mensuel ;
- règles de parrainage, anti-double récompense et éligibilité Top annonce ;
- un seul parrain principal récompensable par inscription, même lorsque dix soutiens alimentent le score initial.
- versions du cycle « après N échanges », montants Bronze/Argent/Gold et plafonds par période.

### 9. Chaînes d'entraide

- chaînes, maillons, invitations, expirations et confirmations ;
- bénéficiaires inscrits/non inscrits et preuve d'information ;
- longueur `unlimited` par défaut ou `limited`, limite éventuelle, profondeur de récompense, gain par validation/maillon et plafonds ;
- simulation de l'émission minimale/maximale avant activation d'une version ;
- contestations, interruptions et reprise ;
- vue graphe comme aide visuelle, doublée d'une table accessible.

### 10. Organisations et missions

- organisations, responsables, adhésions et justificatifs ;
- associations, partenaires, types de coopération, pages publiques et ordre d'affichage ;
- vérification, refus, suspension et expiration éventuelle ;
- missions solidaires, médias, contribution, capacité et candidatures ;
- contrôle du plafond de 15 € par jour ;
- activation globale de la rubrique Voyage solidaire.

### 11. Contenus et apparence

- registre de toutes les pages éditables et état de leur version publiée ;
- blocs d'accueil, titres, descriptions, CTA, ordre des sections, catégories mises en avant et bannière ;
- articles du journal de bord, brouillons, aperçu, publication et archivage ;
- pages légales versionnées, footer, coordonnées de l'éditeur et SEO ;
- médiathèque, images, crédits, licences, points focaux et textes alternatifs ;
- thèmes UI versionnés, tokens de couleurs/typographie/espacement/formes/composants/mouvement et comparaison au défaut ;
- séparateurs organiques par frontière de section, presets statiques ou animés et fallback reduced motion ;
- prévisualisation desktop/tablette/mobile, validation puis publication ;
- reset d'un champ, bloc, média, séparateur, page, thème ou du site entier ; rollback vers une version antérieure.
- preview Search/social, titres et descriptions SEO ; les données Schema.org restent générées depuis les objets métier.

`SEOS Default v1` reste une référence système immuable. Le super-admin modifie une variante au travers de valeurs et presets allowlistés ; les composants, SVG, keyframes, templates et bornes restent versionnés dans le code. Aucun CSS, JavaScript, HTML ou SVG arbitraire n'est accepté. Un reset produit une nouvelle version et conserve l'historique au lieu d'écraser les données.

Le détail complet du Studio figure dans [`12-studio-ui-contenus-carte-et-separateurs.md`](./12-studio-ui-contenus-carte-et-separateurs.md).

### 12. Vie privée et conformité

- demandes d'accès, export, rectification, effacement, limitation et opposition ;
- consentements cookies/newsletter et versions des textes acceptés ;
- durées de conservation, traitements de purge et exceptions de litige ;
- prestataires, finalités et transferts éventuels ;
- accès aux données sensibles et exports réalisés ;
- incidents, chronologie et décisions de notification ;
- documentation de l'analyse d'impact du Trust Score.
- versions de politique de conservation par finalité, rapports de purge et exceptions légales ; aucune option globale « à vie » ;
- demandes Contact visiteurs, contenu chiffré, attribution, résolution et date de purge.

### 13. Plateforme

- paramètres non secrets et feature flags ;
- flag système `public_map_enabled`, activé par défaut et modifiable uniquement par le super-admin ;
- diagnostic garantissant qu'aucun script, tuile, cookie ou appel du fournisseur cartographique n'est chargé lorsque la carte est coupée ;
- files de jobs, échecs, relances idempotentes et e-mails ;
- versions applicatives, migrations et état du stockage ;
- journaux d'audit, sans donner accès aux secrets ou logs bruts contenant des données ;
- santé, capacité et suivi des sauvegardes/restaurations.
- intégrations : Gmail API, Devise/Google OmniAuth, Geocoder/Leaflet, vidéo Active Storage et analytics internes ;
- SEO/GEO : Search Console, sitemaps, canonical, robots, crawlers, données structurées et redirections ;
- soutien Stripe dormant, webhooks et rapprochement visibles uniquement lorsque le module est installé, sans lien avec le registre PS.

## Modèle d'écran commun

Chaque index admin utilise la même structure :

1. titre, description et action principale ;
2. indicateurs compacts utiles à la liste ;
3. recherche, filtres, période et vues enregistrées ;
4. tableau paginé, tri serveur et sélection multiple si sûre ;
5. panneau de détail ou page dédiée avec chronologie ;
6. actions autorisées seulement, avec raison et impact ;
7. export limité aux colonnes affichées et autorisées.

Fonctions transverses :

- recherche globale par identifiant interne, slug, titre ou e-mail haché/index de recherche sécurisé ;
- filtres partageables par URL, compteur de résultats et remise à zéro ;
- colonnes configurables sans exposer de donnée interdite ;
- vues enregistrées personnelles ;
- actions de masse seulement pour les opérations homogènes et réversibles ;
- sélection persistante clairement indiquée entre les pages ;
- pagination serveur et limite d'export ;
- état vide, chargement, erreur, succès et reprise.

## Fiche utilisateur à 360 degrés

La fiche la plus riche du back-office contient des onglets :

- résumé et chronologie ;
- profil public avec aperçu visiteur ;
- données privées masquées ;
- annonces, favoris et commentaires ;
- demandes, échanges, avis et messages protégés ;
- Points Services et opérations ;
- Trust Score global/par catégorie, preuves et recours ;
- parrainages, quêtes, chaînes et organisations ;
- signalements et décisions de modération ;
- consentements, demandes RGPD et accès sensibles ;
- audit des modifications.

Les actions persistantes « suspendre », « anonymiser », « ajuster des points » ou « révéler des données » ne doivent pas être regroupées dans un menu ambigu. Chacune ouvre un parcours décrivant précisément les conséquences.

## Matrice CRUD et exceptions

| Ressource | Créer | Lire | Modifier | Supprimer | Traitement correct |
|---|:---:|:---:|:---:|:---:|---|
| Catégorie/contenu/page légale | Oui | Oui | Oui | Si inutilisé | Archiver/versionner si référencé |
| Utilisateur | Invitation éventuelle | Oui | Champs limités | Non direct | Suspendre, fermer ou anonymiser |
| Profil public | Pour assistance | Oui | Oui avec motif | Non direct | Restreindre/anonymiser |
| Annonce/mission | Oui si besoin | Oui | Oui avec historique | Logique | Masquer, restaurer, clôturer |
| Demande de service | Non à la place du membre | Oui | Transition exceptionnelle | Non | Décision de médiation auditée |
| Message | Non | Sous motif | Jamais le contenu | Non | Masquer/restaurer après modération |
| Avis structuré | Non | Oui | Jamais les réponses | Non | Publier, masquer, invalider du calcul |
| Écriture de points | Non manuellement | Oui | Jamais | Jamais | Opération source/compensatrice |
| Trust Event/snapshot | Via moteur | Oui | Jamais | Jamais | Invalidation et recalcul |
| Version d'algorithme | Super-admin | Oui | Brouillon seulement | Brouillon inutilisé | Simuler, approuver, activer, retirer |
| Thème UI | Super-admin par clonage | Oui | Brouillon seulement | Archiver | Valider, publier, rollbacker ou reset vers le défaut |
| Version de page/bloc/média/séparateur | Selon permission | Oui | Brouillon seulement | Archiver si référencé | Preview, valider, publier, reset versionné |
| Feature flag système | Non librement | Oui | Super-admin | Jamais depuis l'UI | Changer une valeur autorisée, auditer, restaurer le défaut |
| Signalement | Éventuellement pour assistance | Oui | Statut/attribution | Non | Résoudre et conserver l'historique |
| Audit/accès sensible | Automatique | Oui selon droit | Jamais | Jamais via UI | Politique de conservation dédiée |
| Paramètre du site | Oui | Oui | Oui | Si sans historique | Versionner les valeurs critiques |
| Restriction de catégorie | Selon permission | Oui | Brouillon/active par action | Archiver | Simuler l'impact, publier, lever et auditer |
| Version de valorisation/bonus/chaîne | Super-admin | Oui | Brouillon seulement | Brouillon inutilisé | Simuler, publier, remplacer, rollbacker |
| Configuration SEO/GEO | Super-admin | Oui | Brouillon seulement | Archiver | Valider Schema.org/robots/canonical puis publier |
| Politique de conservation | Super-admin | Oui | Brouillon seulement | Jamais si appliquée | Revue légale, simulation, publication et remplacement |
| Contribution financière | Via Stripe si flag actif | Selon droit | Jamais le montant validé | Jamais | Remboursement/provider event compensateur |

## Protection des données dans le back-office

Le rôle administrateur ne rend pas toutes les données automatiquement nécessaires.

- Listes : e-mail partiellement masqué, téléphone masqué, aucun extrait de message.
- Recherche : pas d'autocomplétion publique sur téléphone/adresse ; accès ciblé et limité.
- Révélation : sélectionner la finalité, saisir un motif, réauthentifier si la session est ancienne, ouvrir pendant une courte fenêtre, journaliser.
- Conversation : accès seulement depuis un signalement, litige ou demande de droits ; bannière persistante indiquant la consultation sensible.
- Export : colonnes minimales, justification, fichier chiffré/temporaire, expiration et journalisation ; aucun export « toute la base » courant.
- Audit : conserver qui a consulté quoi, sans dupliquer la valeur sensible dans le log.
- Support : l'administrateur peut envoyer un lien d'action au membre plutôt que changer son mot de passe ou usurper sa session.

## Garde-fous d'action

- Confirmation simple pour une action réversible sans impact important.
- Confirmation renforcée avec résumé d'impact et saisie d'un motif pour suspension, masquage massif, ajustement ou révélation.
- Réauthentification pour permissions, données sensibles, export, points et algorithme.
- Double validation recommandée pour gros ajustement de points, export global et activation d'algorithme.
- Aucun bouton actif pendant l'envoi ; clé d'idempotence côté serveur.
- Notification du membre sauf nécessité documentée de préserver une enquête.
- Possibilité de lever une mesure sans effacer la mesure initiale.

## UI/UX exacte pour l'administration

Le panneau reprend le kit SEOS, avec une densité supérieure aux pages publiques :

- sidebar `deep #004961`, fond de travail `mist #EEF7F9`, cartes blanches, CTA or ;
- DM Sans pour toute l'interface et les nombres tabulaires ; Playfair seulement pour les grands titres de section ;
- densité cible élevée (`8/10`), variance visuelle faible (`3/10`) et mouvement discret (`2/10`) ;
- lignes de table compactes mais cibles interactives d'au moins `44 × 44px` ;
- sidebar repliable, sections accordéon et libellés toujours disponibles ;
- badges avec texte/icône, jamais la couleur seule ;
- tables adaptatives : colonnes prioritaires, scroll annoncé ou cartes structurées sur petit écran ;
- actions de masse visibles après sélection, jamais cachées dans un menu sans contexte ;
- messages d'erreur proches de l'action, chargement visible et confirmation persistante ;
- accès clavier complet, focus visible, lien d'évitement, titres et labels explicites.

## Critères d'acceptation

- Une URL admin ne répond jamais à un membre non habilité, y compris par requête directe.
- Chaque permission possède au moins un test positif et un test négatif.
- Un admin sans permission sensible ne reçoit jamais la donnée dans le HTML, le JSON ou l'export.
- Chaque révélation de donnée produit un journal consultable par le super-admin.
- Toute mutation sensible montre l'ancienne valeur, la nouvelle, l'acteur, la date et le motif.
- Une écriture de points, un Trust Event validé et un audit ne disposent d'aucune route update/destroy.
- Une action répétée par double clic ne s'exécute qu'une fois.
- Les recherches, filtres, tris et pages restent dans l'URL et fonctionnent au clavier.
- Le panneau fonctionne à `320`, `375`, `768`, `1024`, `1280` et `1440px`, ainsi qu'à zoom `200%`.
- Toute fonction créée dans l'application reçoit sa vue de consultation/modération admin avant d'être considérée livrée.
- Chaque capacité possède ses specs RSpec modèle/service/policy/requête et système applicables, avec cas positifs et négatifs pour chaque audience.
- Le thème par défaut passe la comparaison visuelle aux largeurs `320`, `375`, `414`, `768`, `1024`, `1280` et `1440px`.
- Un reset Studio restaure exactement la référence ciblée, crée une version/audit et ne supprime aucun historique.
- Carte coupée : aucun élément cartographique ni requête fournisseur ; carte réactivée : état public restauré sans redéploiement.
- Chaque annonce affiche son statut d'indexabilité et son graphe Schema.org validé, sans donnée privée.
- Aucune version de barème/chaîne/conservation publiée ne se modifie en place ; simulation et rollback sont testés.
- Le bouton de soutien et les routes publiques Stripe sont absents tant que le flag est désactivé.

## Ordre de livraison du panneau

1. socle : authentification admin, permissions, layout, navigation, recherche et audit ;
2. membres, profils, annonces, demandes et signalements ;
3. points, échanges, avis, Trust Score, recours et données sensibles ;
4. catégories, Top annonces, quêtes, parrainage et chaînes ;
5. organisations, missions, contenus, pages légales et médiathèque ;
6. Studio UI/UX, séparateurs organiques, resets et feature flag carte ;
7. demandes RGPD, conservation, incidents et outils d'exploitation ;
8. tableaux de bord avancés et comparaison des versions du Trust Score.

Chaque lot enrichit le même panneau ; il ne crée pas un mini-admin séparé par domaine.
