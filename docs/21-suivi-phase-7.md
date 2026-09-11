# Phase 7 — Confidentialité, administration et exploitation

Branche de travail : `phase-7-conformite`. Périmètre de référence : F-070 à F-073 du [plan de construction](10-plan-construction-feature-par-feature.md), avec le Studio F-008/F-009 reporté du socle.

## Parcours livrés

### Confidentialité

`/preferences-confidentialite` présente acceptation, refus et personnalisation avec le même poids visuel. Chaque choix produit un consentement versionné, rattaché à un identifiant de navigateur signé, sans adresse IP conservée dans cette table. Aucun outil analytics tiers n’est ajouté ni chargé par cette phase.

`/compte/confidentialite` exige une session récente. Le membre peut demander accès, portabilité, rectification, effacement, limitation, opposition et retrait. L’échéance initiale est un mois ; le compte affiche la réponse et un lien privé de suivi valable 90 jours, utilisable après clôture du compte. Ce lien est un secret de consultation : il est filtré dans les paramètres de logs, sans referrer, sans cache et sans indexation.

Les exports JSON contiennent une projection explicite des données du demandeur : profil, annonces, messages écrits, candidatures et messages de mission, commentaires, avis, témoignages, affiliations, récompenses, contributions, favoris, notifications, sessions sans jetons et demandes de droits. Les mots de passe, tokens et identités des autres participants ne sont pas exportés. Les signaux internes de risque et les données mêlées à des droits de tiers demandent une revue humaine ; cet export standard ne remplace pas cette revue. Le fichier est chiffré avant stockage et téléchargeable seulement par son propriétaire pendant 24 heures. Un job récurrent purge les fichiers expirés.

La gestion admin est séparée entre `privacy.manage` et `privacy.rules`. Une demande sensible passe par une revue motivée puis une seconde validation super-admin distincte du demandeur et du réviseur. L’effacement retire le profil, les annonces, coordonnées, images, commentaires, textes d’avis et témoignages ; révoque les sessions et la liaison Google ; et anonymise le compte. Un administrateur ou propriétaire d’organisation doit d’abord transférer ses responsabilités. La réponse indique explicitement un **effacement partiel** : les écritures PS, preuves et conversations partagées sont conservées pour une revue distincte. Les confirmations Google/Stripe/sauvegardes sont suivies par prestataire ; elles ne sont jamais inventées par le logiciel.

### Conservation

Les versions définissent des durées bornées pour sessions, notifications, contacts résolus, invitations expirées, préférences cookies et exports (un jour fixe). Une publication demande simulation, déclaration de revue juridique et seconde approbation. La politique elle-même expire au plus tard deux ans après sa prise d’effet ; une version publiée est immuable dans le modèle et en SQL.

Une purge affiche au maximum 1 000 identifiants par finalité, expire après 15 minutes et exige un autre super-admin. Au moment d’exécuter, les identifiants sont recoupés avec les éléments encore éligibles. Une nouvelle donnée n’entre donc pas silencieusement dans une sélection déjà approuvée. Les registres PS/Trust/audit ne sont pas réécrits par cette purge.

**Limite de lancement à traiter avec le DPO :** cette purge opérationnelle ne constitue pas encore une purge automatique des pièces probatoires immuables, des conversations partagées et des copies de sauvegarde. Leur base légale, minimisation, durée d’archive et procédure de traitement doivent être validées et appliquées avant de déclarer l’ensemble du produit conforme et prêt à ouvrir. Aucun choix global `forever` n’est proposé ; aucune durée d’exemple n’est publiée par les seeds.

### Pilotage et Studio

`/admin/operations` offre un registre de toutes les ressources applicatives, filtré par permission. Les résultats et exports sont bornés à 100 lignes et ne déversent jamais les attributs privés. Les interfaces de gestion métier existantes restent dans la navigation. La fiche membre montre identité masquée, compteurs et solde selon droit ; une révélation des coordonnées demande un super-admin récemment réauthentifié et un motif audité.

La suspension groupée porte sur 1 à 20 membres actifs, avec sélection figée, contrôle de modification, expiration et seconde validation. Les comptes administratifs sont exclus. Le blocage temporaire d’une adresse utilise un HMAC et expire en moins d’un an.

`/admin/studio` propose des champs de couleurs, formes, fontes locales autorisées, mouvement et contenus de cinq pages. Les images sont nettoyées par `SafeImage`, privées avant publication et de nouveau inaccessibles après retrait. Le super-admin prévisualise à 375, 768 ou 1440 px dans un cadre réel, valide les contrastes puis publie une version immuable. Les textes ne deviennent jamais du HTML arbitraire. Les séparateurs sont décoratifs et leur animation respecte le mouvement réduit. Les resets créent de nouvelles versions, sans supprimer l’historique. `SEOS Default v1` reste le thème de code. Le reset du site ou de toutes les pages restaure aussi les premières versions publiées des quatre pages explicatives, dans de nouvelles versions éditoriales, atomiquement avec la publication du thème. La prévisualisation permet de choisir chaque page avant publication.

Le reset porte sur le thème et les cinq pages système administrables. Les articles, documents légaux, données membres, règles PS et Trust restent des ressources distinctes de ce périmètre de présentation.

### Intégrations et exploitation

Google Login utilise OmniAuth avec état OAuth et protection CSRF sur la requête POST. Le compte doit d’abord être lié depuis SEOS après authentification récente ; l’égalité d’e-mail seule ne crée pas de liaison. Seul le `sub` est persisté. Le callback renouvelle effectivement la session applicative et révoque la session précédente.

Gmail dispose d’un adaptateur ActionMailer et d’un registre d’envois. Une réponse ambiguë est réconciliée par `Message-ID` ; si le fournisseur ne permet pas de confirmer l’envoi, une nouvelle émission automatique est bloquée. Les secrets et corps des erreurs fournisseur ne sont pas consignés dans le registre.

Les consignes aux robots de recherche et d’entraînement sont versionnées depuis Pilotage. Les espaces privés restent interdits aux crawlers ; les pages publiques des organisations et leurs fiches éligibles rejoignent le sitemap. Les profils restent non indexables. Le catalogue possède une limite supplémentaire contre le scraping. `robots.txt` est une consigne, pas une barrière d’autorisation.

`bin/backup` sauvegarde, vérifie et restaure une base SQLite et ses fichiers dans une destination neuve. La recette utilise une base isolée et vérifie données, fichiers, empreintes et intégrité ; aucun exercice de restauration n’a écrasé la base de développement. Le [guide d’exploitation](22-exploitation-et-recette.md) détaille configuration, déploiement, rollback, sauvegarde, incident et prérequis externes.

## Recette et preuves

Les nouvelles specs se trouvent dans `spec/services/privacy_spec.rb`, `launch_tools_spec.rb`, `phase_seven_edge_cases_spec.rb`, `backup_spec.rb`, `spec/requests/phase_seven*.rb` et `spec/system/phase_seven_spec.rb`. Les specs antérieures restent la preuve des échanges, PS, Trust, chaînes, missions, partenaires et flags. Le rapport consolidé de la suite est produit dans `tmp/rspec-phase-7.xml`.

La revue visuelle du 6 septembre vérifie les cinq nouveaux écrans à 375 et 1440 px avec axe WCAG 2.2. Les 16 références existantes ont été recapturées explicitement, puis examinées : les différences sont dans le footer avec le nouveau lien « Confidentialité et cookies » ; à 320 px, le retour à la ligne augmente la hauteur de 39 px. Le thème, la navigation principale et les contenus existants restent visuellement identiques hors ce changement intentionnel. Les anciennes références sont conservées par Git ; les tests n’écrivent jamais les baselines.

Les seeds ont été exécutées deux fois. Elles ajoutent `admin@seos.test` et `partenaire@seos.test` aux trois comptes existants, avec le même mot de passe de démonstration `SeosDemo2026!`, sans publication de thème, de politique de conservation ou d’achat de PS.

Les résultats finaux des contrôles sont consignés à la fin de ce document après exécution. Les validations juridiques et les essais avec les vrais comptes Google, fournisseurs et stockage de secours restent des portes de mise en production, pas des validations implicitement acquises par les tests locaux.

### Résultats du 6 septembre 2026

- Suite complète : **283 exemples, aucun échec**, seed `737`, couverture **98,97 % des lignes / 92,10 % des branches**.
- Après cette suite, correction des cas de reçu avec session révoquée et de reconfirmation Devise pendant l’anonymisation : **13 exemples ciblés, aucun échec**, seed `1082`. Ils vérifient notamment que l’ancienne adresse est effectivement remplacée et que `unconfirmed_email` est vidé.
- RuboCop : **307 fichiers, aucune infraction**. Brakeman : **0 avertissement, 0 erreur**. Audit des gems avec base actualisée et audit Yarn : **aucune vulnérabilité connue signalée**. Zeitwerk et contrôle de build : OK.
- Compilation des assets en production : OK ; assets de développement reconstruits ensuite.
- Contrôle de concurrence sur base isolée : tous les scénarios précédents et suspension groupée unique OK. Sauvegarde de cette base applicative restaurée dans un autre dossier : comptes et opérations PS conservés, somme des écritures égale à zéro, intégrité SQLite et clés étrangères vérifiées.
- Seeds exécutées deux fois : **5 comptes locaux, zéro opération PS, Stripe désactivé, aucune politique de conservation publiée**.
- Aucune mise en production, activation fournisseur ou communication externe effectuée. La clôture opérationnelle de F-073 reste conditionnée par les validations et essais externes indiqués dans le guide.
