# Phase 4 — Points Services

Livraison du 5 septembre 2026, couvrant le registre, les transferts, les récompenses et le pilotage des barèmes F-040 à F-043 du [plan](10-plan-construction-feature-par-feature.md).

## Parcours

- `/compte/points` : solde et historique personnels paginés, validation de la quête d’accueil, dépôt de preuves, décisions motivées.
- Échange privé : montant, rôle réel de payeur/bénéficiaire, solde personnel prévisionnel et confirmation explicite de la réalisation **et du transfert**. Le bouton du payeur est désactivé si son solde ne couvre pas le montant.
- `/points-services` : explication publique, estimation indicative en centimes, récompenses Bronze/Argent/Gold et plafonds du barème applicable. L’assistant de publication donne accès à ce repère.
- `/admin/points` : registre, aperçus d’ajustements, validation de preuves et versions des règles selon permissions dédiées.

## F-040 — Registre en partie double

`point_accounts` contient un compte individuel par membre et un compte système unique sans membre. Aucun compte d’association ou de partenaire n’est créé. Un compte membre part de zéro et ne peut jamais être négatif ; le compte système porte la contrepartie des émissions/retraits de récompenses.

Une `point_operation` passe de `pending` à `committed` dans une transaction contenant exactement deux `point_entries`, avec somme nulle. Les écritures portent montant signé et solde après opération. Les montants sont des entiers positifs de 1 à 999 999 PS pour l’opération ; les écritures sont signées. Les soldes restent dans les bornes d’entiers SQLite définies par le schéma.

Les triggers SQL vérifient le solde résultant, mettent à jour le compte depuis l’écriture, interdisent une modification directe du solde, bloquent un ajout à une opération validée et refusent une validation non équilibrée. Écritures et opérations validées sont immuables en Rails et SQL. Le schéma canonique reste `db/structure.sql`.

L’unicité de la clé d’idempotence, les transactions immédiates SQLite et l’ordre stable des comptes protègent des doubles clics, jobs rejoués et dépenses concurrentes. Un rejeu de la même opération retrouve l’écriture initiale ; une clé réutilisée pour un autre montant, sens, source ou barème est refusée.

La correction est une opération inverse liée, unique, avec motif et audit. Elle exige le super-admin et `points.adjust`. Une inversion d’inverse est refusée. Si le bénéficiaire a déjà dépensé les points, la compensation est bloquée par la protection contre le découvert ; une médiation doit alors régler le financement explicitement, sans effacement du registre.

## F-041 — Transfert d’un échange

La proposition d’accord fige dans son contenu chiffré le mode d’échange, le montant entier, les deux comptes humains concernés et la version de valorisation indicative. Pour une offre, le répondant paie l’auteur ; pour une demande, l’auteur paie le répondant qui rend effectivement le service. Les noms techniques `requester` et `provider` ne déterminent donc pas seuls le sens du transfert.

Une modification ultérieure de l’annonce ne change pas cet accord. Toute nouvelle proposition demande à nouveau l’acceptation des deux membres. Chaque confirmation en points doit viser la version actuelle de l’accord. La seconde réalisation confirmée et le débit/crédit sont dans la même transaction : insuffisance de solde, blocage ou litige ouvert empêchent la seconde confirmation et toutes les écritures associées.

Un transfert possède la clé `transfer:<échange>`. La seconde confirmation rejouée ne paie pas deux fois. Les administrateurs ne disposent pas d’un bouton pour confirmer à la place des participants. Le donneur ou le troqueur ne déclenche aucun transfert.

Les accords historiques contenant un montant mais pas de destinataires/version figés doivent être renégociés avant leur confirmation. Les échanges déjà terminés avant cette livraison ne reçoivent pas de transfert rétroactif. Une compensation financière conserve l’échange réalisé et ne modifie pas automatiquement le Trust Score ni les récompenses historiques : une correction de ces sources exige une décision distincte.

## F-042 — Récompenses et ajustements

La référence V1 est inscrite dans `PointRuleVersion::DEFAULT_ENGAGEMENT` :

| Source | Récompense | Unicité / preuve |
|---|---:|---|
| Accueil | 30 PS | Une fois ; action explicite après e-mail confirmé et profil publié |
| Annonce publiée | 10 PS | Une fois par annonce, publiquement admissible ; barème applicable à la date de publication |
| Trois réponses | 10 PS | Une fois ; demandes acceptées par trois membres distincts |
| Parrain principal | 15 PS | Une seule quête sur la vie du parrain ; qualification F-030 revérifiée |
| Série de cinq transferts | 20 / 25 / 30 PS | Bronze / Argent / Gold ; chaque transfert consommé une fois |
| Témoignage écrit | 10 / 15 / 20 PS | Une fois ; preuve et revue humaine |
| Témoignage vidéo | 20 / 25 / 30 PS | Une fois ; référence à une preuve et revue humaine |
| Partage de SEOS | 10 PS | Une fois par mois ; preuve et revue humaine |
| Chaîne | 10 PS | Pont de validation humaine, une preuve mensuelle ; plafond chaîne V1 : 30 PS/mois |

Le plafond général V1 est de 300 PS de récompenses par mois. Les transferts entre membres et ajustements ne sont pas des récompenses mensuelles. Les récompenses automatiques dépassant le plafond attendent un prochain passage ; les crédits précédents ne sont pas annulés. Une validation manuelle dépassant le plafond laisse sa preuve en attente avec une erreur explicite.

Le parrainage ne crédite jamais le filleul. Le principal reçoit 15 PS indépendamment du niveau, conformément à F-030 qui précise la maquette. Une invalidation ultérieure n’efface pas une écriture déjà validée ; elle peut justifier une compensation après revue.

Les seuils initiaux de niveau sont **5 transferts valides pour Argent, 20 pour Gold**, configurables par version. Une série commencée garde sa version ; son niveau est calculé avec les transferts existants à la fin de cette série, même si le worker rattrape plusieurs séries d’un coup. Les transferts compensés ne comptent pas dans une progression encore ouverte. Ni le solde, ni les récompenses, ni le niveau ne sont ajoutés au moteur Trust.

Les preuves sont chiffrées et privées ; le montant, la période, le niveau et le barème sont figés au dépôt. L’équipe disposant de `points.rewards` peut approuver ou refuser avec motif, mais ne peut pas valider sa propre preuve. Les index rendent impossible une seconde attribution de la même quête/période. Une preuve examinée n’est pas modifiable silencieusement.

Le parcours complet des témoignages, succès et chaînes appartient à F-050/F-052, en phase 5. Cette livraison fournit le versement après revue et les plafonds ; elle ne prétend pas créer les maillons, invitations, graphes de chaînes ou hébergement vidéo de cette phase suivante. Le membre fournit actuellement du texte et des références de preuve, pas un fichier vidéo téléversé.

Un ajustement manuel commence par un aperçu chiffré : solde actuel → solde résultant, auteur, motif, expiration après dix minutes. Toute modification du solde entre aperçu et exécution impose un nouvel aperçu. Jusqu’à 100 PS en valeur absolue, le proposant habilité ou un super-admin valide ; au-delà, un autre super-admin doit valider. Ces seuils de contrôle sont fixes dans cette livraison. Les paramètres de l’aperçu sont immuables en SQL ; la requête de confirmation ne peut pas remplacer le montant.

## F-043 — Barèmes versionnés

La table `point_rule_versions` distingue les familles `valuation` et `engagement`, plutôt que deux tables duplicatives. Ses configurations JSON sont validées par schéma fermé : entiers bornés, clés autorisées, trois niveaux connus, tranches contiguës. Aucune expression, script ou formule fournie par un administrateur n’est exécuté.

Les bornes en centimes sont inclusives : 0–2000 → 10 PS, 2001–4000 → 20 PS, 8001–10000 → 50 PS. La référence comporte cent tranches, jusqu’à 2000 € de valeur indicative. Une tranche peut proposer une plage de points. Le repère ne fixe pas le montant négocié et ne permet aucune conversion de monnaie.

Cycle : brouillon → simulation → publication datée. La simulation parcourt les limites de chaque tranche ou calcule les récompenses et plafonds ; elle conserve la configuration précédente pour comparaison. Son empreinte couvre famille, configuration et date d’effet. Une modification après simulation oblige à simuler à nouveau.

`points.rules` permet la consultation et la simulation ; création, publication, planification et retour de version exigent aussi le super-admin. Les versions publiées sont immuables, même par SQL. La version applicable est la dernière publiée dont la date d’effet est atteinte. Un index unique interdit deux publications d’une famille à la même date. Les versions futures ne prennent pas effet immédiatement.

Un rollback crée, simule et publie une nouvelle version reprenant l’ancienne configuration, applicable une minute plus tard ; aucune ancienne ligne n’est modifiée. Les opérations, preuves de quêtes et progressions commencées conservent leurs références historiques. Les changements de règle ne réécrivent pas les montants déjà gagnés.

## Exploitation et sécurité

Les seeds installent une référence V1 publiée, validée dans le code et les tests, pour chacune des deux familles ainsi que le compte système à zéro. C’est le bootstrap du registre ; les évolutions suivantes passent par le cycle administratif audité. Une seed répétée ne remplace aucune version existante et ne crédite aucun utilisateur.

Après déploiement local : migrations, seeds, build, redémarrage du serveur et du worker. Les événements d’annonce, d’échange et de qualification planifient `PointRewardsJob`. `PointMaintenanceJob` est programmé chaque heure pour rattrapage et changement de mois. Passage local explicite :

```sh
bin/rails runner 'PointMaintenanceJob.perform_now'
```

Le registre envoie les notifications par le système existant. Le portefeuille affiche le montant, le solde après opération et le motif. Les pages privées répondent `no-store` et `noindex` ; aucun solde ne sort sur le profil ou le JSON-LD. Le journal général masque les événements `points.*` sans `points.read`, même si l’administrateur possède `audit.read`.

Aucun endpoint d’achat, vente, retrait, conversion, paiement Stripe ou avantage de soutien financier n’a été ajouté. Les comptes d’organisations restent hors périmètre tant qu’une décision produit ne les autorise pas.

## Vérification

Les tests couvrent contraintes SQL, idempotence, insuffisance, sens réel du service, accords modifiés, litiges, compensations, droits, preuves, barèmes et niveaux. `bin/check-exchange-concurrency` utilise une base temporaire isolée pour vérifier aussi deux dépenses sur le même solde, un crédit concurrent rejoué et deux publications de même date.

Le test navigateur vérifie le parcours accueil → portefeuille → preuve, les estimations publiques, le débordement à 375/1440 px, axe WCAG et la console JavaScript. Captures : `tmp/screenshots/points-wallet-375.png` et `points-wallet-1440.png`.

Suite complète finale : **205 exemples, aucun échec**, seed `44022`, couverture **99,83 % des lignes** (1862/1865) et **94,43 % des branches** (814/862). Rapport JUnit : `tmp/rspec-phase-4.xml`. Les captures mobile/bureau ont été examinées ; aucune baseline existante n’a été remplacée.

RuboCop sans anomalie, Brakeman sans avertissement de sécurité, liens locaux et `git diff --check` vérifiés. Migrations appliquées, seed répétée sans changement ni crédit, compilation des assets en mode production réussie. Le test isolé couvre également les deux confirmations simultanées d’un véritable accord en points avec un seul transfert. Aucun déploiement effectué ; le build de développement est restauré après vérification.
