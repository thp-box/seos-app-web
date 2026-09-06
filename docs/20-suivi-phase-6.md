# Phase 6 — Organisations, Voyage solidaire et partenariats

Implémentation du 5 septembre 2026, selon F-060 à F-062 du [plan de construction](10-plan-construction-feature-par-feature.md).

## Parcours disponibles

| Entrée | Fonction |
| --- | --- |
| `/compte/organisations` | Demander un espace, retrouver ses organisations, préparer un profil et accéder à son équipe |
| `/compte/organisations/:slug` | Modifier la présentation, voir son aperçu, inviter, gérer les rôles et préparer missions et partenariats |
| `/associations` et `/associations/:slug` | Annuaire et fiches publiques des associations vérifiées dont la présentation est publiée |
| `/voyage-solidaire` et `/voyage-solidaire/:slug` | Catalogue filtrable par pays, conditions des missions et formulaire de candidature |
| `/compte/candidatures` | Candidatures du membre et celles confiées à ses équipes ; décisions et conversations privées |
| `/partenaires` et `/partenaires/:slug` | Partenariats publiés dans leur période de validité |
| `/admin/organisations` | Revue des organisations, données légales sur révélation, missions, partenariats et réglages globaux |

L’ancien espace `/organisations/:slug/espace` reste disponible et renvoie vers la nouvelle gestion. Les pages utilisent les composants existants ; la navigation d’espace se replie sur mobile.

## F-060 — Organisation et équipe

La création fait une demande `pending` avec un propriétaire, dans une seule transaction. Nom, slug et type sont contrôlés. La présentation et le logo sont distincts de l’identité légale : dénomination, numéro d’enregistrement et e-mail légal sont chiffrés et filtrés dans les logs.

Le propriétaire peut modifier l’identité légale. Les autres membres n’en reçoivent pas les champs dans leur formulaire ou leur aperçu. Une modification de l’identité remet la structure en attente de vérification ; une modification éditoriale retire seulement la publication de sa fiche pour nouvelle revue. L’administration vérifie une identité complète, une présentation et la présence d’un propriétaire actif avant publication.

Règle d’équipe choisie : **plusieurs propriétaires sont autorisés, mais le dernier ne peut pas être retiré**. Cette garantie existe dans le service et en SQLite, y compris lors de deux changements concurrents.

- Propriétaire : profil, identité légale, invitations d’éditeurs/responsables et changements de rôles, dont désignation d’un autre propriétaire.
- Responsable : gestion des éditeurs, invitations d’éditeurs, candidatures et conversations ; aucun accès à l’identité légale.
- Éditeur : préparation des contenus de sa structure vérifiée ; aucune gestion d’équipe ni lecture des candidatures.
- Super-admin : récupération motivée d’un propriétaire et changement exceptionnel de type ; pas d’accès implicite à l’espace membre d’une organisation sans membership.

Une invitation est liée à l’e-mail exact du compte destinataire, chiffré en base. Son jeton aléatoire n’est conservé que sous forme SHA-256 et expire après sept jours. L’émetteur copie et transmet lui-même le lien ; aucun e-mail à un tiers n’est envoyé par cette action. Le lien est retiré de l’URL avant connexion et l’identifiant d’invitation est conservé dans la session signée. L’acceptation vérifie la confirmation du compte, le destinataire, l’expiration, la révocation et les droits actuels de l’émetteur. Un rejeu ne crée pas un second accès et ne rétrograde pas un membre déjà actif.

L’administration peut vérifier, refuser, suspendre et rétablir une organisation. La suspension masque ses publications et ses médias publics, coupe son espace de gestion et la progression des candidatures. Le candidat conserve la lecture de son propre historique. Les actes sont conservés dans le journal d’audit. La révélation de l’identité légale nécessite `organizations.legal`, une réauthentification récente et un motif ; le journal correspondant n’est pas affiché sans cette permission.

## F-061 — Missions et candidatures

Une association vérifiée peut préparer une mission, ses photos et ses conditions : pays, région/localisation publique, adresse privée, dates, durée minimale, langues, hébergement, repas, heures d’aide, jours libres, capacité et contribution quotidienne.

La contribution se saisit en euros, est stockée en centimes et reste comprise entre **0 et 1 500 centimes par jour**, avec validation du modèle et contrainte SQLite. Aucun règlement n’est collecté par le parcours. Les photos passent par `SafeImage` : six images maximum, format réellement vérifié et métadonnées supprimées.

La soumission passe par `pending_review`. **Seul le super-admin avec `missions.manage` peut créer depuis l’administration puis publier une annonce monde au nom d’une association vérifiée.** L’association ne peut pas contourner cette règle en postant un statut. Un admin délégué peut modérer, mettre en pause ou archiver ; il ne peut pas publier. Une modification de mission repasse par un brouillon.

Les dates doivent être cohérentes et permettre le séjour minimal. La publication refuse une mission terminée. Une candidature nécessite un compte actif confirmé, des dates dans la mission et un séjour assez long. Un membre de l’équipe ne peut pas candidater à sa propre mission. L’unicité `[mission, membre]` bloque le doublon ; les dossiers retirés/refusés restent conservés et ne sont pas remplacés par une nouvelle soumission.

Les responsables acceptent/refusent avec motif ; le candidat peut se retirer. L’acceptation réserve une place pour les dates demandées. La capacité est calculée par intervalles : des séjours consécutifs ne consomment pas deux places simultanées. Le verrou de mission protège les acceptations concurrentes. Tant que des dossiers sont en attente ou acceptés, les conditions du séjour ne peuvent pas être changées ; le titre et la présentation restent éditables avec nouvelle revue.

La conversation est propre à `MissionApplication`, sans détourner les messages d’échanges locaux. Elle est chiffrée, limitée au candidat et aux propriétaires/responsables actifs, et ses livraisons sont idempotentes. Un dossier fermé, une mission masquée ou une structure suspendue bloque les nouveaux messages. Le contrat de candidature et les messages sont protégés en base contre les réécritures.

L’adresse précise n’est présente ni dans la fiche publique ni dans le dossier en attente. Elle est communiquée dans le dossier accepté lorsque la mission est encore disponible ; le formulaire de l’association annonce explicitement ce partage après acceptation. Les notifications restent génériques et ne contiennent ni motivation, ni adresse, ni contenu de conversation.

## F-062 — Partenariats

Le partenariat est une ressource distincte : une association peut être partenaire sans changer de type. Les types autorisés sont institutionnel, opérationnel, technique et soutien. Leur sélection administrative est réservée au super-admin ; la proposition d’un membre commence comme partenariat opérationnel.

Le membre habilité prépare titre, texte, logo, période et lien facultatif, puis consulte l’aperçu et soumet à revue. Une modification retire la publication et crée un état brouillon à revoir. L’administration habilitée gère contenu, ordre, dates, publication et archive. Publier exige une organisation vérifiée, une période cohérente non terminée et une présentation complète.

L’annuaire filtre les périodes et l’ordre avant présentation ; brouillons, archives et périodes futures/expirées sont invisibles. Le logo utilise le même traitement d’image et la même autorisation de média que les autres contenus. Les liens acceptent uniquement HTTPS sans identifiant/mot de passe ; aucun chargement automatique de la destination n’est ajouté et les liens portent `noopener noreferrer`.

Un partenariat ne donne aucun accès aux membres privés, exports, candidatures d’autres organisations, conversations ou outils d’administration. Ces parcours ne créent aucun Point Service, événement Trust ou avantage de niveau.

## Permissions et flags

Nouvelles permissions : `organizations.read`, `organizations.manage`, `organizations.legal`, `missions.manage`, `partnerships.manage`. Elles s’ajoutent aux permissions existantes et restent soumises au contrôle d’administration et à la réauthentification récente.

`voyage_enabled` et `partnerships_enabled` sont actifs par défaut. Le super-admin peut les désactiver avec un motif depuis `/admin/organisations`. Leurs pages publiques et médias deviennent alors indisponibles ; publication et progression des candidatures sont contrôlées côté serveur. Les espaces privés et historiques restent accessibles selon leurs droits. Le flag Stripe de phase 5 conserve son état indépendant et reste désactivé dans les seeds.

## Démonstration et démarrage

Les trois comptes de démonstration existants sont conservés. Pour `association@seos.test`, les seeds préparent la présentation de l’association, une mission **en brouillon** « Participer au jardin solidaire » et un partenariat **en brouillon**. Aucune mission monde n’est publiée par les seeds ; utiliser `superadmin@seos.test` dans `/admin/organisations` pour effectuer la revue.

Après récupération du code : `bin/rails db:migrate`, `bin/rails db:seed`, `yarn build`, puis redémarrer `bin/dev`. Les seeds sont idempotents et ne réactivent pas un flag préexistant.

## Vérification

Suite complète : **250 exemples RSpec, aucun échec** (seed `66026`), couverture **99,60 % des lignes / 92,55 % des branches**. Les contrôles RuboCop, Brakeman et Zeitwerk sont également exécutés. Les seeds ont été exécutées deux fois sans doublon : un brouillon de mission, un brouillon de partenariat, zéro opération PS et Stripe toujours désactivé.

Les specs couvrent les rôles, l’identité légale privée, le retour d’invitation après connexion, l’expiration et le rejeu, le dernier propriétaire, les bornes monétaires et dates, les candidatures en doublon, la capacité, les conversations, les flags, les liens externes, les médias privés/publiés/suspendus et la publication exclusive du super-admin.

`bin/check-exchange-concurrency` utilise une base SQLite temporaire : dernier propriétaire conservé lors de deux rétrogradations, une seule acceptation pour une place restante, message et acceptation d’invitation uniques. Les nouvelles pages membre/public/admin sont vérifiées en navigateur à 375 et 1440 pixels avec axe. Les références visuelles préexistantes ne sont pas remplacées.
