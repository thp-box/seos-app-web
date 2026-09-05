# Phase 3 — Parrainage, confiance et recours

Suite livrée : [la phase 4](18-suivi-phase-4.md) apporte désormais le registre de Points Services et le crédit unique du parrain principal qualifié. Les mentions d’attente ci-dessous décrivent l’état historique de la livraison de phase 3.

Livraison du 5 septembre 2026. Références : [plan F-030 à F-033](10-plan-construction-feature-par-feature.md), [formule de référence](08-systeme-trust-score.md). Le socle fonctionnel est implémenté ; l’activation publique reste une décision de gouvernance, après simulation et validation du dossier de lancement.

## Parcours disponibles

- `/compte/confiance` : saisie de codes pendant les sept premiers jours du compte confirmé, choix du principal pendant cette fenêtre, émission de codes pour les parrains éligibles, objections, historique des calculs et recours.
- `/confiance` : explication publique de la formule, des seuils, des limites et du recours.
- Profils et fiches d’annonces : indice public uniquement lorsqu’une version active possède une projection ; marque provisoire et compteurs sans identité des parrains. Aucun `AggregateRating`, signal interne ni détail de recours dans le JSON-LD.
- `/admin/confiance` : versions, preuves, snapshots récents, recours, invalidation et restauration des soutiens. Permissions `trust.read` et `trust.manage` distinctes.
- `/admin/confiance/risks` : file interne séparée avec permission `trust.risk` et accès journalisé. La clôture exige aussi `trust.manage`.

## F-030 — Parrainage

Codes aléatoires de 192 bits stockés exclusivement en SHA-256, affichés une seule fois lors de l’émission. Expiration sept jours ; cinq codes disponibles, cinq émissions sur 24 heures, une émission par minute maximum. Le code en clair est exclu des journaux applicatifs et n’est pas mis en session ni dans les notifications.

Les transactions verrouillent le compte et utilisent les transactions SQLite immédiates du projet. Les index uniques protègent la consommation du code, la paire parrain/filleul, les positions 1–10 et le principal. Un lot invalide est intégralement annulé. L’invalidation conserve sa position : elle ne permet pas de contourner la limite de dix émissions de soutien.

Éligibilité : compte actif, e-mail confirmé, 30 jours, deux partenaires distincts. Une exemption fondatrice expire après 30 jours et exige une action super-admin motivée et auditée ; aucune exemption implicite dans les seeds.

Le soutien provisoire produit immédiatement son poids de 0,25 dans le prochain calcul. Après 72 heures sans objection il est confirmé. Retrait et restauration sont audités, notifiés et recalculés. Un recours indépendant d’un snapshot est disponible en cas de retrait.

La qualification du principal exige 30 jours, e-mail confirmé et deux partenaires absents de l’ensemble des parrains. `qualified_at` représente une éligibilité, **aucun crédit de points**. La phase 4 devra vérifier à nouveau la validité du soutien et assurer l’unicité de la quête sur toute la vie du parrain avant une écriture de 15 PS dans le registre.

## F-031 — Calcul et conservation

`TrustSources` transforme les échanges doublement confirmés et les notes structurées révélées en événements idempotents. Le nom de la dimension est figé dans l’évaluation au dépôt ; une modification ultérieure du référentiel ne requalifie pas rétroactivement les notes. Masquer le texte d’un avis ne supprime pas ses notes ; l’invalidation de l’avis les exclut. Un avis encore masqué, une question non applicable, un critère personnalisé sans dimension reconnue, un signalement et le texte libre ne contribuent pas.

`TrustCalculator` applique la normalisation 1–5, l’a priori 2/2, les poids source 1 et 0,8, la récence par jour civil (demi-vie 548 jours, plancher 0,25), les facteurs de paire 1/0,5/0,2 et un plafond cumulé 2,5 par paire/dimension. Le budget par échange/dimension est 1. Les seuils de publication utilisent les confirmations indépendamment du nombre de questions : déposer un avis ne fait pas perdre la diversité acquise.

À partir de sept auteurs, chaque auteur est plafonné à 15 % du poids final de la dimension. Lorsqu’au moins deux catégories sont présentes, la contribution globale d’une catégorie est plafonnée à 60 %. Une seule catégorie ne peut mathématiquement être ramenée à 60 % sans ajouter une preuve fictive : elle reste seule, explicitement localisée, jusqu’à diversification.

Les dimensions applicables utilisent les poids 30/25/20/15/10 renormalisés. Le global agrège leurs statistiques non arrondies, puis ajoute les parrainages au numérateur et au dénominateur bayésiens. Les parrainages ne créent aucune dimension ou compétence. Les multiplicateurs auteur et contexte restent neutres à 1 : aucun niveau social, point, appareil ou donnée sensible ne les influence. Aucun héritage de catégorie n’est activé.

Les dimensions et catégories sont conservées dans le JSON du snapshot, plutôt que dans deux tables de projection séparées. `trust_profiles` pointe vers le calcul actif. Les preuves, corrections et snapshots sont append-only au niveau Rails **et SQL** ; une correction est une nouvelle ligne, jamais une réécriture de preuve. Les configurations et explications des versions sont également protégées en SQL.

L’empreinte inclut le résultat et ses contributions. Un recalcul identique dans la même journée réutilise le snapshot. L’évolution de la récence crée un nouveau calcul ; les anciennes versions restent consultables. Une bascule cache les projections de la version précédente jusqu’au calcul actif suivant.

## Gouvernance et exploitation

La seed de développement prépare `v1.0` en **brouillon**, sans score fictif ni activation. Le cycle est : créer → simuler → faire approuver par un autre compte super-admin → calculer en ombre → activer. La simulation appelle le moteur réel pour les repères de parrainage et les scénarios nouveau membre, partenaires indépendants, paire répétée et ancien membre. Elle vérifie aussi l’indépendance à l’ordre des événements. L’activation exige un snapshot en ombre pour chaque compte actif. Un retour à une version précédemment active est disponible et audité.

La V1 accepte exactement la configuration documentée. L’écran ne permet pas une modification libre de poids en production ; une évolution de formule exige une implémentation et des tests supplémentaires, puis une nouvelle version. L’approbation enregistre le motif de revue, mais ne remplace pas le travail réel de deux personnes, les comparaisons de cohortes et la validation juridique du dossier.

Les fins d’échanges, dépôts/révélations et invalidations d’avis, ainsi que les changements de soutien, planifient `TrustRecalculationJob`. `TrustMaintenanceJob`, programmé chaque heure en production, assure maturité, qualification, expiration des signaux et recalcul quotidien de la récence. Il faut un worker Solid Queue en fonctionnement. En développement, un passage explicite est possible :

```sh
bin/rails runner 'TrustMaintenanceJob.perform_now'
```

## F-032 — Revue humaine

Le membre voit les snapshots de ses propres calculs, leurs versions, dimensions publiables et poids par preuve, avec des liens vers ses échanges. Ses recours, déclarations et décisions restent privés et chiffrés. Un recours ouvert par source est unique. Le délai de réponse initial est sept jours, visible à l’utilisateur et à l’équipe.

Le traitement suit ouverture → prise en charge → acceptation ou maintien motivé → notification → recalcul. Une acceptation exige préalablement une correction d’une preuve du snapshot, ou une restauration auditée du soutien contesté. Les décisions n’acceptent aucun champ « nouvelle note ». Les écrans administratifs conservent les protections de session et de réauthentification du projet.

## F-033 — Risque interne

Détecteurs minimisés V1 : au moins dix échanges en 24 heures, cinq échanges avec une paire en 30 jours, cinq soutiens émis en 24 heures, cycle de parrainage détectable jusqu’à cinq niveaux. Les résultats contiennent type et compteur, sans collecte IP/appareil, adresse, conversation ou contact. La file est réservée à la revue humaine ; un classement sans suite évite de rouvrir le même signal pendant sa période de conservation.

Les signaux expirent et sont supprimés après 30 jours ; les décisions d’accès et de traitement restent dans l’audit. Aucun détecteur ne modifie compte, score ou droits. Une mesure éventuelle passe par la procédure humaine existante et une correction de source explicite. Voir le complément technique d’AIPD dans [la documentation RGPD](09-rgpd-profils-publics.md).

## Périmètre encore à approfondir avant généralisation

- Saisie de codes directement dans le formulaire d’inscription : cette livraison les accepte dans le compte confirmé pendant les sept jours documentés.
- Éditeur de critères avec rattachement explicite des critères personnalisés aux dimensions et questions métier distinctes selon le rôle réel du service (reste de F-023).
- Recommandations de compétence consenties et expirantes, multiplicateurs contexte par famille, simulations étendues de groupes fermés et attaques coordonnées ; aucun de ces signaux n’est improvisé dans le calcul actuel.
- Contributions négatives ciblées issues d’une médiation confirmée : le moteur actuel sait exclure/rétablir les preuves existantes, mais ne crée pas encore d’observation de médiation par dimension.
- Console comparative détaillée entre cohortes/versions, configuration versionnée des délais de recours et détecteurs, export d’explication, pagination complète des historiques au-delà des dernières lignes présentées.
- Politique de conservation des preuves/snapshots et procédure d’anonymisation validées, AIPD, textes définitifs et revue des effets disproportionnés avant activation publique en production. Le cycle logiciel ne constitue pas leur validation.
- Crédit unique de la quête de 15 PS par le registre de phase 4.

Ces points sont explicités pour ne pas présenter le lancement de production ou toute la feuille de route de confiance comme déjà validés.

## Vérifications de cette livraison

Suite complète finale : **177 exemples RSpec, aucun échec**, seed `44022` ; couverture **99,86 % des lignes** (1535/1537) et **95,69 % des branches** (644/673). Rapport JUnit : `tmp/rspec-phase-3.xml`.

- Tests métier et HTTP : repères provisoires, transactions des codes, délais, qualification, révélations d’avis, plafonds, corrections, recours et permissions ; le journal d’audit général ne contourne pas `trust.risk`.
- Test navigateur : recours réel via Turbo, affichage mobile/bureau sans débordement, axe WCAG 2 A/AA, 2.1 AA et 2.2 AA, console sans erreur. Les captures `tmp/screenshots/trust-account-375.png` et `trust-account-1440.png` ont été examinées ; les baselines existantes n’ont pas été remplacées.
- `bin/check-exchange-concurrency` : base temporaire isolée, deux connexions concurrentes, consommation unique d’un code, course pour le dixième soutien, principal unique et snapshot idempotent, en plus des contrôles existants des échanges.
- Migrations appliquées et autoload Zeitwerk vérifié ; RuboCop et Brakeman sans anomalie ; `git diff --check` propre.
- Compilation des assets en mode production réussie ; assets précompilés nettoyés puis build de développement restauré. Aucun déploiement effectué.
