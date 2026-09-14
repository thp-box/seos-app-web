# Phase 5 — Engagement communautaire

Implémentation du 5 septembre 2026, sur le registre Points Services de la phase 4. Périmètre : F-050 à F-053 de `10-plan-construction-feature-par-feature.md`.

## Parcours livrés

| Fonction | Membre / visiteur | Administration |
| --- | --- | --- |
| Quêtes | `/compte/engagement` : objectifs, progression, niveau, preuves privées et décision ; portefeuille pour les récompenses natives et le partage mensuel | `/admin/engagement` : création, modification éditoriale, archivage, revue, refus et réexamen des quêtes personnalisées |
| Top et urgence | Demande sur une annonce publique autorisée, retrait, badge Top ; badge urgent à durée limitée | Éligibilité contrôlée à la demande, à l’approbation et à l’affichage ; ordre et dates de mise en avant ; politique versionnée par le super-admin |
| Témoignages | Écrit ou vidéo MP4 avec transcription, nom public choisi, consentement distinct et retrait ; `/temoignages` pour les publications autorisées | Relecture, refus, réexamen, publication et retrait ; récompense examinée séparément dans `/admin/points` |
| Chaînes | `/compte/chaines` : création, suivi, invitation privée après service rendu, confirmation après connexion puis relais | Inspection des maillons et récompenses, médiation, clôture/réactivation ; simulation et publication des barèmes par le super-admin |
| Soutien financier | Aucun parcours public lorsque le flag est désactivé ; `/compte/soutien` seulement après activation | `/admin/soutien` : lecture, rapprochement, remboursement intégral par super-admin, activation/désactivation auditée |

Les gestionnaires d’association participent aux quêtes et aux chaînes en leur nom personnel. Une demande Top peut porter sur une annonce d’association vérifiée si le demandeur dispose déjà du droit de la gérer. Le portail partenaire est prévu en phase 6 ; aucun statut partenaire ne procure ici de privilège.

## Points et quêtes

Les neuf objectifs de référence sont semés sans distribuer de points. Le moteur existant continue à traiter accueil, annonces éligibles, demandes acceptées, parrainage qualifié, cycles et niveaux. Les niveaux ne modifient pas le Trust Score.

Une quête personnalisée demande une preuve et une revue humaine. Son montant, sa période et sa version de barème sont figés au dépôt. Une contrainte unique interdit une seconde soumission pour la même période ; les récompenses sont inscrites dans le registre avec une clé stable. Le refus peut être réexaminé sans effacer le journal d’audit. La preuve originale est conservée ; le motif de réexamen permet de documenter les vérifications complémentaires. Une quête déjà utilisée peut être renommée ou archivée, mais son contrat ne peut pas être remplacé.

Les preuves natives de phase 4 restent consultables dans le portefeuille. La saisie libre d’une récompense de chaîne n’est plus proposée ni acceptée par le contrôleur membre : les nouvelles chaînes utilisent les confirmations réelles. Les anciennes preuves conservent leur historique.

## Visibilité et consentement

Le Top requiert un niveau Argent/Or ou un partage validé pendant le mois courant, puis une décision humaine. Les annonces fermées, devenues privées ou sans éligibilité ne bénéficient plus de l’affichage Top. L’approbation fixe les dates et la position ; les requêtes publiques vérifient leur validité sans dépendre d’un job d’expiration.

La politique initiale fixe l’urgence à 7 jours et le Top à 30 jours maximum. Le super-admin peut publier une nouvelle politique bornée (urgence : 1 à 30 jours ; Top : 1 à 90 jours). Les dates déjà accordées restent inchangées. La garantie du double n’est ni activée ni promise.

Le consentement `publication-2026-09-v1` enregistre une version, une date et le nom public choisi. Refuser ce consentement empêche la soumission du témoignage. Le retrait coupe immédiatement la page publique et l’accès public au média, sans défaire une récompense déjà validée. Une seconde publication du même format réutilise la même demande de récompense : aucun second bonus.

Les images justificatives passent par `SafeImage`. Les vidéos passent par FFprobe et FFmpeg : MP4 uniquement, 25 Mo maximum, 180 secondes et 1920 × 1920 maximum, transcodage H.264/AAC, suppression des métadonnées, protocoles limités à `file,pipe`, démultiplexeur MOV/MP4. Les commandes utilisent des arguments séparés et un délai maximal. Aucune intégration vidéo externe ni traceur de partage n’est ajouté. Les transcriptions sont affichées avec les vidéos ; le montage de sous-titres synchronisés reste une tâche éditoriale.

Installer FFmpeg/FFprobe sur tout environnement exécutant Rails (`apt-get install ffmpeg` sur Debian/Ubuntu). Le Dockerfile inclut cette dépendance. Sur cet environnement de développement, les exécutables ont été rendus disponibles dans `~/.local/bin` à partir des paquets Ubuntu, avec leurs bibliothèques isolées dans `~/.local/share/seos-video-runtime`. Aucun paquet système n’a été remplacé. Si le traitement est indisponible, l’envoi vidéo échoue avec un message explicite.

## Chaînes et plafonds

La référence V1 est illimitée, avec récompense du seul prestataire : 10 PS par validation, plafond de 30 PS par maillon et 100 PS par membre dans une chaîne, auxquels s’ajoutent les plafonds mensuels de la version Points Services associée (30 PS de chaînes et 300 PS d’engagement dans la référence initiale).

La chaîne conserve ses deux versions de barème. Les alternatives autorisées sont une longueur limitée, les N derniers prestataires (N ≤ 10), ou tous les prestataires d’une chaîne limitée. La simulation calcule une borne d’émission par validation et pour 100 validations. Publier exige cette simulation inchangée et une date future. Un retour à un ancien barème crée un nouveau brouillon à simuler/publier ; il ne réécrit aucune chaîne existante.

Le jeton d’invitation est affiché une fois, stocké seulement sous forme SHA-256 et expire après 7 jours. Le membre transmet lui-même le lien ; aucune coordonnée de tiers n’est demandée. L’ouverture stocke l’identifiant interne dans la session signée puis retire le jeton de l’URL avant la confirmation. Le retour après connexion conserve cette invitation. Les pages concernées sont privées, sans cache ni référent.

Une chaîne n’a qu’une invitation en attente. Une personne ne peut ni s’auto-valider ni revenir dans une chaîne déjà parcourue. Le bénéficiaire confirme le service reçu en connaissance des récompenses ; confirmation, récompenses et notifications sont atomiques. Atteindre un plafond n’empêche pas le relais : une ligne historique de récompense à zéro est conservée. Les services confirmés, les récompenses et les contrats sont protégés en base. Le contact de médiation référence la chaîne ; l’équipe peut suspendre sa progression en la passant en litige.

## Stripe reste dormant

`financial_support_enabled` est absent ou `false` par défaut ; les seeds ne réactivent jamais un flag existant. Aucun script Stripe, bouton membre ni paiement ne se charge dans cet état. Le webhook répond 404 et les routes membre ne reconnaissent pas le parcours.

Préparation avant activation :

- `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET` et `APP_URL` avec une origine HTTPS sans chemin.
- `FINANCIAL_SUPPORT_READY=1` après recette du compte Stripe et validation des informations comptables et contractuelles.
- Super-admin récemment réauthentifié, motif et case de validations explicite dans `/admin/soutien`.

Checkout fonctionne en paiement ponctuel EUR, de 1 à 1 000 €. Une référence locale et une clé d’idempotence persistante identifient chaque demande. Une réponse perdue peut être reprise avec la même clé ; une tentative non résolue de plus de 23 heures exige un rapprochement pour éviter un nouveau paiement après expiration de l’idempotence Stripe. Le retour navigateur ne crédite jamais le statut payé.

Événements utilisés : `checkout.session.completed`, `checkout.session.async_payment_succeeded`, `checkout.session.async_payment_failed`, `checkout.session.expired`, `charge.refunded`. La signature est vérifiée sur le corps brut ; identifiants, montant, devise et référence locale sont contrôlés. Les événements sont dédupliqués et immuables. Les remboursements reçus avant la confirmation restent rapprochables grâce à leurs seuls identifiants et montants ; aucun payload Stripe contenant des données personnelles n’est conservé. Les événements tardifs ne font pas régresser un remboursement.

Le remboursement administratif est intégral, réservé au super-admin, motivé et idempotent. Un remboursement en attente ne devient pas fictivement terminé. Le rapprochement relit la session, le PaymentIntent et sa charge ; les remboursements partiels effectués côté Stripe sont reflétés. Une réponse de création perdue sans identifiant de session connu doit être retrouvée côté Stripe grâce à la référence locale avant une nouvelle tentative. Désactiver le flag bloque aussi le webhook ; les paiements déjà ouverts restent à rapprocher depuis l’administration.

Aucune de ces opérations n’écrit dans les comptes PS, les niveaux, les événements Trust ou les demandes Top. Aucun reçu fiscal ni contrepartie n’est promis. Aucun paiement réel ni activation de compte Stripe n’a été effectué pour cette livraison.

Références d’intégration : [Checkout Sessions](https://docs.stripe.com/api/checkout/sessions), [vérification des signatures](https://docs.stripe.com/webhooks/signature), [idempotence](https://docs.stripe.com/api/idempotent_requests), [remboursements](https://docs.stripe.com/api/refunds/create?lang=ruby).

## Vérification

Recette finale : **230 exemples RSpec, aucun échec** (seed `44022`), couverture **99,62 % des lignes / 93,66 % des branches**. RuboCop : aucune offense ; Brakeman : aucune alerte et aucune erreur. Chargement Zeitwerk et concurrence SQLite validés. Les seeds exécutées deux fois conservent neuf quêtes, un barème, zéro opération PS et le soutien désactivé.

Les tests couvrent notamment une chaîne de 12 maillons, les limites et profondeurs, les jetons expirés/rejoués, auto-validation/boucle/branche, le gel historique, les plafonds, les preuves mensuelles, refus/réexamen, consentement/retrait, Top expiré, vidéo réellement transcodée et droits médias, signatures Stripe, événements rejoués, échec/remboursement et absence de PS.

`bin/check-exchange-concurrency` utilise une base temporaire isolée et vérifie également deux bénéficiaires concurrents et deux invitations concurrentes. Les tests navigateur vérifient les nouvelles pages en 375 et 1440 pixels et leur accessibilité ; les références visuelles existantes restent inchangées.

Après mise à jour : `bundle install`, `bin/rails db:migrate`, `bin/rails db:seed`, `yarn build`, puis redémarrer `bin/dev`. Les seeds sont idempotents et ne créent aucun soutien financier ni récompense.
