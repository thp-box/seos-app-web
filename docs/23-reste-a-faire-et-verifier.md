# SEOS — Tout ce qu’il reste à faire et à vérifier

État consolidé au **6 septembre 2026**, après la phase 7. Ce document devient le point d’entrée du reste à faire ; les suivis précédents restent des photographies historiques.

**Le passage par les phases 0 à 7 ne signifie pas que toutes les exigences du plan initial sont terminées.** Des parcours sont codés et testés localement, des fonctions sont encore partielles et plusieurs validations de lancement restent à obtenir.

## 1. Comment utiliser cette checklist

Priorités proposées :

- **P0 — Avant ouverture publique** : sécurité, droits des personnes, règles critiques, exploitation et validation du périmètre publié.
- **P1 — Compléter le périmètre prévu** : fonction attendue dans la documentation initiale. Son report exige une décision de périmètre explicite ; « P1 » ne signifie pas « facultatif ».
- **P2 — Extension ou activation ultérieure** : ne bloque pas un lancement si la fonction concernée reste désactivée ou hors périmètre annoncé.

Nature du travail : **Code** = réalisation ou correction ; **Vérifier** = recette ou audit à effectuer ; **Décider** = arbitrage produit/juridique ; **Configurer** = environnement ou prestataire.

Toutes les cases ci-dessous sont volontairement ouvertes. Pour clôturer une ligne, ajouter la date, le responsable, le commit/configuration concerné et une preuve : test, capture, rapport ou validation. Les responsables indiqués sont des rôles à attribuer, pas des personnes déjà engagées.

### Ce qui a été examiné pour cette consolidation

- Plan [F-001 à F-073](10-plan-construction-feature-par-feature.md), suivis des phases [0](14-analyse-et-suivi-phase-0.md), [1–2](15-suivi-phases-1-et-2.md), [3](17-suivi-phase-3.md), [4](18-suivi-phase-4.md), [5](19-suivi-phase-5.md), [6](20-suivi-phase-6.md) et [7](21-suivi-phase-7.md).
- Références [Studio](12-studio-ui-contenus-carte-et-separateurs.md), [administration](07-panel-administration.md), [SEO](13-strategie-seo-schema-org-et-geo.md), [tests](11-strategie-tests-rspec-et-regression.md) et [exploitation](22-exploitation-et-recette.md).
- Lecture ciblée du code : inscription, demandes de droits, conservation, Studio, pilotage admin, Gmail, récompenses et configuration Kamal.

Cette consolidation est une **revue documentaire et ciblée du code**, pas un nouvel audit exhaustif ni une nouvelle exécution des tests. Les **283 tests réussis**, les **13 contrôles ciblés** après correctifs, les audits et la restauration sont les résultats consignés dans le suivi de phase 7. Ils ne prouvent pas une configuration de production fonctionnelle.

## 2. Priorités immédiates

| Case / ID | Priorité et nature | À terminer | Responsable | Preuve de clôture |
|---|---|---|---|---|
| [ ] L01 | P0 · Décider + Code | Textes légaux définitifs, politique d’âge et acceptation des CGU versionnées à l’inscription. Aucun enregistrement d’acceptation versionnée n’a été identifié dans le parcours actuel. | Produit + juridique/DPO + développement | Versions approuvées, acceptation enregistrée côté serveur, refus/absence de case testés, procédure de changement de CGU. |
| [ ] L02 | P0 · Décider + Code | Conservation complète par finalité, y compris preuves, conversations, snapshots, audits, demandes de droits, médias et sauvegardes. La purge actuelle ne couvre que six finalités opérationnelles. | DPO + développement + exploitation | Matrice complète des durées actives/archives, exceptions justifiées, traitements implémentés, simulation et purge contrôlée démontrées. |
| [ ] L03 | P0 · Vérifier + Code | Fermer les cas incomplets de traitement des droits : rectification réelle, opposition/limitation proportionnées, export complet après revue des droits de tiers, effacement et suivi prestataires. | DPO + support + développement | Recette de chaque droit avec données réalistes, réponse exacte et preuve d’exécution. |
| [ ] L04 | P0 · Configurer + Vérifier | Google/Gmail sur de vrais comptes autorisés, délivrabilité et reprise après incident. | Exploitation + développement | Recette en préproduction, aucun secret dans les logs, envois réconciliés et procédure de résolution exploitable. |
| [ ] L05 | P0 · Configurer | Déploiement réel : serveurs, domaine, TLS, registre, volumes, secrets et workers. `config/deploy.yml` contient encore des valeurs d’exemple, notamment `192.168.0.1`. | Exploitation | Configuration relue, déploiement préproduction reproductible et contrôles de santé. |
| [ ] L06 | P0 · Configurer + Vérifier | Sauvegarde chiffrée hors serveur, restauration avec les clés, reprise des effacements et rollback. | Exploitation + DPO | Exercice sur l’infrastructure cible, RPO/RTO mesurés, accès et expirations contrôlés. |
| [ ] L07 | P0 · Décider + Vérifier | AIPD/revue des effets du Trust, règles sensibles et périmètre des publics autorisés. | Produit + juridique/DPO | Décision documentée sur les traitements réellement activés et les protections associées. |
| [ ] L08 | P0 · Vérifier | Recette des rôles, confidentialité, accessibilité manuelle et performance à volume réaliste. | QA + développement | Rapport des scénarios, anomalies corrigées ou fonctionnalités exclues explicitement du lancement. |

## 3. Confidentialité, droits et conservation — F-003 / F-070

Sources techniques principales : [Privacy](../app/services/privacy.rb), [Retention](../app/services/retention.rb), [RetentionPolicyVersion](../app/models/retention_policy_version.rb), [inscription](../app/views/devise/registrations/new.html.erb).

- [ ] **R01 — P0 · Décider + Code : étendre la couverture de conservation.** Les finalités configurables actuelles sont `exports`, `sessions`, `notifications`, `contacts`, `invitations`, `cookie_preferences`. Inventorier les autres tables, pièces jointes, journaux et traitements ; distinguer durée active, archive, point de départ, exception et méthode de suppression/minimisation. Une durée absente ne doit pas devenir une conservation indéfinie de fait.
- [ ] **R02 — P0 · Décider + Code : concilier preuves et effacement.** Définir comment minimiser les données personnelles des preuves immuables sans réécrire les montants PS, les faits Trust ni l’historique d’audit. L’effacement actuel est explicitement partiel ; la seule présence d’une réponse « partiel » ne clôture pas le travail de conservation.
- [ ] **R03 — P0 · Vérifier + Code : rectification.** Dans `Privacy.execute!`, la branche générique peut clôturer une rectification sans appliquer elle-même de changement de champ. Formaliser la correction manuelle/automatique, sa vérification et son audit avant de marquer la demande terminée.
- [ ] **R04 — P0 · Décider + Code : limitation/opposition.** Leur exécution actuelle suspend le compte et retire des contenus. Faire valider le caractère adapté de cette réponse selon le traitement contesté ; prévoir les cas où une restriction ciblée suffit, ainsi que la levée de restriction.
- [ ] **R05 — P0 · Vérifier + Code : exhaustivité de l’accès.** Comparer l’export standard à un inventaire de toutes les données personnelles : parrainages, blocages, signalements, accords, preuves, informations Trust et pièces jointes, notamment. Documenter ce qui relève de l’export automatique, d’une réponse humaine ou d’une exclusion motivée ; éviter de présenter une projection partielle comme toute la réponse d’accès.
- [ ] **R06 — P0 · Vérifier : accès au reçu et aux exports.** Rejouer expiration, lien altéré, mauvais propriétaire, session révoquée, compte anonymisé, fuite par logs/referrer/cache, récupération après panne et purge effective du fichier. Le reçu est un lien secret valable 90 jours ; valider cette durée et les modalités de remise/révocation.
- [ ] **R07 — P0 · Code + Exploitation : suivi des délais.** Ajouter ou vérifier alertes avant échéance, dépassement, escalade, traitement des demandes reçues hors compte et contrôle proportionné de l’identité. Un tri par échéance ne remplace pas une alerte opérationnelle.
- [ ] **R08 — P0 · Vérifier + Code : propagation réelle.** Les tâches Google/Stripe/sauvegardes sont des lignes de suivi, pas des appels garantissant une suppression externe. N’ouvrir que les démarches pertinentes, conserver leurs preuves et prévoir un état « non applicable » si nécessaire. Rejouer les effacements après restauration avant de rouvrir les accès.
- [ ] **R09 — P0 · Vérifier : retrait des données publiques.** Contrôler HTML, JSON-LD, galerie, liens médias déjà copiés, commentaires, réponses d’avis, témoignages et caches après retrait/suspension/anonymisation. Vérifier aussi les données privées partagées avec d’autres participants.
- [ ] **R10 — P0 · Décider + Vérifier : consentements.** Aligner notices et catégories de cookies sur les traitements réellement utilisés. Tester acceptation/refus/retrait/version/expiration. Les préférences enregistrées ne constituent pas, à elles seules, un mécanisme bloquant automatiquement tout futur script tiers.
- [ ] **R11 — P0 · Vérifier : preuves de revue juridique.** Définir les pièces ou références accompagnant une politique de conservation. La case déclarative de revue juridique dans l’admin ne remplace pas la validation elle-même.

## 4. Connexion, notifications et prestataires — F-003 / F-006 / F-072

Sources : [callback Google](../app/controllers/users/omniauth_callbacks_controller.rb), [adaptateur Gmail](../lib/seos_mail/gmail.rb), [registre d’envois](../app/models/mail_delivery.rb).

- [ ] **I01 — P0 · Configurer + Vérifier : Google.** Configurer projet, écran de consentement, client et callback exact via `bin/rails routes -g google`. Tester liaison, connexion, refus du consentement, révocation Google, compte bloqué/suspendu, retour d’invitation et renouvellement de session. Le parcours actuel lie un compte SEOS existant : décider explicitement si une inscription initiale via Google est attendue ou hors périmètre.
- [ ] **I02 — P0 · Configurer + Vérifier : Gmail.** Configurer l’expéditeur autorisé, domaine, authentification du domaine, scopes d’envoi/recherche et renouvellement du token. Vérifier confirmations Devise, récupération de mot de passe et notifications, liens HTTPS et absence de contenu privé superflu.
- [ ] **I03 — P0 · Vérifier + Code : échec avant tentative d’envoi.** Le registre Gmail passe à `uncertain` avant l’obtention du token. Une panne de refresh peut donc laisser un envoi jamais tenté dans le chemin de réconciliation. Reproduire ce cas puis distinguer échec avant envoi, résultat ambigu et envoi confirmé, avec reprise sûre.
- [ ] **I04 — P0 · Vérifier + Code : intervention support sur les envois.** Le guide demande de rechercher `message_id`, alors que l’export générique du pilotage ne contient que ID/statut/date. Prévoir un écran autorisé de diagnostic et une reprise auditée utilisable sans supprimer la ligne de suivi ni bricoler la base.
- [ ] **I05 — P0 · Vérifier : pannes fournisseur.** Simuler 401, quota, 429, 5xx, timeout après acceptation, indexation retardée, jobs simultanés et crash avant enregistrement local. Définir alerte et intervention après épuisement des reprises ; ne jamais réémettre aveuglément.
- [ ] **I06 — P1 · Code + Vérifier : notifications de sécurité.** Faire l’inventaire des alertes réellement émises pour changement d’identifiants, rôle, permissions, sessions et actions sensibles ; compléter les événements et préférences manquants.
- [ ] **I07 — P0 · Configurer + Vérifier : carte.** Choisir les fournisseurs de géocodage/tuiles, contrats, quotas et attribution ; tester refus/panne et cache. Vérifier à nouveau qu’un détail `remote` n’a ni géocodage ni carte individuelle et que le flag désactivé coupe tout appel fournisseur de carte.

## 5. Compléments fonctionnels des premières phases

Les points ci-dessous proviennent des suivis historiques. Les éléments explicitement marqués « vérifier » demandent une comparaison finale du code et du plan avant de conclure qu’ils manquent encore.

| Case / ID | Priorité / nature | Reste à faire ou vérifier | Critère de sortie |
|---|---|---|---|
| [ ] M01 | P1 · Vérifier + Code | Couverture de toutes les sections et interactions de la maquette et des 28 user stories, au-delà de l’accueil actuellement implémenté. | Matrice story → routes → rôles → tests → capture, avec les reports explicitement décidés. |
| [ ] M02 | P1 · Code | Catégories : fusion exceptionnelle, édition des critères et héritage Trust versionné (F-012/F-023). | Procédure avec impact prévisualisé, protection des historiques et tests des catégories existantes. |
| [ ] M03 | P1 · Vérifier + Code | Annonces : suppression individuelle des photos et comportement de la galerie après retrait d’un fichier (F-014). | Suppression autorisée d’une photo sans perte des autres, média retiré inaccessible. |
| [ ] M04 | P1 · Code | Délais d’échange, relances, fenêtres d’avis et règles de modération configurables/versionnées (F-020 à F-024). | Publication contrôlée des règles, dossiers anciens préservés et jobs de relance idempotents. |
| [ ] M05 | P1 · Vérifier + Code | Réception des messages en temps réel (F-021). Turbo présent ne prouve pas un abonnement aux messages entrants. | Deux navigateurs connectés, arrivée sans rechargement, droits identiques au HTTP, reconnexion sans doublon. |
| [ ] M06 | P1 · Code | Réponses de commentaires en arborescence si conservées dans le périmètre F-024. | Création/retrait/signalement d’une réponse, permissions et rendu accessibles. |
| [ ] M07 | P0/P1 · Décider + Vérifier | Médiation, attribution de faute et éventuelles conséquences PS/Trust. P0 pour toute sanction activée, P1 pour extension non activée. | Procédure contradictoire, décision motivée, recours et correction auditable ; aucune sanction déduite d’un simple signal. |
| [ ] M08 | P1 · Vérifier + Code | Archivage éditorial, programmation, médias des pages et couverture du journal (F-010). | Retrait public effectif, historique conservé et programmation testée avec fuseaux/retour de version. |

## 6. Trust et parrainage — phase 3

Référence : [compléments du suivi Trust](17-suivi-phase-3.md). Les points déjà livrés ensuite ne doivent pas être recodés.

- [ ] **T01 — P1 · Code/Décider : codes à l’inscription.** Ils sont actuellement saisis depuis le compte confirmé ; implémenter le parcours initial prévu ou faire approuver cette différence de produit.
- [ ] **T02 — P1 · Code : critères personnalisés.** Éditeur versionné, rattachement aux dimensions et questions adaptées au rôle réel dans le service ; validation du traitement des réponses non applicables.
- [ ] **T03 — P1 · Code/Décider : recommandations de compétences consenties et expirantes**, si maintenues dans le périmètre. Ne pas inventer des observations à partir d’une compétence déclarée.
- [ ] **T04 — P1 · Code/Décider : contexte et médiation.** Multiplicateurs par famille et observations négatives ciblées issues d’une médiation confirmée, avec simulation, justification et garde-fous.
- [ ] **T05 — P1 · Code : outils de supervision.** Comparaison cohortes/versions, export d’explication, pagination complète des historiques, délais de recours/détecteurs versionnés et alertes d’escalade.
- [ ] **T06 — P0 · Vérifier : adversarial et équité.** Tester groupes fermés, cycles, collusion, activités coordonnées, faible nombre de preuves, récence et faux positifs. Vérifier neutralité des PS/soutiens financiers et absence de sanction automatique par les détecteurs.
- [ ] **T07 — P0 · Décider + Configurer : activation publique.** Approuver AIPD, textes d’explication, procédure de recours et politique de conservation avant d’activer la version destinée au public.

**Point historique résolu :** la quête unique de parrainage de 15 PS, encore indiquée « restante » dans le suivi de phase 3, est présente dans [Points::Rewards](../app/services/points/rewards.rb). Elle relève désormais de la recette de qualification/idempotence, pas d’un nouveau développement.

## 7. Points, communauté, organisations et soutien — phases 4 à 6

- [ ] **B01 — P0 · Décider + Vérifier : contrat PS final.** Faire approuver le parcours exact de double confirmation, le sens du transfert, les plafonds et compensations. Rejouer modification d’accord, solde insuffisant, litige, annulation et concurrence. Aucun achat, conversion ou vente de PS.
- [ ] **B02 — P0 · Vérifier : récompenses.** Tester les quêtes, témoignages, parrainages et chaînes avec plafonds, changements de mois/règle, suspension, rejeu et reprise des jobs. Les seeds ne doivent pas créditer de points par leur seule exécution.
- [ ] **B03 — P1 · Décider : vocabulaire.** Harmoniser succès/quêtes, points de valorisation, bonus et messages d’interface avec les textes publics.
- [ ] **B04 — P0 · Vérifier : organisations.** Rejouer demande/revue, changement d’identité légale, transferts de responsabilités, dernier propriétaire, invitations expirées et suspension ; contrôler l’étanchéité entre équipes et fiches légales privées.
- [ ] **B05 — P0 · Décider + Vérifier : Voyage.** Valider conditions, responsabilités, âge/publics vulnérables, hébergement, repas, contribution et calendrier. Tester capacités concurrentes et confidentialité des adresses/messages. La publication monde doit rester exclusive au super-admin.
- [ ] **B06 — P0 · Vérifier : partenaires.** Publication, périodes de visibilité, liens externes, médias, révocation et absence de données légales privées dans le public/SEO.
- [ ] **B07 — P2 · Décider + Configurer + Vérifier : Stripe.** Maintenir le flag désactivé tant que l’entité, la comptabilité, la fiscalité et le vocabulaire du soutien ne sont pas validés. Avant activation : recette des webhooks signés, rejeux, événements désordonnés, remboursement et rapprochement, sans écriture PS ni influence Trust.
- [ ] **B08 — P2 · Décider : fonctions non activées.** Facebook, compte PS d’organisation ou « garantie du double » ne doivent pas être activés implicitement. Documenter leur exclusion ou un lot séparé avec validations adaptées.

## 8. Studio UI, contenus et séparateurs — F-008 / F-009 / F-015

Mise à jour du 7 septembre : **Studio admin → Personnalisation** ajoute le compositeur de pages, le header/footer et le kit extrait de la maquette ; voir le [guide et les preuves de recette](24-studio-mon-site-et-kit-maquette.md). Les points ci-dessous restent une checklist de la cible complète, notamment les contrôles typographiques fins, les différences détaillées et la recette exhaustive des variantes. Les capacités livrées ne se limitent plus aux cinq pages et quelques tokens du premier Studio.

- [ ] **S01 — P1 · Code/Décider : registre complet.** Inventorier pages, blocs et composants réellement administrables ; décider puis implémenter les emplacements manquants. Ne pas confondre « cinq pages système » et « toutes les pages du site ».
- [ ] **S02 — P1 · Code : kit étendu.** Compléter tailles/interlignes/graisses, espacements, densité, ombres, largeur de conteneur, composants et états. Conserver des valeurs bornées et des fontes locales.
- [ ] **S03 — P1 · Code : séparateurs.** Placement par frontière de bloc, tailles/couleurs/instances et resets correspondants. Vérifier le comportement réel de chaque niveau de mouvement proposé.
- [ ] **S04 — P0 · Vérifier + Code : accessibilité des variantes.** Le validateur actuel contrôle cinq paires de couleurs ; tester aussi boutons, liens, focus, erreurs, badges et surfaces effectives. Une palette valide sur ces cinq paires peut rester inaccessible sur un composant.
- [ ] **S05 — P1 · Vérifier + Code : défaut et resets.** Vérifier token, groupe, composant, bloc, image/alt, séparateur, page et site. Les premières versions éditoriales publiées servent actuellement de référence de reset : faire valider leur correspondance au défaut souhaité et les figer comme références explicites si nécessaire.
- [ ] **S06 — P0 · Vérifier : cas limites du reset.** Notamment alt seul avec image conservée, page sans version initiale, image retirée encore référencée, publication concurrente et ancien brouillon publié tardivement. Aucune validation ne doit produire une 500 ou une perte silencieuse.
- [ ] **S07 — P1 · Code : revue des changements.** Afficher différences lisibles, pages touchées, médias remplacés, références restaurées et contrastes, au-delà du JSON technique des valeurs. Compléter le catalogue vivant de composants.
- [ ] **S08 — P0 · Vérifier : cycle complet.** Preview mobile/tablette/bureau, isolation du brouillon, publication atomique, CSP, navigation Turbo, cache, reset et mouvement réduit. Vérifier que les documents légaux et données métier ne sont pas modifiés par un reset de présentation.

## 9. Administration — F-071

Source : [OperationsController](../app/controllers/admin/operations_controller.rb). Le registre actuel apporte de la lecture bornée ; ce n’est pas encore toute la console décrite dans [le plan admin](07-panel-administration.md).

- [ ] **A01 — P1 · Code : recherche globale réelle.** La recherche actuelle choisit une ressource et filtre par identifiant. Compléter les recherches métier autorisées, filtres, pagination, liens vers dossiers et historiques.
- [ ] **A02 — P1 · Code : files de travail et indicateurs.** Dossiers à traiter, délais, affectations, alertes et priorités, avec filtres selon permissions.
- [ ] **A03 — P1 · Code : fiche membre 360°.** Compléter liens vers échanges, modération, affiliations, recours, preuves et historique, en gardant les sections sensibles masquées selon droits.
- [ ] **A04 — P0 · Vérifier + Code : cohérence des permissions.** Notamment un admin avec seulement `operations.manage` : les mutations sont autorisées mais le registre des opérations groupées est associé à `operations.read`. Tester le parcours entier après redirection, puis définir les prérequis ou corriger les associations. Faire de même pour les permissions du Studio et SEO.
- [ ] **A05 — P0 · Vérifier : ressources immuables.** Aucun écran, export réimportable ou action de masse ne doit permettre de modifier/supprimer écritures PS, événements Trust, snapshots ou audit. Refaire la recette des compensations par les voies dédiées.
- [ ] **A06 — P1 · Code/Vérifier : blacklist.** Recherche, motif, expiration, levée anticipée, historique et périmètre exact du blocage, y compris inscription, sessions existantes et Google. Contrôler les adresses administratives protégées.
- [ ] **A07 — P0 · Vérifier : exports et révélations.** Justification, droits, réauthentification, champs réellement exportés, limites, absence de PII dans URL/logs et audit suffisamment précis pour retrouver l’action.
- [ ] **A08 — P0 · Vérifier : clôture des opérations.** Sélection figée, double validation distincte, expiration, cible changée entre preview/exécution, rejeu et dossier déjà publié/terminé. Les boutons ne doivent pas proposer une modification d’une version immuable.

## 10. SEO, performance, médias et accessibilité — F-017 / F-072

- [ ] **Q01 — P0 · Vérifier : indexation effective.** Domaine canonique réel, variantes d’URL/filtres, profils et espaces privés non indexables, sitemap limité aux contenus éligibles, retrait 404/410 et absence de PII dans Schema.org/OpenGraph. `robots.txt` n’est jamais une protection d’accès.
- [ ] **Q02 — P1 · Code/Configurer : SEO complet.** Sitemaps segmentés à grande échelle, redirections d’anciens slugs, métadonnées éditables, diagnostics, Search Console et périmètre GEO prévu. Les préférences actuelles des crawlers ne couvrent pas tout l’éditeur SEO envisagé.
- [ ] **Q03 — P0 · Vérifier + Code : charge réaliste.** Catalogue, distance/filtres, sitemap et listes admin avec volumes représentatifs. Mesurer temps de réponse, mémoire, requêtes/N+1 et index, puis corriger les traitements en mémoire et limites de pagination si nécessaire.
- [ ] **Q04 — P0 · Vérifier : accessibilité manuelle.** Clavier, lecteur d’écran, zoom, petits écrans, focus après erreurs/dialogues, formulaires longs, messages de statut et reduced motion. Axe et les PNG ne prouvent pas à eux seuls toute la conformité attendue.
- [ ] **Q05 — P0 · Vérifier : médias.** Fichiers invalides/tronqués, MIME trompeur, métadonnées, tailles/dimensions/durée extrêmes, coût CPU/mémoire, délais de traitement et fichiers orphelins. Vérifier la stratégie de scan/quarantaine attendue par F-072, distincte du seul réencodage.
- [ ] **Q06 — P0 · Vérifier : sécurité de bout en bout.** CSRF, CSP/nonce, upload/download, IDOR, élévation de rôle, cookies, rotation/revocation, brute force et scraping. Contrôler les limites par IP derrière le proxy réel, ainsi que les faux positifs sur un réseau partagé.
- [ ] **Q07 — P0 · Vérifier : erreurs et confidentialité technique.** 404/410/422/500 en production, formats HTML/CSV/JSON, contenu des logs, remontées d’erreur, traces OAuth et absence de secret dans les réponses.
- [ ] **Q08 — P0 · Vérifier : dépendances et build final.** Relancer les audits au moment du déploiement ; vérifier budgets JS, polices locales, découpage carte, assets et navigateur sur l’image réellement livrée.

## 11. Exploitation et lancement — F-073

Procédures de référence : [guide d’exploitation et matrice des 21 scénarios](22-exploitation-et-recette.md).

- [ ] **O01 — P0 · Configurer : préproduction représentative.** Domaine/TLS, hébergement, registre d’image, reverse proxy, volumes SQLite/Active Storage, espace disque et séparation des environnements.
- [ ] **O02 — P0 · Configurer : secrets.** Clés Rails/chiffrement, Google/Gmail, éventuels fournisseurs ; sauvegarde séparée, contrôle d’accès, rotation et procédure de perte de clé. Ne pas inscrire leurs valeurs dans ce document.
- [ ] **O03 — P0 · Configurer + Vérifier : jobs.** Worker Solid Queue, tâches récurrentes, base queue/cache/câble, redémarrage, échec et rattrapage. Contrôler particulièrement expiration des exports et recalculs/récompenses.
- [ ] **O04 — P0 · Configurer : monitoring.** Alertes 5xx, latence, 429, jobs bloqués, Gmail incertain, saturation disque, sauvegarde périmée et délais de support/RGPD. Désigner qui reçoit et traite chaque alerte.
- [ ] **O05 — P0 · Vérifier : sauvegarde hors serveur.** Chiffrement, rétention, accès, manifestes, clés et restauration de toutes les bases/fichiers nécessaires. La restauration locale déjà testée n’est pas une preuve de reprise du stockage distant.
- [ ] **O06 — P0 · Vérifier : déploiement/rollback.** Image avec libvips/FFmpeg, migrations, compatibilité de retour, maintenance, arrêt des écritures, reprise des jobs et contrôles fonctionnels après bascule.
- [ ] **O07 — P0 · Décider + Vérifier : incidents/support.** Responsabilités, astreinte, escalade, qualification d’incident, décision de communication et exercice avec l’équipe. Mesurer les objectifs de perte de données et de reprise retenus.
- [ ] **O08 — P0 · Vérifier : données initiales.** Aucun compte ou mot de passe de démonstration sur environnement public, droits admin minimaux, durée des délégations, catégories/barèmes/textes validés, flags conformes au périmètre décidé.
- [ ] **O09 — P0 · Vérifier : recette fonctionnelle finale.** Rejouer les 21 scénarios F-073 sur préproduction avec les rôles visiteur, membre, association, partenaire, admin délégué et super-admin ; consigner les résultats réels et les anomalies.
- [ ] **O10 — P0 · Décider : ouverture.** Faire approuver la liste exacte des fonctions activées, les éventuels reports P1 et les risques résiduels. Préparer support, contenus et communication ; aucune mise en ligne n’est validée par la seule réussite des tests locaux.

## 12. Documentation à remettre en cohérence

- [ ] **D01 — P1 · Documentation : README principal.** Son début pointe encore vers les phases 1–2 et certaines phrases indiquent Google/Gmail/Studio comme absents alors que la phase 7 a apporté leur première implémentation. Remplacer ces affirmations par une description de l’état actuel et de ses limites.
- [ ] **D02 — P1 · Documentation : suivis historiques.** Ajouter des renvois vers ce document pour les sujets résolus ensuite : Gmail, Google, Top annonces, vidéo, scores/badges, estimation PS, quêtes et organisations. Conserver les résultats historiques sans les faire passer pour une nouvelle recette.
- [ ] **D03 — P1 · Documentation : matrice de couverture.** Pour chaque F-xxx et chaque user story, distinguer livré, partiel, reporté, à vérifier en préproduction et validé extérieurement. Un nom de ressource dans le registre admin ne suffit pas à déclarer son workflow complet.
- [ ] **D04 — P1 · Documentation : preuves de livraison.** Archiver rapports utiles hors des seuls fichiers temporaires locaux, avec commit, environnement, versions des outils, date et périmètre testé. Garder les données personnelles et secrets hors de ces preuves.

## 13. Ordre de travail recommandé

1. **Fermer le périmètre de lancement** : attribuer les responsables, choisir les fonctions actives et arbitrer les reports explicites.
2. **Traiter L01 à L03 et les corrections concrètes** : CGU/âge, conservation, droits, reprise Gmail et cohérence des permissions.
3. **Préparer la préproduction** : secrets, fournisseurs, workers, monitoring, sauvegarde distante et domaine.
4. **Compléter les P1 retenus** : parcours historiques, Trust, Studio, admin et SEO ; conserver une recette verticale par rôle.
5. **Rejouer la recette complète** : tests automatisés, concurrence, 21 scénarios métier, accessibilité manuelle, performance et erreurs fournisseur.
6. **Effectuer l’exercice opérationnel** : restauration, reprise des effacements, rollback et incident avec l’équipe.
7. **Décider l’ouverture**, preuves et validations à l’appui. Garder Stripe et toute fonction non validée désactivés.

### Registre de clôture à remplir

| ID | Responsable nommé | Décision / réalisation | Preuve et version | Date | Clôturé par |
|---|---|---|---|---|---|
| À renseigner | | | | | |

**Règle finale :** une ligne n’est terminée que lorsque son résultat est vérifié. « Codé », « simulé localement », « configuré » et « validé pour la production » sont des états différents.
