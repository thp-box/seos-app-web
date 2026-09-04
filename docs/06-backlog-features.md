# Backlog fonctionnel et priorités

## Convention

- **P0** : indispensable à un lancement utile et sûr.
- **P1** : important après stabilisation du cœur.
- **P2** : différenciation avancée ou forte complexité.
- **P3** : optimisation ou extension ultérieure.

Une fonctionnalité n'est terminée que si son contrôle d'accès, ses validations, ses états vides/erreurs, ses specs RSpec, sa version mobile et son suivi d'audit sont couverts. La stratégie de non-régression complète est dans [`11-strategie-tests-rspec-et-regression.md`](./11-strategie-tests-rspec-et-regression.md).

Les priorités organisent la livraison, elles ne définissent pas ce qui sera oublié :

- les 28 user stories sont des obligations fonctionnelles ;
- toutes les fonctionnalités inventoriées dans la maquette appartiennent à la feuille de route ;
- tout retrait ultérieur exige une décision produit explicite et une mise à jour de la matrice de couverture.

## Lot 0 — Fondations

| Priorité | Feature | Résultat attendu |
|---|---|---|
| P0 | Build Rails 8/esbuild | `yarn build`, `bin/dev` et précompilation produisent ensemble le JavaScript et le CSS attendus |
| P0 | RSpec et CI | RSpec installé avant les générateurs, factories/support, tests parallélisables et pipeline de non-régression |
| P0 | Référence visuelle | Baselines de la maquette aux sept viewports, comparaison contrôlée et écarts intentionnels documentés |
| P0 | Design system par défaut | Tokens et composants `SEOS Default v1` conformes à la maquette et référence immuable de reset |
| P0 | Authentification Devise | Inscription, confirmation, connexion, déconnexion, oubli/réinitialisation, sessions |
| P0 | Protection inscription | Conditions, vérification e-mail, limitation de débit et anti-robot accessible |
| P1 | Connexion Google | Devise/OmniAuth, scopes minimaux et parcours de dissociation |
| P2 | Connexion Facebook dormante | Flag off jusqu'à validation de compatibilité/maintenance du provider |
| P0 | Autorisation | Rôles membre/admin/super-admin et permissions testées serveur |
| P0 | Profil privé/public | Profil de service visible aux visiteurs avec annonces/Trust Score, données privées séparées |
| P0 | E-mail transactionnel Gmail API | Client Ruby Google, Action Mailer, secrets hors base, retries et idempotence |
| P0 | Active Storage | Upload sécurisé, limites, variantes et purge contrôlée |
| P0 | Journal d'audit | Actions administratives et ajustements sensibles traçables |
| P0 | Socle du panneau admin | Namespace, layout, permissions, recherche, pagination et masquage des données |
| P0 | Pages légales de base | CGU, confidentialité, mentions et choix cookies finalisés |
| P0 | France/français | Pays `FR`, locale `fr-FR`, contenus et formats français au lancement |

## Lot 1 — Découverte et annonces

| Priorité | Feature | Détails |
|---|---|---|
| P0 | Accueil public | Promesse, trois modes, catégories, annonces, confiance et CTA |
| P1 | Vidéo de présentation | Lecteur accessible, consentement si tiers et alternative textuelle |
| P0 | Pages Don/Échange/Points | Explication claire des règles et limites |
| P0 | Catégories hiérarchiques | Catégories et sous-catégories administrables |
| P0 | Blacklist catégories | Admin habilité/super-admin, termes/catégories, période, motif, sort des annonces existantes |
| P0 | Catalogue | Pagination, recherche texte, intention, mode, catégorie, zone, distance |
| P0 | Détail public | Contenu, médias, localisation approximative, réputation minimale |
| P0 | Profil public membre | Identité d'affichage, annonces, avis, Trust Score et aucune coordonnée |
| P0 | Publication en 4 étapes | Brouillon, validations par étape, aperçu et reprise |
| P0 | Gestion de ses annonces | Modifier, mettre en pause, réactiver, clôturer, supprimer logiquement |
| P0 | Confidentialité de localisation | Adresse exacte absente des réponses publiques |
| P0 | Vue carte | Geocoder + Leaflet, tuiles configurables, marqueurs approximatifs et alternative liste |
| P0 | Interrupteur carte | Super-admin uniquement ; désactivation sans contrôle, script, tuile, cookie ni requête fournisseur |
| P1 | Badge urgent | Critères, durée et modération définis |
| P1 | Top annonce | Demande d'éligibilité et validation humaine |
| P1 | Partage social | URLs partageables et copie du lien, sans traceur par défaut |
| P0 | Contact public | Le visiteur contacte seulement l'équipe SEOS ; anti-spam, notice et conservation limitée |
| P0 | SEO des annonces | URL canonique, rendu serveur, meta, sitemap et maillage pour chaque annonce indexable |
| P0 | Schema.org | JSON-LD généré : `Service`, `Demand`, `ItemList`, `ProfilePage`, organisations et articles ; `Offer` seulement avec une fonction non commerciale explicite validée |
| P0 | GEO | Contenu original structuré, entités stables, fraîcheur, crawlers gouvernés et mesure des citations/référents |

## Lot 2 — Mise en relation et échange

| Priorité | Feature | Détails |
|---|---|---|
| P0 | Demande de service | Créer et suivre une demande distincte d'un message |
| P0 | Boîte des demandes | Envoyées/reçues, filtres, statut et actions possibles |
| P0 | Messagerie interne | Conversation limitée aux participants, pièces jointes contrôlées |
| P0 | Notifications | Centre, compteur non lu, marquer lu, préférences e-mail |
| P0 | Accord sur les modalités | Date, lieu, mode et montant final historisés |
| P0 | Cycle de réalisation | Accepter, refuser, planifier, réaliser, confirmer, annuler, contester |
| P0 | Révélation contrôlée | Coordonnée ou adresse exacte seulement après condition et accord définis |
| P0 | Signalement | Motif, preuve, délai, traitement et résultat |
| P1 | Commentaires d'annonce | Fil public distinct de la messagerie et des avis |
| P1 | Favoris | Ajout/retrait idempotent et espace dédié |
| P0 | Avis structurés vérifiés | Après échange, critères par rôle/tâche, double aveugle, modération et recours |

## Lot 3 — Trust Score et sécurité relationnelle

| Priorité | Feature | Détails |
|---|---|---|
| P0 | Événements de confiance | Sources immuables, idempotentes, invalidables avec motif |
| P0 | Score par dimension | Fiabilité, qualité, respect/sécurité, communication, ponctualité |
| P0 | Score par catégorie | Confiance liée à la tâche sans généralisation abusive |
| P0 | Score global prudent | Formule versionnée, bornée et influence d'une catégorie plafonnée |
| P0 | Incertitude visible | Pas de note sous le seuil ; données limitées/modérées/solides |
| P0 | Explication membre/public | Facteurs, nombre de preuves, date, méthode et version |
| P0 | Contestation | Dossier, revue humaine, décision motivée et recalcul |
| P0 | Administration Trust | Profil 360°, événements, snapshots, avis et recours |
| P0 | Anti-manipulation initial | Paires plafonnées, diversité, rythme, avis réciproques et idempotence |
| P0 | AIPD et gouvernance | Profilage, base légale, minimisation, recours et revue humaine |
| P0 | Parrainage multi-code initial | Jusqu'à 10 parrains distincts, score provisoire 53–69, aucun point ni déblocage pour le nouveau membre |
| P1 | Recommandation par compétence | Contexte, consentement public, expiration et influence maximale de 5 % |
| P1 | Revue de risque interne | Signaux limités, faux positifs, décision humaine, aucune accusation publique |
| P1 | Cycle d'algorithme | Simulation, comparaison par cohortes, mode ombre, activation et retour |

La formule, les seuils et les tests d'attaque sont spécifiés dans [`08-systeme-trust-score.md`](./08-systeme-trust-score.md).

## Lot 4 — Points Services

| Priorité | Feature | Détails |
|---|---|---|
| P0 | Compte de points | Solde cohérent et visible |
| P0 | Registre append-only | Débits, crédits, source, acteur, date, solde après opération |
| P0 | Transfert après échange | Solde suffisant, confirmations et idempotence |
| P0 | Historique membre | Libellé compréhensible, filtres et lien vers la source |
| P0 | Audit admin | Recherche par membre, source, période, type et identifiant |
| P0 | Annulation compensatrice | Pas d'édition d'une écriture validée |
| P0 | Valorisation configurable | Tranches euros → PS indicatives, versions super-admin, simulation et non-rétroactivité |
| P0 | Quête d'accueil | Promesse maquette de 30 PS, attribuée une seule fois par une quête/action d'onboarding versionnée, jamais par achat |
| P1 | Ajustement admin | Motif obligatoire, permission dédiée et audit |
| P1 | Export | Historique portable pour le membre et l'audit |
| P2 | Garantie/médiation | Seulement après validation juridique et budgétaire |
| P0 | Bonus/niveaux configurables | N échanges, Bronze/Argent/Gold, plafonds et dates d'effet versionnés par le super-admin |

## Lot 5 — Modération et administration

| Priorité | Feature | Détails |
|---|---|---|
| P0 | Gestion des annonces | Filtrer, masquer, restaurer, clôturer et consulter l'historique |
| P0 | Gestion des utilisateurs | Rechercher, vérifier, suspendre, réactiver, anonymiser |
| P0 | Fiche utilisateur 360° | Profil public/privé, annonces, échanges, points, Trust, droits et audit |
| P0 | Gestion des échanges | Chronologie, modalités, confirmations, litiges et actions exceptionnelles |
| P0 | File de signalements | SLA, attribution, preuve, action et notification |
| P0 | Audit des points | Consultation seule plus opérations compensatrices dédiées |
| P0 | Administration du Trust | Scores par tâche, preuves, anomalies, contestations et snapshots |
| P0 | Tableau d'audit | Journal des actions sensibles |
| P0 | Gestion des rôles | Super-admin seul pour créer/promouvoir/rétrograder un admin |
| P0 | Données sensibles | Masquage, motif, réauthentification, révélation temporaire et audit |
| P0 | Recherche et listes | Filtres URL, pagination, tris, vues enregistrées et exports minimisés |
| P1 | Vérification de profil | E-mail et téléphone facultatif avec badges précis ; aucune pièce d'identité en V1 |
| P1 | Paramètres globaux | Rubriques, pays, limites, sans secrets |
| P1 | Modération commentaires/avis | Historique et motif de décision |
| P1 | Exports admin | Données minimisées et accès journalisé |
| P1 | CMS global | Accueil, témoignages, pages légales, articles, footer et SEO |
| P0 | Studio de contenus | Chaque page déclarée : textes, descriptions, CTA, images, alt, SEO, ordre, preview, version et reset |
| P0 | Studio UI/UX | Super-admin : tokens/presets sûrs, thème versionné, publication, rollback et reset vers `SEOS Default v1` |
| P1 | Séparateurs organiques | Plusieurs formes par page, statiques/animées, bornées, accessibles et réinitialisables |
| P0 | Contrôle carte | État en lecture admin ; activation, désactivation et reset réservés au super-admin, avec audit |
| P0 | Pilotage SEO/GEO | Indexabilité, Schema.org, sitemaps, canonical, robots/crawlers et diagnostics |
| P0 | Pilotage des barèmes | Valorisation PS, bonus, niveaux et règles de chaîne simulés/versionnés |
| P0 | Blacklist | Catégories/termes interdits, annonces affectées, historique et permissions |
| P1 | Exploitation | Jobs, e-mails, stockage, sauvegardes, santé et incidents |

Le panneau couvre ensuite chaque ressource ajoutée aux lots suivants. Voir la matrice CRUD complète dans [`07-panel-administration.md`](./07-panel-administration.md).

## Lot 6 — Quêtes, succès et engagement

| Priorité | Feature | Détails |
|---|---|---|
| P1 | Catalogue de quêtes | CRUD admin, activation, ordre et règles |
| P1 | Progression membre | En cours, à valider, terminée et récompensée |
| P1 | Récompenses par niveau | Bronze/Argent/Gold, barème versionné |
| P1 | Preuves | Capture, texte ou vidéo selon la quête |
| P1 | Revue humaine | Témoignages et partages avant récompense |
| P1 | Partage mensuel | Une seule récompense par période |
| P1 | Quête de parrainage | `15 PS` une fois au parrain principal après 30 jours + 2 échanges indépendants du filleul ; autres codes = Trust seulement |
| P1 | Séries d'échanges | Comptage sur échanges validés, sans double comptage |
| P2 | Calcul des niveaux | Critères transparents, contestables et recalculables |
| P2 | Éligibilité Top annonce | Niveau ou action validée, puis approbation admin |
| P2 | Soutenir SEOS | Parcours séparé de l'échange, prestataire et cadre financier/juridique à choisir |

## Lot 7 — Chaînes d'entraide

| Priorité | Feature | Détails |
|---|---|---|
| P2 | Démarrer une chaîne | Description du service et bénéficiaire |
| P2 | Invitation sécurisée | Jeton à usage unique, expiration et information RGPD |
| P2 | Inscription/connexion bénéficiaire | Retour au parcours de validation après authentification |
| P2 | Validation du service | Confirmation unique, contestation possible |
| P2 | Visualisation | Maillons, services, participants et progression |
| P2 | Chaîne sans fin par défaut | Aucun nombre maximal de maillons tant que la règle active est `unlimited` |
| P2 | Règles de chaîne configurables | Mode illimité/limité, limite éventuelle, profondeur récompensée, gain et plafonds |
| P2 | Anti-fraude | Auto-validation, boucles, appareils, répétitions et collusion |
| P2 | Audit admin | Chaîne, invitations, validations et récompenses |

Ce lot doit être développé après le registre de points. Il combine identité d'un tiers, jetons publics, concurrence et émission contrôlée de Points Services par les règles de chaîne.

## Lot 8 — Associations et Voyage solidaire

| Priorité | Feature | Détails |
|---|---|---|
| P2 | Demande Association | Organisation, justificatifs et responsables |
| P2 | Vérification admin | Valider, refuser, suspendre et historiser |
| P2 | Membres d'organisation | Propriétaire, gestionnaire et éditeur |
| P2 | Missions solidaires | Formulaire complet, médias, dates, conditions |
| P2 | Plafond de contribution | 0 à 15 € par jour, contrôle serveur et base |
| P2 | Catalogue de missions | Pays, région, période, capacité et conditions |
| P2 | Gestion durable | Pas d'expiration automatique selon la maquette, mais statut explicite |
| P2 | Candidature | Parcours membre et conversation mission si retenus |
| P2 | Feature flag | Affichage de la rubrique dans la navigation |
| P1 | Annuaire Associations | Fiches publiques, missions actives et contact protégé |
| P1 | Pages Partenaires | Annuaire, fiche, type de partenariat et aucun accès implicite aux membres |
| P1 | Espace organisation | Membres owner/manager/editor, aperçu public et activité autorisée |
| P1 | Gestion admin partenaires | CRUD, ordre, dates, validation, archivage et audit |

## Lot 9 — Journal de bord et contenus

| Priorité | Feature | Détails |
|---|---|---|
| P2 | Articles | Brouillon, aperçu, publication, archivage |
| P2 | Éditeur riche | Action Text, images et textes alternatifs |
| P2 | Droits éditoriaux | Super-admin selon user story, délégation éventuelle à arbitrer |
| P2 | Pages publiques | Index, article, partage, SEO et métadonnées |
| P0 | Registre des pages | Schéma de champs et slots pour chaque page publique, compte, organisation, admin, erreur et e-mail |
| P0 | Versions et publication | Brouillon, preview, validation, publication atomique, archivage et rollback |
| P0 | Médiathèque | Réemploi, alt, crédit/licence, point focal, statut et purge seulement si non référencée |
| P0 | Resets granulaires | Champ, bloc, média, séparateur, page, thème et site, sans effacer l'historique |
| P1 | Décorations de section | Presets organiques statiques/animés, ordre, couleurs, variantes et reduced motion |
| P3 | Planification | Publication future via job |
| P3 | Catégories/tags | Seulement si le volume le justifie |
| P0 | SEO éditorial | Canonical, Schema.org Article, sitemap, métadonnées et preview Search/social |

## Lot 10 — Vie privée et conformité

| Priorité | Feature | Détails |
|---|---|---|
| P0 | Consentement cookies | Refuser aussi facilement qu'accepter, choix versionné et réversible |
| P0 | Minimisation | Pas d'adresse ou téléphone dans les pages publiques |
| P0 | Profil public maîtrisé | Accessible au visiteur, `noindex` initial recommandé, sans annuaire exportable |
| P0 | Profilage Trust | Information dédiée, base légale, AIPD, explication et recours humain |
| P0 | Durées de conservation | Matrice par finalité, aucune conservation globale à vie, versions validées juridiquement |
| P0 | Fermeture de compte | Suppression/anonymisation compatible avec audit et litiges |
| P1 | Export des données | Préparation asynchrone, lien temporaire et authentifié |
| P1 | Demandes de droits | Accès, rectification, effacement, limitation, opposition, retrait |
| P1 | Tableau de confidentialité | Coordonnées, consentements, visibilité, sessions et demandes dans l'espace membre |
| P1 | Preuve de consentement | Newsletter et traceurs versionnés |
| P1 | Registre des prestataires | Hébergement, e-mail, sociaux, cartographie, médias |
| P1 | Incident de sécurité | Procédure, journaux et notification selon obligation |

## Lot 11 — Soutien financier dormant

| Priorité | Feature | Détails |
|---|---|---|
| P2 | Stripe Checkout dormant | Intégration testée derrière `financial_support_enabled = false` |
| P2 | Don/contribution seulement | Aucun achat, produit, contrepartie, PS, niveau, Trust ou visibilité |
| P2 | Webhooks | Signature, idempotence, remboursement et rapprochement |
| P2 | Cadre préalable | Entité bénéficiaire, comptabilité, confidentialité et terminologie validées avant activation |
| P2 | Reçu fiscal | Aucune promesse ni émission sans habilitation juridique confirmée |

## Exigences non fonctionnelles

### Sécurité

- contrôle d'accès côté serveur pour chaque action ;
- protection CSRF, sessions sécurisées et rotation après connexion ;
- limitation de débit sur authentification, messages, invitations et signalements ;
- validation MIME/taille des uploads et analyse antivirus si nécessaire ;
- chiffrement des coordonnées sensibles ;
- URLs signées ou jetons condensés pour les actions publiques ;
- aucune donnée sensible dans logs, analytics ou métadonnées d'audit.

### Accessibilité

- objectif WCAG 2.2 niveau AA ;
- navigation clavier et focus visible ;
- structure de titres et landmarks ;
- cibles tactiles d'au moins `44 × 44px` ;
- erreurs reliées aux champs ;
- contraste contrôlé ;
- alternatives textuelles ;
- reduced motion ;
- tests lecteur d'écran sur les parcours critiques.

### Performance

- images responsives et formats modernes ;
- dimensions de médias réservées ;
- pagination serveur ;
- index sur les listes et filtres ;
- jobs pour e-mails, variantes et exports ;
- budget JavaScript limité, Stimulus seulement là où nécessaire ;
- objectif de stabilité visuelle CLS inférieur à `0.1`.

### Exploitation

- sauvegarde et restauration testées ;
- supervision des jobs et échecs d'e-mail ;
- health check existant `/up` ;
- journalisation structurée et `request_id` ;
- procédure de rollback des migrations ;
- seeds de démonstration séparés des données de production.

### Tests et non-régression

- RSpec est la suite canonique dès le socle ; les générateurs écrivent dans `spec/` ;
- chaque feature couvre modèle/service, policy, requête, job/mailer et système selon son risque ;
- chaque permission possède des exemples partagés visiteur, membre, association, partenaire, admin et super-admin ;
- les invariants Points, Trust, confidentialité, Studio, reset et feature flags possèdent des tests de concurrence/idempotence ;
- les parcours JavaScript reconstruisent d'abord les assets avec `yarn build` ;
- le thème par défaut subit une comparaison visuelle stable aux sept viewports ;
- objectifs : 100 % des user stories/features/policies/transitions tracées, au moins 95 % de lignes et 90 % de branches ;
- une baseline visuelle ne peut être changée que dans une revue explicitant l'écart produit.

## Découpage vertical conseillé

Chaque tranche doit livrer une valeur testable de bout en bout :

1. Un visiteur explore une annonce sans voir de donnée privée.
2. Un membre s'inscrit, complète son profil et publie un don.
3. Un second membre demande le service et échange dans la messagerie.
4. Les deux membres clôturent le don et publient un avis.
5. Le profil public reflète l'échange dans un Trust Score expliqué et contestable.
6. Le même parcours fonctionne en Points Services avec registre auditable.
7. Un admin traite un signalement et consulte la fiche 360° sans accès implicite aux données privées.
8. Les fonctions d'engagement, de chaîne et d'association sont ajoutées une par une avec leur administration.

## Critères de sortie MVP

- Les parcours P0 fonctionnent avec de vraies URLs et données persistées.
- Chaque rôle ne voit et ne peut exécuter que les actions autorisées.
- Don, échange libre et points possèdent chacun un scénario système complet.
- Les points résistent au double clic, à deux confirmations concurrentes et au solde insuffisant.
- L'adresse exacte et le téléphone ne fuient pas dans les pages, JSON, logs ou notifications.
- Le back-office permet de modérer sans modifier silencieusement l'historique.
- Le profil public reste visible aux visiteurs avec annonces et confiance, sans e-mail, téléphone ou adresse exacte.
- Le score par tâche, son incertitude, ses facteurs et son recours sont opérationnels ; aucun effet important n'est entièrement automatique.
- Les fonctions P0 disposent de leur vue de consultation ou de modération dans le panneau admin.
- Le Studio peut modifier puis réinitialiser thème, contenu, média et séparateur sans perdre la version précédente.
- La carte peut être coupée/réactivée sans déploiement ; coupée, elle ne provoque aucun chargement fournisseur.
- Mobile, clavier et contrastes sont validés.
- `yarn build` produit JS/CSS ; toute la suite `bundle exec rspec`, les contrôles visuels, RuboCop et Brakeman passent.
- Chaque annonce publique indexable possède canonical, sitemap et JSON-LD cohérent sans PII ; les pages filtrées ne créent pas de duplication.
- Un visiteur peut contacter l'équipe mais aucune route ne lui permet d'écrire à un annonceur.
- Aucune donnée personnelle n'utilise une durée globale `forever` ; les purges versionnées sont simulées et testées.
- Le parcours Stripe est absent tant que son flag vaut faux et n'a aucun effet sur les Points Services.
- Les textes juridiques ne contiennent plus de champ « à compléter ».
- Sauvegarde, restauration et traitement d'incident sont documentés.

## Traçabilité des user stories obligatoires

| User story | Lot principal | Preuve attendue |
|---|---:|---|
| US-01 Comprendre l'offre | 1 | Test visiteur de l'accueil |
| US-02 Pages publiques | 1 | Routes publiques et navigation |
| US-03 Catalogue d'annonces | 1 | Recherche, filtres, pagination |
| US-04 Détail d'annonce | 1 | Vue publique sans donnée privée |
| US-05 Coordonnées cachées | 0/2/10 | Tests HTML/JSON et partage contrôlé |
| US-06 Informations personnelles privées | 0/1/10 | Profil de service public distinct du profil privé |
| US-07 Inscription | 0 | Scénario système complet |
| US-08 Connexion/déconnexion | 0 | Sessions, récupération et révocation |
| US-09 Création d'annonce | 1 | Assistant quatre étapes et brouillon |
| US-10 Modification/suppression | 1 | Autorisation et suppression logique |
| US-11 Demande de service | 2 | Création et transitions serveur |
| US-12 Suivi des demandes | 2 | Boîtes envoyées/reçues et statuts |
| US-13 Notifications | 2 | Centre, non-lus et préférences |
| US-14 Transaction en points | 4 | Double confirmation et idempotence |
| US-15 Historique d'échange | 2/4 | Chronologie métier et registre |
| US-16 Mon profil | 0 | Édition privée + aperçu public |
| US-17 Admin annonces | 5 | CRUD limité, modération et audit |
| US-18 Admin utilisateurs | 5 | Fiche 360°, statut et droits |
| US-19 Audit transactions | 4/5 | Registre append-only et recherche |
| US-20 Permissions super-admin | 0/5 | Matrice et tests négatifs |
| US-21 Création d'administrateur | 5 | Réauthentification et audit |
| US-22 Succès en cours/réalisés | 6 | États et progression membre |
| US-23 Admin CRUD succès | 6 | Gestion, barèmes et versions |
| US-24 Articles par super-admin | 9 | Brouillon, publication, archivage |
| US-25 Commentaires d'annonce | 2/5 | Fil distinct et modération |
| US-26 Favoris | 1/2 | Action idempotente et espace dédié |
| US-27 Chaîne d'entraide | 7 | Invitation, validation, récompense, audit |
| US-28 Annonces monde/associations | 8 | Organisation vérifiée et mission modérée |

## Couverture des fonctions propres à la maquette

| Fonction de la maquette | Lot |
|---|---:|
| Hero, recherche immédiate et CTA d'inscription/publication | 1 |
| Présentation des modes Don, Échange et Points | 1 |
| Catégories illustrées et annonces d'exemple | 1/9 |
| Vidéo de présentation | 1/10 |
| Bloc Chaîne d'entraide de l'accueil | 7/9 |
| Témoignages publics écrits et vidéo | 6/9 |
| Bloc sécurité et réassurance | 0/3/9 |
| Présence francophone annoncée | 1/10, territoire à valider |
| Partage social et soutien à SEOS | 1/6/11, soutien dormant |
| Pages explicatives Don, Échange et Points | 1 |
| Barème indicatif des Points et accord final | 4, version super-admin |
| Quête d'accueil affichée « 30 PS » dans la maquette | 4, valeur versionnée |
| Bonus après cinq échanges | 4/6, fréquence et montant versionnés |
| Recherche texte, ville, catégorie et filtres rapides | 1 |
| Filtres intention, mode, rayon, urgence et distance | 1 |
| Tri pertinence, proximité, note et date | 1/3 |
| Vues liste/carte, marqueurs et état vide | 1 |
| Carte activable/désactivable par super-admin sans chargement tiers résiduel | 0/1/5 |
| Carte annonce : favori, badge, personne, zone et mode | 1/3 |
| Galerie, informations pratiques et partage du détail | 1 |
| Proposition, question préalable et estimation du solde | 2/4 |
| Téléphone masqué puis partage contrôlé | 2/10, règle renforcée par rapport à la maquette |
| Avis après échange et signalement sous objectif de délai | 2/3/5 |
| Assistant quatre étapes Offre/Demande et trois modes | 1 |
| Adresse préremplie privée et zone publique | 0/1/10 |
| Photos/vidéo, disponibilité, priorité et aperçu | 1 |
| Connexion/inscription e-mail et Google/Facebook | 0, Devise + Google ; Facebook dormant |
| Conditions, newsletter facultative et anti-robot | 0/10 |
| Dashboard Aperçu et activité récente | 0/2 |
| Mes annonces, modification, réactivation et Top annonce | 1/5/6 |
| Quêtes, progression, preuves et Bronze/Argent/Gold | 6 |
| Portefeuille, solde et historique | 4 |
| Mes chaînes, favoris, messagerie et avis | 2/7 |
| Profil, avatar, bio, adresse privée et visibilité | 0/10 |
| Export, rectification, effacement, limitation et opposition | 10 |
| Centre de préférences cookies | 10 |
| Création/validation de chaîne et authentification bénéficiaire | 7 |
| Chaîne illimitée et récompenses des maillons | 7, règle super-admin versionnée |
| Voyage solidaire, catalogue et formulaire Association | 8 |
| Contribution maximale 15 € par jour | 8 |
| Activation globale Voyage et octroi du statut Association | 5/8 |
| Demandes Top, organisations et signalements dans l'admin visible | 5 |
| Centre légal et notices contextuelles | 9/10 |
| Thème UI/UX administrable, versionné et reset exact vers la maquette | 0/5/9 |
| Textes, descriptions, images, CTA et SEO éditables/réinitialisables par page | 5/9 |
| Plusieurs séparateurs organiques par page, statiques ou animés | 5/9 |
| Tests RSpec exhaustifs et non-régression visuelle CSS/JS | Tous les lots |
| SEO alimenté par les annonces actives, sûres et suffisamment complètes, avec Schema.org | 1/5/9/10 |
| GEO, crawlers de recherche et contenu citable | 1/5/9/10 |

Cette double matrice est la checklist anti-oubli : toute recette fonctionnelle doit pouvoir remonter à une ligne de user story ou de maquette.
