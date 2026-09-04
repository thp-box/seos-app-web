# Système de Trust Score SEOS

## Positionnement

Le Trust Score aide un membre à estimer si une collaboration semble suffisamment documentée. Il ne certifie ni l'identité civile, ni l'absence de danger, ni la qualité future d'une personne.

La V1 ne demande pas de carte d'identité. Elle construit donc une confiance progressive à partir d'actions observables dans SEOS : échanges confirmés, respect des engagements, évaluations structurées, ancienneté, signaux de compte vérifiés, recours et décisions humaines.

Principes non négociables :

- un score global ne remplace jamais la confiance liée à une tâche précise ;
- un nouveau membre n'est pas présenté comme peu fiable : il possède simplement trop peu d'éléments ;
- aucun avis libre ne suffit à faire monter ou chuter fortement un score ;
- jusqu'à dix parrains distincts peuvent augmenter le score initial, sans remplacer les preuves issues des échanges ;
- un signal technique est un indice de revue, jamais une preuve automatique de fraude ;
- une restriction ayant un effet important ne repose pas uniquement sur l'algorithme ;
- formule, version, date, principaux facteurs et recours sont accessibles ;
- ni le solde de Points Services, ni le niveau Bronze/Argent/Gold, ni un soutien financier à SEOS n'améliorent directement le score.

## Deux systèmes séparés

### Indice de confiance public

Visible sur le profil de service et les annonces :

- score global sur 100 seulement lorsque les preuves sont suffisantes ;
- score provisoire possible dès l'inscription lorsqu'au moins un code valide, provisoire ou confirmé, est présenté comme tel ;
- scores par catégorie de tâche lorsqu'ils sont eux-mêmes suffisamment documentés ;
- dimensions principales : fiabilité, qualité de la tâche, respect/sécurité, communication et ponctualité ;
- nombre d'échanges confirmés et de partenaires indépendants ;
- niveau de confiance du calcul : données limitées, modérées ou solides ;
- date du dernier calcul et lien « Comprendre ce score ».

### Risque interne

Visible seulement par les personnes habilitées :

- signaux de comptes liés, activité artificielle, répétitions, réciprocité anormale ou contournement ;
- niveau de priorité pour une revue humaine ;
- éléments ayant déclenché la revue et durée de conservation ;
- décision humaine, action éventuelle et recours.

Le risque interne ne doit jamais être transformé en badge public « dangereux » ou en accusation. Il ne rentre dans le score public qu'après une décision humaine sur un fait pertinent, contestable et documenté.

## Preuves disponibles sans pièce d'identité

| Source | Ce qu'elle prouve réellement | Ce qu'elle ne prouve pas |
|---|---|---|
| E-mail vérifié | Contrôle d'une boîte à un instant | Identité civile, unicité de la personne |
| Téléphone vérifié facultatif | Contrôle d'un numéro | Propriété durable, identité légale |
| Ancienneté du compte | Durée d'existence sans suppression | Honnêteté future |
| Échange doublement confirmé | Interaction reconnue par les deux parties | Qualité parfaite ou absence de pression |
| Avis structuré | Expérience déclarée dans un contexte précis | Vérité absolue ou aptitude universelle |
| Code de parrainage valide | Un membre actif engage une part limitée de sa confiance, avec délai d'objection | Identité civile, compétence dans une tâche ou sécurité garantie |
| Appartenance à une organisation vérifiée | Relation déclarée/validée avec l'organisation | Identité civile complète du membre |
| Décision de médiation | Fait examiné selon la procédure interne | Jugement pénal ou vérité générale |

Les badges doivent reprendre ces formulations précises : « e-mail vérifié », « téléphone vérifié », « 12 échanges confirmés », jamais « identité vérifiée » en V1.

## Score global et scores par tâche

### Hiérarchie

1. **Score par sous-catégorie**, par exemple aide informatique → dépannage ordinateur.
2. **Score par catégorie**, par exemple aide informatique.
3. **Score global**, synthèse prudente de l'activité documentée.

Une bonne réputation en jardinage ne doit pas produire une forte réputation en garde d'enfants. En l'absence de preuves directes, la page affiche « Pas encore assez d'échanges dans cette catégorie ».

Un héritage depuis la catégorie parente peut être utilisé avec un poids maximal de `30 %`, clairement identifié comme expérience connexe. Les catégories sensibles peuvent interdire cet héritage.

### Dimensions V1

| Dimension | Poids global initial | Données principales |
|---|---:|---|
| Fiabilité / engagements | 30 % | confirmation, réalisation, annulation attribuée après revue, engagements |
| Qualité liée à la tâche | 25 % | critères propres à la catégorie, résultat déclaré |
| Respect et sécurité relationnelle | 20 % | respect des limites, comportement, médiation confirmée |
| Communication | 15 % | clarté, réponses, accord sur les modalités |
| Ponctualité / organisation | 10 % | présence, horaires, préparation ; « non applicable » autorisé |

Les quêtes, niveaux et Points Services restent extérieurs au calcul. Le parrainage possède en revanche un rôle particulier : jusqu'à dix soutiens distincts peuvent former un score global provisoire dès l'inscription. Leur poids de preuve cumulé est plafonné à `2,50` et devient proportionnellement plus faible dès que les échanges réels s'accumulent. Il ne crée jamais de score par catégorie de tâche.

Les poids varient par famille de tâches dans une version d'algorithme. Exemple : la ponctualité compte peu pour un dépannage asynchrone à distance et davantage pour un accompagnement planifié.

## Avis structuré après une tâche

### Conditions

- échange au statut `completed` ;
- auteur participant à l'échange ;
- une évaluation par auteur et par échange ;
- dépôt possible pendant 30 jours ;
- réponses cachées jusqu'à ce que les deux parties répondent ou pendant 14 jours maximum ;
- modification possible seulement avant révélation ; ensuite, ajout d'une réponse ou recours, pas réécriture silencieuse.

### Questions communes

1. Le service prévu a-t-il été réalisé ? `oui`, `partiellement`, `non`, avec raison.
2. Les engagements convenus ont-ils été respectés ? note 1–5.
3. La communication a-t-elle permis d'organiser l'échange ? note 1–5.
4. Les interactions ont-elles été respectueuses et les limites convenues respectées ? note 1–5.
5. La ponctualité/l'organisation étaient-elles satisfaisantes ? note 1–5 ou non applicable.
6. Confieriez-vous à nouveau une tâche comparable à cette personne ? `oui`, `peut-être`, `non`.

### Questions liées au rôle

Le demandeur évalue la qualité concrète, l'adéquation au besoin et le respect des consignes. Le prestataire évalue la clarté de la demande, l'accès aux éléments nécessaires, le respect de l'accord et la confirmation du service. Les deux formulaires ne doivent donc pas être artificiellement identiques.

### Questions liées à la catégorie

Une courte liste administrable complète le tronc commun : soin apporté au matériel, pédagogie, propreté du lieu, respect d'une consigne technique, etc. Deux ou trois critères maximum sont affichés pour éviter un questionnaire lourd.

Le texte libre demande : « Décrivez un fait utile aux prochains membres ». Les attaques personnelles, diagnostics, accusations non étayées, coordonnées et données sensibles sont interdits. Les tags proposés restent factuels : `à_l_heure`, `consignes_claires`, `travail_soigné`, `a_prévenu`, `besoin_incomplet`.

## Formule de référence V1

La formule ci-dessous est une base de travail testable, à simuler avant activation.

### 1. Normalisation

Chaque observation pertinente devient `xᵢ` dans `[0, 1]` :

- note 1–5 : `(note - 1) / 4` ;
- oui / peut-être / non : `1 / 0,5 / 0` ;
- service partiellement réalisé : valeur définie par la raison et confirmée par les parties ;
- annulation sans faute établie : aucune contribution négative ;
- incident confirmé après médiation : contribution ciblée, jamais baisse générale arbitraire.

### 2. Poids effectif

Pour une observation `i` :

```text
wᵢ = sourceᵢ × auteurᵢ × récenceᵢ × paireᵢ × contexteᵢ
```

- `sourceᵢ` : qualité de la preuve ; échange doublement confirmé `1,00`, avis structuré `0,80`, recommandation arrivée à maturité au plus `0,15`, décision de médiation jusqu'à `1,25`.
- `auteurᵢ` : poids borné entre `0,75` et `1,25`, selon ancienneté des preuves et qualité de participation ; jamais un multiplicateur extrême.
- `récenceᵢ` : `2 ^ (-âge_en_jours / 548)`, soit une demi-vie de 18 mois, avec plancher recommandé à `0,25` pour un échange confirmé non invalidé.
- `paireᵢ` : premier échange entre deux comptes `1,00`, deuxième `0,50`, troisième et suivants `0,20`, avec plafond cumulé par paire.
- `contexteᵢ` : facteur borné entre `0,80` et `1,20`, défini par catégorie et complexité, jamais directement par le nombre de points ou la richesse supposée.

Un seul auteur ou une seule paire ne peut représenter plus de `15 %` du poids public d'une dimension lorsque le profil possède assez d'autres preuves.

Un échange possède également un budget de poids maximal par personne : la double confirmation renseigne la fiabilité, puis chaque réponse renseigne sa dimension, sans compter plusieurs fois le même fait sous des noms différents. Ne pas déposer d'avis n'est jamais un signal négatif.

### 3. Estimation bayésienne

Pour une dimension, avec un a priori neutre `α₀ = 2` et `β₀ = 2` :

```text
α = α₀ + Σ(wᵢ × xᵢ)
β = β₀ + Σ(wᵢ × (1 - xᵢ))
score_dimension = arrondi(100 × α / (α + β))
poids_preuve = Σ(wᵢ)
confiance_calcul = 1 - exp(-poids_preuve / 8)
```

L'a priori évite qu'un unique avis parfait donne `100/100`. Le score reste caché tant que le poids et la diversité sont insuffisants.

Pour le score global uniquement, chaque code de parrainage valide au statut `provisional` ou `confirmed` ajoute une observation positive `x = 1` de poids `w = 0,25`. Les dix codes apportent donc au maximum `2,50` de poids de preuve. Leur présence ne modifie ni les dimensions ni les scores par tâche. Une objection invalide l'observation et déclenche un recalcul.

### 4. Seuils de publication

- aucun code de parrainage valide et moins de `3,0` de poids d'échange ou moins de 3 partenaires indépendants : « Nouveau profil — données insuffisantes », pas de note numérique globale ;
- au moins un code valide mais seuil d'échanges non atteint : score numérique marqué `provisoire`, source « basé sur N parrainages », sans score par tâche ;
- confiance du calcul `< 0,50` : données limitées ;
- de `0,50` à `< 0,80` : données modérées ;
- `≥ 0,80` : données solides.

Un score de catégorie exige au moins deux partenaires indépendants et un poids effectif de `2,0`; la page montre encore explicitement le faible échantillon. Les seuils seront ajustés par simulation et consignés dans la version d'algorithme.

Le niveau de confiance d'un score uniquement parrainé reste toujours « données limitées », y compris avec dix codes. Avec l'a priori `2/2` et des parrains de poids égal, les repères initiaux sont :

| Codes valides | Score provisoire indicatif | Poids de preuve parrainage |
|---:|---:|---:|
| 1 | 53/100 | 0,25 |
| 3 | 58/100 | 0,75 |
| 5 | 62/100 | 1,25 |
| 10 | 69/100 | 2,50 |

Ces valeurs ne sont pas des bonus ajoutés après le calcul : elles résultent de la même formule bayésienne. Dès que dix unités de poids proviennent d'échanges, les dix parrainages ne représentent plus que `20 %` du poids observé ; leur influence continue ensuite de décroître.

### 5. Agrégation

Le score de catégorie est la moyenne pondérée des dimensions applicables. Le score global utilise les poids de la table précédente, puis limite l'influence d'une seule catégorie à `60 %`. Une dimension non applicable est exclue et les poids restants sont renormalisés.

Le résultat public est un entier. L'application conserve davantage de précision pour recalculer, mais n'affiche jamais de faux niveau de précision comme `82,437/100`.

## Parrainage et confiance directe

### Code de parrainage

- un nouveau membre peut saisir de `0` à `10` codes appartenant à autant de parrains distincts ;
- les codes sont saisis pendant l'inscription ou pendant les sept premiers jours du compte ; passé ce délai, ils ne peuvent plus améliorer le score initial ;
- chaque code est aléatoire, à usage unique, limité dans le temps et stocké sous forme de condensat ;
- un parrain doit être actif, avoir vérifié son e-mail, avoir au moins 30 jours d'ancienneté et deux échanges confirmés avec deux membres distincts ; les membres fondateurs éventuels utilisent une exemption explicite et auditée ;
- un parrain ne peut maintenir que cinq codes non utilisés simultanément et chaque émission est limitée en rythme ;
- auto-parrainage, doublon de parrain, réutilisation de code et dépassement de dix codes sont interdits dans une transaction serveur ;
- le code utilisé produit immédiatement un soutien `provisional`; le parrain est notifié et peut signaler un usage non autorisé pendant 72 heures ; il devient ensuite `confirmed` ;
- un soutien retiré pour code volé ou fraude est invalidé et le score recalculé ; le comportement futur ordinaire du parrain ne punit pas automatiquement le filleul ;
- les identités des parrains ne sont pas publiques : seul leur nombre confirmé peut apparaître dans l'explication du score ;
- saisir un ou dix codes ne donne aucun Point Service au nouveau membre et ne débloque aucune fonctionnalité ; seul le score provisoire diffère ;
- un seul code est désigné `primary` pour l'éventuelle quête de parrainage de la maquette. Les neuf autres n'entraînent aucune récompense de quête, ce qui évite dix émissions de points pour une seule inscription ;
- le parrain principal reçoit `15 PS` une seule fois dans la vie de sa quête, conformément à la maquette, lorsque le nouveau membre a vérifié son e-mail, atteint 30 jours d'ancienneté et terminé deux échanges avec des membres qui ne font pas partie de ses parrains ;
- cette récompense passe par le registre de points et reste totalement séparée du Trust Score ; si le parrain a déjà terminé cette quête, le code conserve tout son poids Trust mais ne génère aucun point ;
- aucune donnée de contact du nouveau membre n'est visible aux parrains sans accord.

### Poids dans le score global

Les parrainages sont des preuves positives générales, pas des évaluations de compétence. Ils sont injectés dans la formule avec `x = 1`, `w = 0,25` par code provisoire/confirmé et un plafond de dix.

```text
W_parrainage = 0,25 × nombre_de_parrainages_valides
W_parrainage_max = 2,50
part_parrainage = W_parrainage / (W_parrainage + W_échanges)
```

Ainsi, ils constituent toute la preuve observable au départ, puis s'effacent graduellement sans changement brutal. Ils n'augmentent jamais `Aide informatique`, `Jardinage` ou une autre catégorie : seul le score global provisoire est concerné.

### Recommandation de compétence

Un membre peut déclarer « Je lui confierais une tâche dans [catégorie] » et préciser le contexte : déjà travaillé ensemble, connaissance personnelle ou simple recommandation. Cette déclaration :

- est publique seulement si les deux personnes acceptent le contexte affiché ;
- expire après 12 mois si elle n'est pas soutenue par une activité ;
- a une influence très faible et plafonnée ;
- ne compte pas si elle forme un groupe d'évaluations circulaires suspect ;
- peut être retirée sans effacer l'historique de calcul ;
- ne transmet pas automatiquement les problèmes du filleul au parrain, ni l'inverse.

Le graphe de parrainage sert surtout à détecter des structures anormales et à donner du contexte. Il ne devient pas un classement social récursif où les membres populaires contrôlent la réputation de tous.

## Défenses contre la manipulation

| Risque | Défense V1 |
|---|---|
| Faux comptes / Sybil | codes à usage unique, parrains éligibles, fenêtre de sept jours, limites d'émission, graphes et revue humaine |
| Ballot stuffing | avis seulement après échange, paire plafonnée, diversité minimale, aucun avis public libre |
| Bad-mouthing | avis double aveugle, poids borné, contestation, modération et analyse des écarts d'auteur |
| Représailles | révélation différée, fenêtre fixe, aucune modification après révélation |
| Collusion | graphe de réciprocité, cycles, groupes fermés, répétition de paires et rafales soumis à revue |
| Farming de micro-tâches | facteur de contexte borné, plafond par paire/catégorie/période, détection de cadence |
| Whitewashing | conservation minimisée des liens de sécurité autorisés, examen des réinscriptions, pas de fusion automatique |
| Compte compromis | alertes de session, réinitialisation, gel temporaire et invalidation ciblée après enquête |
| Chantage à la note | signalement confidentiel, double aveugle, texte factuel, sanction après revue |
| Manipulation par points/quêtes | solde, transferts, récompenses et niveaux totalement exclus de la formule Trust |

Les empreintes IP/appareil éventuelles sont pseudonymisées, limitées dans le temps et accessibles à peu de personnes. Un foyer, une association ou un réseau partagé peut produire un faux positif ; aucune sanction ne doit en découler seule.

## Événements positifs, neutres et négatifs

### Positifs

- échange doublement confirmé ;
- critères structurés satisfaisants ;
- plusieurs partenaires indépendants dans la même catégorie ;
- réponse constructive à une médiation, si elle correspond à un fait documenté.

### Neutres par défaut

- peu d'activité ou longue absence ;
- refus d'une demande ;
- annulation convenue ou due à un cas non imputable ;
- absence de téléphone vérifié ;
- refus de rendre son avatar public ;
- absence de parrain, qui laisse seulement le profil sans score provisoire ;
- localisation, âge, genre, origine, handicap, situation économique ou type d'appareil.

### Négatifs seulement après condition claire

- non-présentation reconnue ou établie après médiation ;
- engagements substantiels non respectés et confirmés ;
- incident de respect/sécurité traité par un humain ;
- fraude démontrée dans le système de points, de quêtes ou de parrainage.

Un signalement non résolu ne diminue jamais publiquement le score. Une mesure annulée en recours produit un événement correctif et un recalcul.

## Expérience publique

Exemple de carte, lorsque les éléments sont suffisants :

```text
Indice de confiance SEOS   82 / 100
Données du calcul          Modérées
Échanges confirmés         14 avec 11 membres
Aide informatique          88 · données solides
Jardinage                   Pas encore assez d'échanges
Points forts observés       Fiabilité · Communication
Mis à jour                  4 septembre 2026
```

Pour un nouveau membre parrainé, le composant affiche plutôt : `Score provisoire 62/100 · 5 codes valides, dont 3 confirmés · aucun échange confirmé · données limitées`. Le mot `provisoire` disparaît seulement lorsque le seuil d'échanges indépendants est atteint.

À proximité figurent : « Comment est-il calculé ? », « Voir les avis vérifiés » et « Signaler une erreur ». L'interface ne montre pas de classement général des personnes et ne compare pas deux membres comme des produits.

## Explication et recours

Le membre voit dans son espace :

- chaque dimension, catégorie, niveau de confiance et évolution ;
- les échanges/événements pris en compte ou plafonnés ;
- une explication simple des poids : récence, répétition de paire et contexte ;
- la version de formule et sa date d'activation ;
- les éléments non pris en compte et la raison ;
- un bouton de contestation.

Le recours suit : réception → vérification d'accès → attribution → revue humaine → correction ou maintien motivé → notification → recalcul. L'administrateur ne saisit pas directement une nouvelle note : il invalide une donnée erronée, corrige la source ou ajoute une décision documentée.

## Cycle de vie de l'algorithme

États : `draft` → `simulated` → `approved` → `shadow` → `active` → `retired`.

Avant activation :

1. documenter finalité, données, formule, seuils et personnes responsables ;
2. exécuter le calcul sur une copie contrôlée ou des données synthétiques ;
3. comparer ancien/nouveau score, nouveaux membres, catégories, zones et niveaux d'activité ;
4. inspecter les variations extrêmes et les recours historiques ;
5. valider l'analyse d'impact et les textes d'information ;
6. faire approuver la version par deux personnes pour une évolution importante ;
7. calculer en mode ombre avant bascule ;
8. conserver les snapshots et une procédure de retour.

Aucun poids ne doit être modifiable en direct dans un champ de production sans passer par ce cycle.

## Tests et suivi

### Tests du moteur

- score et confiance toujours bornés ;
- même jeu d'événements = même résultat ;
- ordre d'arrivée sans effet après tri/idempotence ;
- aucun double comptage d'une source ;
- répétition de paire et recommandation effectivement plafonnées ;
- zéro à dix codes acceptés, jamais onze, avec un parrain unique par code ;
- repères de score provisoire reproductibles pour 1, 3, 5 et 10 parrains ;
- un seul parrain principal éligible à une éventuelle récompense de quête ;
- absence de note numérique sous le seuil ;
- vieillissement prévisible et recalcul reproductible ;
- événement invalidé retiré puis snapshot conservé ;
- changement de version comparable et réversible.

### Simulations d'attaque

- 20 faux comptes autour d'un parrain et dix faux parrains autour d'un compte ;
- anneau de cinq membres se notant parfaitement ;
- alternance de notes positives réciproques ;
- attaque coordonnée de notes faibles ;
- série de tâches minuscules ;
- foyer légitime utilisant le même réseau ;
- nouvel arrivant excellent avec peu de preuves ;
- ancien membre inactif revenant sur une nouvelle catégorie.

### Indicateurs de qualité

- part des profils avec données insuffisantes, globalement et par catégorie ;
- délai médian pour obtenir un premier score publié ;
- concentration du poids par auteur, paire et groupe ;
- taux de recours, délai de réponse et part de décisions corrigées ;
- faux positifs des revues de risque ;
- corrélation entre score et litiges futurs, sans en faire une causalité ;
- distribution des scores et effets disproportionnés sur des cohortes, avec données minimisées ;
- stabilité des scores entre deux versions.

## Cadre RGPD et gouvernance

Le Trust Score concerne une personne identifiable et constitue un profilage. Avant lancement :

- documenter la base légale, la nécessité et la mise en balance ;
- réaliser une analyse d'impact, le scoring étant un critère de risque important ;
- expliquer catégories de données, logique générale, conséquences et durées ;
- permettre opposition/contestation selon la base et revue humaine ;
- éviter toute décision à effet important fondée exclusivement sur le calcul ;
- limiter destinataires, données techniques, exports et conservation ;
- contractualiser les éventuels prestataires et sécuriser les accès ;
- faire valider le dispositif et les textes par le référent juridique/DPO.

Le détail opérationnel figure dans [`09-rgpd-profils-publics.md`](./09-rgpd-profils-publics.md).

### SEO, GEO et conservation

Le Trust Score visible peut aider un visiteur à comprendre un profil depuis une annonce, mais il ne doit pas être transformé en `AggregateRating` Schema.org : il combine plusieurs signaux et n'est pas une moyenne d'étoiles. Le JSON-LD public n'expose ni événements Trust, ni parrains, ni niveau de risque. Le profil reste `noindex` au lancement, tandis que ses données publiques minimales peuvent être reliées à l'annonce indexable.

Les données Trust ne sont pas conservées « à vie » par défaut. La version de politique de conservation fixe une durée active, une éventuelle archive intermédiaire restreinte et une sortie par suppression, invalidation, dissociation ou anonymisation. Toute durée exacte reste subordonnée à l'AIPD et à la validation juridique/DPO.

## Références de conception

- [CNIL — Profilage et décision entièrement automatisée](https://www.cnil.fr/fr/profilage-et-decision-entierement-automatisee)
- [CNIL — Gérer les risques et réaliser une AIPD](https://www.cnil.fr/fr/gerer-les-risques)
- [PeerTrust — Supporting Reputation-Based Trust for Peer-to-Peer Electronic Communities](https://faculty.cc.gatech.edu/~lingliu/papers/2004/xiong04peertrust.pdf)
- [EigenTrust — Reputation Management in P2P Networks](https://nlp.stanford.edu/pubs/eigentrust.pdf)
- [The Illusion of the Cloak of Reciprocity](https://pmc.ncbi.nlm.nih.gov/articles/PMC5471239/)

Ces travaux inspirent la pondération par contexte, crédibilité bornée, historique et réciprocité. SEOS retient une formule plus explicable et plafonnée, sans reproduire un classement global récursif.
