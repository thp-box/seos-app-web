# Profils publics, vie privée et cadre RGPD/CNIL

## Statut du document

Ce document fixe une conception « protection des données dès la conception » pour SEOS. Il ne remplace pas l'avis d'un DPO ou d'un juriste. Bases légales, durées, textes d'information, contrats de sous-traitance et analyse d'impact doivent être validés avant mise en production.

## Décision produit

Un visiteur non connecté peut :

- ouvrir le profil de service public d'un membre ;
- voir ses annonces actives ;
- consulter son Trust Score global et par catégorie lorsque les preuves sont suffisantes ;
- voir le nombre d'échanges confirmés, des avis structurés publiés et des badges précis ;
- signaler un contenu ou être invité à se connecter pour contacter la personne.
- contacter l'équipe SEOS depuis une page Contact distincte.

Il ne peut jamais obtenir l'e-mail, le téléphone, l'adresse exacte, la géolocalisation précise, le nom civil complet, les messages, le solde de points, les signalements ou les évaluations de risque internes.

Il ne peut pas envoyer de question, demande ou message à propos d'une annonce. Toute action de contact avec l'annonceur exige un compte authentifié ; le formulaire public Contact ne crée qu'une demande adressée à l'équipe SEOS.

Le profil public est un profil de service, pas une fiche d'identité.

## Matrice de visibilité

| Donnée | Visiteur | Membre connecté | Participant à un échange | Admin habilité | Règle |
|---|---|---|---|---|---|
| Pseudonyme ou prénom + initiale | Oui | Oui | Oui | Oui | Valeur d'affichage dédiée |
| Nom civil complet | Non | Non par défaut | Seulement si partagé volontairement | Masqué, révélation motivée | Jamais dérivé automatiquement |
| Avatar | Si choix public | Si choix public | Oui si public | Oui | Facultatif, métadonnées retirées |
| Bio et compétences choisies | Oui | Oui | Oui | Oui | Modérables, avertissement anti-coordonnées |
| Commune/zone large | Oui | Oui | Oui | Oui | Jamais latitude/longitude exacte |
| Adresse exacte | Non | Non | Partage ponctuel après accord | Masquée, accès motivé | Absente du HTML/JSON public |
| E-mail | Non | Non | Partage volontaire hors affichage public | Masqué, accès motivé | Identifiant de compte privé |
| Téléphone | Non | Non | Partage volontaire par échange | Masqué, accès motivé | Pas d'option « public » en V1 |
| Ancienneté mois/année | Oui | Oui | Oui | Oui | Pas de date de naissance déduite |
| Annonces actives | Oui | Oui | Oui | Oui | Lien principal du profil public |
| Anciennes annonces | Agrégat éventuel | Selon politique | Selon échange | Oui | Pas de détails devenus inutiles |
| Échanges confirmés | Nombre agrégé | Nombre agrégé | Échange commun détaillé | Oui | Identité de l'autre partie non exposée |
| Avis structurés publiés | Oui | Oui | Oui | Oui | Texte modéré et données tierces retirées |
| Trust Score public | Oui | Oui | Oui | Oui | Score, confiance du calcul, date, méthode |
| Signaux de risque | Non | Non | Non | Cellule restreinte | Ne jamais rendre public |
| Solde/historique de points | Non | Propriétaire | Opération commune limitée | Permission points | Jamais sur le profil public |
| Favoris | Non | Propriétaire | Non | Accès exceptionnel | Privés par défaut |
| Messages | Non | Participants | Conversation commune | Révélation motivée | Pas d'extrait dans les listes admin |
| Signalements/décisions | Non | Auteur/cible selon procédure | Selon procédure | Modération | Pas d'accusation publique |
| Nombre de parrainages valides/confirmés | Oui dans l'explication Trust | Oui | Oui | Permission Trust | Nombres/statut seulement, jamais les identités publiques |
| Identité parrain/filleul | Non | Parties concernées | Non | Permission Trust | Relation privée, contexte public seulement avec accord distinct |
| IP/appareil/session | Non | Sessions propres limitées | Non | Sécurité restreinte | Pseudonymisé et durée courte |

## Profil public minimal et utile

### En-tête

- `display_name` ;
- avatar facultatif ou illustration neutre ;
- zone approximative ;
- « Membre depuis septembre 2026 » ;
- badges littéraux : e-mail vérifié, téléphone vérifié facultatif, organisation vérifiée le cas échéant.

### Confiance

- indice public et état « données insuffisantes » si nécessaire ;
- niveau de confiance du calcul, nombre d'échanges et partenaires distincts ;
- dimensions et catégories suffisamment documentées ;
- date/version, explication et contestation.

### Activité

- annonces actives ;
- catégories pratiquées ;
- avis factuels publiés ;
- badges/quêtes que le membre choisit de rendre visibles.

### Actions

- voir une annonce ;
- se connecter pour contacter ;
- signaler le profil ;
- copier le lien sans injecter de traceur social.

Le profil ne doit pas inclure de « dernière connexion », calendrier détaillé, historique de localisation, liste d'amis ou graphe de parrainage public.

## Confidentialité par défaut

- Le nom public est choisi séparément du nom utilisé pour la gestion du compte.
- Le téléphone ne possède pas de réglage « visible à tous » ou « tous les membres » en V1.
- L'adresse exacte se partage pour un échange précis, après acceptation, avec rappel de l'audience.
- Les champs texte détectent et préviennent la publication accidentelle d'e-mail/téléphone, sans bloquer aveuglément un contenu légitime.
- Les coordonnées précises ne sont jamais envoyées au navigateur public puis cachées en CSS.
- Les médias sont réencodés et leurs métadonnées EXIF/localisation supprimées.
- Les notifications et e-mails ne recopient que l'information nécessaire.
- Les analytics n'enregistrent ni texte de message, ni coordonnées, ni identifiant civil.

## Visibilité et moteurs de recherche

« Accessible à un visiteur » ne signifie pas nécessairement « indexé par tous les moteurs ».

Recommandation V1 :

- annonces publiques indexables avec zone large ;
- profils accessibles par lien et recherche interne, mais balise `noindex` au lancement ;
- slugs non séquentiels, stables et non dérivés d'un e-mail/téléphone ;
- pas d'annuaire exhaustif librement téléchargeable ;
- limitation de rythme et surveillance du scraping ;
- aperçu social sans coordonnées ni avis complet ;
- suppression rapide des caches contrôlés après retrait, avec procédure de déréférencement si nécessaire.

`robots.txt` et `noindex` limitent l'indexation coopérative mais ne garantissent pas l'absence de copie. Une indexation future des profils exige une nouvelle analyse de nécessité, d'attentes raisonnables et de risques.

## Finalités et bases légales candidates

La base légale est choisie traitement par traitement, avant collecte. Le tableau est une hypothèse de cadrage à valider.

| Traitement | Finalité | Base candidate | Travail préalable |
|---|---|---|---|
| Compte, authentification, échanges | Fournir le service demandé | Contrat | Tester la stricte nécessité de chaque champ |
| Publication d'annonce/profil minimal | Rendre l'offre ou la demande consultable | Contrat ou intérêt légitime selon le traitement exact | Information claire et paramètres par défaut minimaux |
| Trust Score public | Donner du contexte de confiance et prévenir les abus | Intérêt légitime candidat | Test de finalité, nécessité, attentes et mise en balance ; droit d'opposition |
| Détection de fraude/modération | Sécuriser membres et plateforme | Intérêt légitime candidat | Minimisation, faux positifs, revue humaine, conservation limitée |
| Points Services | Exécuter et auditer l'échange interne | Contrat/intérêt légitime selon opération | Registre, exactitude et contestation |
| Demandes de droits | Répondre aux obligations RGPD | Obligation légale | Vérification proportionnée de l'auteur |
| Newsletter | Envoyer des communications facultatives | Consentement | Séparé, prouvable, retirable |
| Cookies analytics/publicité | Mesurer/personnaliser selon finalité | Consentement lorsque requis | Refuser aussi facilement qu'accepter |
| Sécurité des sessions | Prévenir les accès non autorisés | Intérêt légitime candidat | Durée courte, accès restreint, information |

L'intérêt légitime n'est pas une base automatique. SEOS doit documenter l'objectif, démontrer la nécessité, apprécier les attentes raisonnables et mettre en balance les droits, puis ajouter les mesures de réduction de risque.

## Trust Score et profilage

Le calcul analyse des comportements attribués à un membre : il s'agit d'un profilage de données personnelles. L'information dédiée doit expliquer en langage simple :

- pourquoi le score existe ;
- quelles familles de données interviennent ;
- la logique et les principaux facteurs ;
- pourquoi répétition, récence et parrainage sont plafonnés ;
- pourquoi jusqu'à dix codes peuvent créer un score provisoire et comment leur influence diminue avec les échanges ;
- qui reçoit le score public et les signaux internes ;
- les conséquences possibles ;
- comment signaler une erreur, s'opposer lorsque le droit s'applique et obtenir une revue humaine.

La simple publication d'un indicateur n'entre pas nécessairement dans l'interdiction des décisions entièrement automatisées. Mais si SEOS refuse automatiquement un échange, suspend un compte ou limite fortement un membre sur ce seul fondement, l'effet peut devenir significatif. La V1 interdit donc ces décisions sans intervention humaine, explication et recours.

## Analyse d'impact

Une AIPD est à conduire avant lancement du Trust Score. Le projet cumule au minimum une évaluation/scoring systématique et des traitements pouvant influencer l'accès à des échanges ; d'autres critères peuvent apparaître selon l'échelle, le suivi, les publics vulnérables et les rapprochements de données.

L'AIPD doit couvrir :

1. finalités, responsabilités, acteurs et flux ;
2. données et preuves utilisées, y compris signaux écartés ;
3. nécessité et proportionnalité du score public et du risque interne ;
4. risques : stigmatisation, discrimination indirecte, faux compte, collusion, représailles, scraping, fuite admin ;
5. mesures : seuils, plafonds, explication, recours, revue humaine, sécurité, conservation ;
6. tests par cohortes et nouveaux membres ;
7. risques résiduels et validation formelle ;
8. réexamen à chaque évolution importante de formule ou de finalité.

Si un risque élevé résiduel ne peut pas être réduit, la procédure de consultation appropriée doit être étudiée avec le DPO/juriste avant lancement.

## Durées de conservation

**Réponse à « à vie ? » : non pour les données personnelles identifiantes.** La CNIL rappelle qu'elles ne peuvent pas être conservées indéfiniment : chaque traitement doit posséder une durée ou un critère de durée lié à sa finalité. Seules des données réellement anonymisées ou des archives soumises à une obligation légale documentée peuvent subsister durablement hors usage courant.

Il n'existe pas une durée universelle. Chaque durée dépend de la finalité, des obligations, des contentieux possibles et de la nécessité. La matrice ci-dessous est un point de départ produit, pas une validation juridique.

| Donnée | Conservation active proposée | Après fermeture/fin | Sortie |
|---|---|---|---|
| Compte et profil privé | Vie du compte | Courte phase de fermeture puis anonymisation, sauf besoin justifié | Suppression/anonymisation |
| Profil public | Tant que compte actif et usage public | Dépublication immédiate à la fermeture/restriction | Cache/déréférencement |
| Annonce active | Jusqu'à clôture/retrait | Archive privée limitée + éléments nécessaires aux échanges/litiges | Anonymisation ou suppression |
| Message | Pendant échange et période utile de suivi | Durée définie pour litige/sécurité, accès fortement restreint | Suppression/anonymisation |
| Avis/Trust Events | Tant que nécessaires au profil actif | Période limitée pour recours/audit ; dissociation du profil public | Invalidation/anonymisation |
| Opérations de points | Durée métier et probatoire validée | Conservation du registre minimisé | Pseudonymisation si possible |
| Signalement/modération | Traitement + prévention proportionnée | Durée selon gravité/récidive/recours | Purge programmée |
| IP/session/appareil | Sécurité immédiate | Durée courte documentée | Suppression/agrégation |
| Consentement | Durée de validité + preuve nécessaire | Selon prescription applicable | Suppression |
| Export RGPD | Temps de préparation/téléchargement | Lien et archive temporaires | Purge automatique |
| Audit admin/accès sensible | Durée de contrôle définie | Accès restreint | Purge contrôlée |
| Contact visiteur | Jusqu'à résolution + courte période de suivi | Archive restreinte si litige, sinon purge | Suppression/anonymisation |
| SEO/sitemap | Tant que contenu public indexable | Retrait immédiat du sitemap, déréférencement selon besoin | `410`, `301` ou `noindex` selon cycle |
| Don Stripe dormant | Si module activé : durée du paiement/support | Durées comptables/légales validées | Minimisation puis purge/archivage légal |

Chaque ligne du registre final comportera : responsable, base, déclencheur du délai, durée active, archive intermédiaire, destinataires, méthode de purge, exceptions et preuve d'exécution. Un job de purge doit être simulable et produire un compte rendu sans copier les données supprimées. Le super-admin publie des versions validées de cette politique, mais l'interface interdit une valeur globale `forever` et ne remplace pas la revue DPO/juridique.

## Droits des personnes

L'espace confidentialité permet : accès, rectification, export, effacement, limitation, opposition et retrait du consentement selon le traitement.

Parcours cible :

1. demande authentifiée ou vérification proportionnée ;
2. accusé de réception et délai affiché ;
3. recherche dans base, fichiers, jobs, prestataires et archives concernées ;
4. revue des droits des tiers, obligations et litiges ;
5. réponse compréhensible et export sécurisé ;
6. exécution chez les sous-traitants ;
7. preuve minimale de traitement et suppression de l'export temporaire.

Le délai réglementaire applicable est géré dans `response_due_at` et surveillé par le back-office. Une impossibilité d'effacer une écriture probante n'autorise pas à conserver tout le profil public : il faut restreindre, pseudonymiser ou anonymiser ce qui peut l'être et expliquer le reliquat.

## Administration et données sensibles

- permissions par finalité ;
- données masquées par défaut ;
- motif obligatoire et réauthentification pour révéler ;
- accès conversation uniquement depuis un dossier précis ;
- journal append-only de chaque consultation sensible ;
- export temporaire, limité, chiffré et tracé ;
- aucun secret dans `site_settings`, les logs ou les exports ;
- revue périodique des permissions et retrait immédiat au départ d'un administrateur ;
- interdiction de l'usurpation silencieuse de session membre.

Le détail des écrans et actions figure dans [`07-panel-administration.md`](./07-panel-administration.md).

## Studio, contenus publics et carte

Rendre une page éditable ne permet pas d'y recopier des données personnelles sans nouvelle finalité. Le Studio applique donc les mêmes règles de minimisation que le code :

- aucun champ de contenu ne propose automatiquement e-mail, téléphone, adresse exacte, messages, solde, signalements ou signaux Trust internes ;
- images et vidéos sont réencodées, dépourvues d'EXIF/localisation, associées à un alt, un crédit, une licence et un statut de publication ;
- preview et versions archivées restent soumises aux permissions et à la conservation ; une URL de preview ne doit pas devenir publique/indexable ;
- un reset retire la version du rendu actif mais ne dispense pas d'appliquer la durée de conservation à l'historique et aux blobs devenus orphelins ;
- les descriptions, SEO et aperçus sociaux sont contrôlés pour éviter coordonnées, identifiants privés ou données concernant un tiers ;
- aucun CSS/HTML/JavaScript/SVG libre n'est accepté, afin de réduire exfiltration, traceurs et contournement du consentement.

Le flag `public_map_enabled` est aussi un interrupteur de traitement côté client. Lorsqu'il est faux, SEOS n'affiche pas seulement une carte vide : il n'envoie aucun SDK, script, tuile, cookie ou requête au fournisseur. Lorsqu'il est vrai, la localisation reste approximative et les obligations de consentement/information dépendent du prestataire finalement choisi. Chaque changement du flag est audité.

Le mode `remote` n'autorise jamais à géocoder l'adresse privée du membre pour « remplir » la carte. Sur une annonce individuelle, seuls `in_person` et `hybrid` peuvent produire une carte, à partir d'une zone publique minimisée. Sur la carte globale, les annonces à distance restent visibles dans un panneau de résultats dédié et dans le total, mais sans latitude/longitude, distance ou marqueur artificiel. Une annonce hybride n'apparaît qu'une fois dans le total : elle est rattachée à son marqueur et porte un badge indiquant la possibilité à distance.

## SEO, GEO et moteurs génératifs

Une annonce publique est destinée à être trouvée. Le formulaire de publication doit l'indiquer clairement et montrer l'aperçu exact des informations indexables. Cette information ne vaut jamais consentement à publier une coordonnée privée.

- canonical, métadonnées, Open Graph, Schema.org et sitemap reprennent seulement les champs déjà visibles ;
- `Service` ou `Demand/Service` n'incluent jamais adresse exacte, coordonnées précises, téléphone, e-mail, relation de parrainage ou signaux Trust internes ; un éventuel `Offer` reste soumis au mapping non commercial strict du document SEO ;
- les brouillons, previews, recherches internes, compte et administration sont exclus des crawlers ;
- retrait/fermeture déclenchent la sortie du sitemap et la stratégie `noindex`/`410`/redirection appropriée ;
- les logs de crawlers sont agrégés et ne deviennent pas un nouveau profil utilisateur ;
- la politique distingue crawler de recherche et crawler d'entraînement ; autoriser l'un n'autorise pas automatiquement l'autre ;
- un membre peut demander rectification/retrait ; SEOS documente aussi la procédure de déréférencement auprès des tiers.

La stratégie détaillée figure dans [`13-strategie-seo-schema-org-et-geo.md`](./13-strategie-seo-schema-org-et-geo.md).

## Prestataires V1 et soutien dormant

- Gmail API : adresse d'envoi SEOS, credentials Google hors base, contenu minimal et reprise des erreurs ;
- login : Devise et Google OmniAuth en premier ; Facebook désactivé tant que la compatibilité n'est pas validée ;
- géocodage/carte : Geocoder + Leaflet, fournisseur de géocodage/tuiles inscrit au registre et localisation publique minimisée ;
- vidéo : Active Storage/HTML5 afin d'éviter un tiers par défaut ;
- analytics : aucun traceur tiers au lancement, uniquement des compteurs agrégés internes ;
- Stripe : intégration dormant derrière un flag faux, soutien uniquement, aucun PS/Trust/niveau/avantage et aucune donnée carte bancaire stockée par SEOS.

Avant activation de Stripe : valider entité bénéficiaire, terminologie « don », fiscalité, comptabilité, information, sous-traitance et conservation. Aucun reçu fiscal n'est promis sans habilitation.

## Sécurité et réduction de l'exposition

- chiffrement applicatif des coordonnées sensibles et clés gérées hors base ;
- TLS, cookies de session sécurisés, rotation et révocation ;
- authentification renforcée des administrateurs ;
- limitation de débit sur profil, recherche, messages, exports et révélations ;
- pièces jointes contrôlées, réencodées et analysées selon risque ;
- sauvegardes chiffrées avec restauration testée et calendrier de purge ;
- environnements et jeux de données séparés ;
- aucune donnée de production réelle dans les seeds ou captures de test ;
- alertes sur exports volumineux, consultations répétées et élévations de permissions ;
- procédure d'incident et qualification d'une éventuelle violation de données.

## Publics vulnérables et âge

Recommandation V1 : réserver l'inscription et les rencontres organisées aux personnes majeures. Le service combine mise en relation, déplacement possible, réputation et données de localisation ; l'ouverture aux mineurs demande un cadrage séparé sur consentement, représentation légale, modération, sécurité et tâches interdites.

Les catégories impliquant domicile, garde, santé, personnes dépendantes, transport ou équipements dangereux doivent recevoir des avertissements et règles supplémentaires. Sans vérification d'identité V1, SEOS peut limiter ou différer certains usages au lieu de présenter le Trust Score comme une garantie.

## Textes et écrans à prévoir

- notice de confidentialité générale ;
- notice courte au moment de créer le profil public ;
- explication dédiée du Trust Score et de son profilage ;
- politique cookies et centre de préférences ;
- charte d'avis factuels et de confiance ;
- charte de sécurité des rencontres et échanges à domicile ;
- formulaire de contact DPO/référent et d'exercice des droits ;
- historique des versions de textes acceptés ;
- avertissement avant partage d'une coordonnée ;
- aperçu exact « Ce que voit un visiteur » dans le profil membre.

## Checklist avant mise en production

- [ ] Registre des traitements complété et responsabilités attribuées.
- [ ] Base légale et test de mise en balance validés pour le Trust Score et la lutte contre la fraude.
- [ ] AIPD terminée, risques résiduels acceptés et date de réexamen prévue.
- [ ] Profil visiteur testé sans authentification et sans donnée privée dans HTML/JSON/métadonnées.
- [ ] Score expliqué, versionné, contestable et sans décision importante entièrement automatisée.
- [ ] Téléphone/e-mail/adresse absents des réglages publics.
- [ ] Durées et purges effectives testées, y compris stockage, sauvegardes et prestataires.
- [ ] Sous-traitants, localisation, contrats et transferts examinés.
- [ ] Consentement cookies granulaire, symétrique et réversible.
- [ ] Procédure droits/incidents et délais testés dans le back-office.
- [ ] Permissions admin, réauthentification, masquage et journaux d'accès testés.
- [ ] Contenus/médias du Studio contrôlés contre les coordonnées, métadonnées de localisation et traceurs arbitraires.
- [ ] Preview Studio non indexable et inaccessible aux audiences non autorisées.
- [ ] Carte désactivée testée sans SDK, tuile, cookie ni appel réseau du fournisseur.
- [ ] Annonces indexables et JSON-LD testés sans coordonnée ni donnée Trust interne.
- [ ] Politique de conservation publiée sans valeur globale à vie et purge simulée.
- [ ] Formulaire Contact visiteur incapable de créer un message ou une demande d'annonce.
- [ ] Module Stripe absent publiquement tant que son flag est faux et totalement indépendant des PS.
- [ ] Textes légaux validés par le responsable compétent.

## Références officielles

- [CNIL — Définition d'une donnée personnelle](https://www.cnil.fr/fr/definition/donnee-personnelle)
- [CNIL — Minimiser les données collectées](https://www.cnil.fr/fr/minimiser-les-donnees-collectees)
- [CNIL — Préparer son développement, privacy by design et par défaut](https://www.cnil.fr/fr/preparer-son-developpement)
- [CNIL — Les bases légales et l'intérêt légitime](https://cnil.fr/fr/les-bases-legales/interet-legitime)
- [CNIL — Profilage et décision entièrement automatisée](https://www.cnil.fr/fr/profilage-et-decision-entierement-automatisee)
- [CNIL — Gérer les risques et l'AIPD](https://www.cnil.fr/fr/gerer-les-risques)
- [CNIL — Durées de conservation](https://www.cnil.fr/fr/passer-laction/les-durees-de-conservation-des-donnees)
- [CNIL — Droit à l'effacement](https://www.cnil.fr/fr/comprendre-mes-droits/le-droit-leffacement-supprimer-vos-donnees-en-ligne)
- [CNIL — Recommandations aux diffuseurs de données ouvertes](https://www.cnil.fr/sites/cnil/files/2024-06/recommandations_diffuseurs_de_donnees_ouvertes_open_data.pdf)
- [Règlement général sur la protection des données — texte consolidé](https://eur-lex.europa.eu/legal-content/EN/TXT/PDF/?qid=1787347134762&uri=CELEX%3A02016R0679-20160504)
