# Parrainage par lien personnel permanent

Cette évolution remplace l’émission de codes jetables dans l’espace utilisateur. Les historiques et les anciens codes déjà transmis restent compatibles ; aucune génération de nouveaux codes jetables n’est proposée dans l’interface.

## Parcours

- Un membre actif dont l’e-mail est confirmé et dont l’ancienneté atteint le réglage courant peut créer son lien. Aucun échange préalable n’est nécessaire.
- Un propriétaire possède un seul lien aléatoire, réaffichable et copiable. Le lien ne possède ni date d’expiration ni quota de filleuls.
- Ouvrir `/parrainage/:token` conserve l’invitation en session et conduit à l’inscription. Le dernier lien valide ouvert avant l’inscription est retenu. Un compte déjà connecté ne change pas de parrain par ce mécanisme.
- À l’inscription, le lien est conservé en base sur le compte non confirmé. Une erreur du formulaire n’efface pas l’invitation. La confirmation de l’e-mail crée le parrainage, même si elle intervient depuis un autre appareil.
- Un filleul inscrit par lien a un seul parrain rattaché ; l’auto-parrainage, les doublons et le remplacement par un autre lien sont refusés. Les anciens soutiens multiples restent conservés pour la compatibilité du calcul de confiance.
- Si le propriétaire ne remplit plus les conditions (suspension, changement d’ancienneté…), le lien reste stable mais ne permet plus de nouvelles attributions tant que l’éligibilité n’est pas retrouvée. Les comptes confirmés dont l’invitation est encore en attente sont réexaminés par la maintenance.

## Réglages super-admin

Dans **Studio admin → Confiance et recours → Réglages du parrainage**, l’ancienneté minimale est modifiable entre 0 et 36 500 jours (30 par défaut). La valeur est utilisée directement par le contrôle serveur et le message de l’espace utilisateur. L’enregistrement exige le rôle super-admin et crée une trace d’audit. Une exemption administrative temporaire contourne l’ancienneté, mais jamais l’exigence de compte actif et d’e-mail confirmé.

## Suivi et récompenses

Le parrain retrouve le nombre total d’inscriptions confirmées, les parrainages qualifiés et une liste paginée de tous ses filleuls avec leurs états. Les noms affichés sont les pseudonymes publics ; les e-mails restent privés. Les objections sous 72 heures et la revue administrative sont conservées.

Le nombre de filleuls est illimité. Pour les nouveaux liens, chaque filleul qualifié peut déclencher **15 PS une seule fois par parrainage**, au lieu d’une seule récompense pour toute la vie du parrain. Le filleul doit toujours avoir 30 jours et deux partenaires distincts hors de ses parrains. Cette durée de qualification de récompense est distincte de l’ancienneté configurable pour pouvoir parrainer.

Le plafond mensuel global de récompenses du barème Points Services reste applicable. Les récompenses différées sont réexaminées par les tâches existantes. Les historiques issus de codes conservent leur ancienne règle de récompense unique, sans recrédit rétroactif. Le plafond de dix soutiens pris en compte par le Trust Score concerne les soutiens reçus, pas le nombre de filleuls.

## Technique et exploitation

Migration `20260912180000_add_permanent_referral_links` : tables `referral_links`, `referral_settings`, origine de parrainage par lien et invitation en attente sur `users`. Index uniques sur le propriétaire, le jeton et le filleul rattaché par lien. Pas de suppression des données historiques.

Déployer la migration et relancer l’application avec les nouveaux assets. `TrustMaintenanceJob` et `PointMaintenanceJob` doivent être exécutés par les workers pour la qualification différée et les crédits. Leur configuration horaire existante est conservée ; ce changement ne constitue pas une vérification des workers de production.

Tests dédiés : `spec/requests/referral_links_spec.rb`, `spec/system/referral_links_spec.rb`, plus les suites historiques confiance, points et authentification.
