# Analyse du dossier du 4 septembre et démarrage de la phase 0

Date : 5 septembre 2026. Références Git analysées : `2762831`, `14b4d4e`, `cb07029`.

## Conclusion de l’analyse

Le dossier décrit un produit complet et cohérent sur ses invariants. La phase 0 est déjà un chantier conséquent : neuf features F-001 à F-009, incluant deux Studios versionnés. **P0 est une priorité de backlog, pas le numéro de la phase 0** : toutes les lignes P0 ne doivent donc pas être générées maintenant.

Le premier incrément fournit une application locale navigable et authentifiée, des permissions serveur, des accès administratifs testés et une chaîne de vérification reproductible. Il commence la phase 0 ; il ne clôture pas ses neuf features. Les Studios, prestataires et finitions listés ci-dessous restent à construire.

## Lecture croisée de toute la documentation

| Source | Décision utile pour le code et vigilance |
|---|---|
| `user-story.md` et `maquette.html` | Les 28 stories restent obligatoires. La maquette couvre davantage de parcours, avec état simulé et utilisateur connecté fictif. Il faut conserver l’intention visuelle et reconstruire chaque action sur une vraie route serveur. |
| `01-resume-application.md` | Trois modes indépendants ; France/français ; séparation membres, organisations et administration. Aucun achat de PS et aucune coordonnée privée sur le profil public. |
| `02-analyse-maquette-user-stories.md` | La story initiale « ne pas voir les profils » est arbitrée en profil de service public sans informations privées. L’authentification protège les actions de contact avec les annonceurs. |
| `03-modele-de-donnees.md` | Les contraintes doivent vivre en base et les transitions dans des services. `Association`/`Partenaire` ne deviennent pas des rôles `User`. Sessions, grants et memberships constituent les premières tables utiles. |
| `04-plan-scaffolds-rails-8.md` | Installer RSpec avant les générateurs, un seul modèle Devise et un seul build JS/CSS. Les commandes sont indicatives : aucun scaffold global ni CRUD sur les écritures sensibles. |
| `05-kit-ui-ux.md` | Palette SEOS, DM Sans/Playfair locales, largeur 1240 px, composants arrondis, 7 viewports. Les petits textes bleu vif et danger manquent de contraste dans la maquette ; utiliser les variantes profondes prévues. |
| `06-backlog-features.md` | Les priorités organisent la livraison sans supprimer les stories. Le « lot 0 » n’est pas identique à la « phase 0 » : le profil y figure, mais F-011 appartient à la phase 1 du plan d’exécution. |
| `07-panel-administration.md` | Même panneau enrichi à chaque feature, permissions granulaires, données masquées, motif et réauthentification. Les treize domaines admin ne sont pas tous implémentables avant leurs modèles métier. |
| `08-systeme-trust-score.md` | Indice public distinct du risque interne. Les 1/3/5/10 parrainages donnent environ 53/58/62/69, uniquement au global provisoire. PS, niveau et soutien financier n’améliorent pas le Trust. Ce moteur relève des phases 3/4. |
| `09-rgpd-profils-publics.md` | Séparation public/privé jusque dans HTML, logs et métadonnées ; aucune conservation globale à vie. Les contrats, durées, AIPD et textes légaux exigent une validation avant lancement. |
| `10-plan-construction-feature-par-feature.md` | Référence d’ordre de chantier : phase 0 = F-001…F-009. Une feature n’est terminée qu’avec ses droits, son administration applicable et ses preuves de test. |
| `11-strategie-tests-rspec-et-regression.md` | RSpec canonique, contrats serveur + navigateur, coverage 95/90, tests visuels échouant sans référence, aucune mise à jour automatique des baselines. Ne pas confondre couverture du code présent et couverture des stories futures. |
| `12-studio-ui-contenus-carte-et-separateurs.md` | Les templates restent codés. Défaut immuable, brouillons isolés, schémas fermés, publication atomique et reset créant une nouvelle version. Aucun champ de code libre. Le registre s’enrichit avec chaque route. |
| `13-strategie-seo-schema-org-et-geo.md` | SEO fondé sur les annonces publiques réelles et leurs métadonnées sûres. `Service`/`Demand`, pas de prix EUR pour les PS ni de Trust transformé en étoiles. Profil `noindex` initial. L’indexation attend F-017. |
| `docs/README.md` | Index et décisions consolidées ; sa photo technique décrit l’état du 4 septembre, pas l’état après cette livraison. |

## Incohérences et arbitrages d’exécution

1. **Ordre de chantier** : le plan de scaffolds place encore les Studios après les premières annonces, alors que le plan feature par feature les place en phase 0. L’exécution suit F-001 à F-009 ; les Studios précèdent donc la livraison de la phase 1.
2. **Google login** : le résumé le mentionne aussi dans une « version suivante », le backlog le classe P1 et F-003 le prévoit dès les fondations. Le reste à faire de la phase 0 conserve Google OmniAuth ; cela n’autorise aucun bouton simulé.
3. **Prestataires** : la phrase de synthèse « Devise, Gmail API, Google OmniAuth, Geocoder/Leaflet, vidéo interne et analytics tiers désactivés » était ambiguë. Les documents détaillés retiennent les premiers, avec seulement les analytics tiers désactivés ; Facebook et Stripe restent dormants. La formulation de l’index a été clarifiée.
4. **Fidélité et accessibilité** : la référence possède des contrastes insuffisants et un menu mobile sans comportement. Les tokens de marque sont conservés ; petits textes profonds, focus visible, menu fonctionnel et cibles de 44 px complètent l’interface.
5. **Règles encore ouvertes** : ordre exact de double confirmation des PS, vocabulaire succès/quêtes, politique d’âge, catégories sensibles et garanties éventuelles. Elles ne bloquent pas la création du socle technique. Elles restent à décider avant les parcours concernés.
6. **Statut visuel** : l’accueil livré est l’accueil initial de F-001, pas la page complète de F-010. Les captures initiales préviennent des régressions de ce socle ; elles ne prouvent pas encore une identité visuelle de tous les états de la maquette.

## État exact de F-001 à F-009

| Feature | Livré dans cet incrément | Restant avant clôture complète |
|---|---|---|
| F-001 Socle | Rails 8.1.3.1, Ruby 3.4.7, SQLite, Propshaft, Turbo/Stimulus ; CSS importé depuis JS ; build unique, empreinte des sources et sorties ; locale française/Paris ; setup, healthcheck, erreurs françaises ; première suite RSpec | Configuration réelle du domaine et des credentials de production dépendant des prestataires |
| F-002 UI/layouts | Tokens et logo issus de la maquette, polices locales, layouts public/compte/admin, navigation d’organisation, champs/erreurs, badges, cartes, boutons, modale, messages, tableaux et pagination ; clavier/reduced motion | Catalogue complet des composants métier et comparaison exhaustive à la maquette ; référence immuable stockée pour le Studio |
| F-003 Authentification | Devise 5.0.4, Confirmable, Recoverable, Lockable, Timeoutable, normalisation/unicité e-mail, anti-robot sans puzzle, rate limit, sessions/appareils révocables, récupération, changement d’identifiants, réauthentification | Google OmniAuth et dissociation, politique d’âge/CGU versionnées, récupération renforcée des comptes privilégiés ; notification/audit complet des événements de connexion |
| F-004 Autorisations | Pundit, refus par défaut, rôles système, permissions expirables/révocables, memberships owner/manager/editor, changement de rôle super-admin, sessions révoquées, audit | Gestion complète des équipes/invitations et cycle des partenariats avec F-060/F-062 ; nouveaux droits ajoutés avec leurs ressources, alertes de mutation avec F-006 |
| F-005 Administration | Namespaces protégés, sidebar par droits, dashboards, liste membres masquée/recherche par identifiant/filtres URL/pagination, journal d’audit, gestion des administrateurs et permissions | Recherche transverse, pagination avancée de la gestion des admins, vues enregistrées, exports limités et actions de masse idempotentes sur ressources disponibles |
| F-006 Technique | Tables Active Storage installées ; routes d’upload fermées ; audit append-only en Ruby et SQL, paramètres sensibles filtrés ; e-mails Devise capturés localement sans envoi ; infrastructure Solid Queue existante conservée | Gmail API, files/outbox/retries/idempotence/alertes, notifications de sécurité, MIME/taille/nombre/réencodage/EXIF, médias et purges, accès sensibles journalisés |
| F-007 RSpec/CI | RSpec 8.0.4, FactoryBot, WebMock, Chrome/driver verrouillés, axe, comparaison PNG, couverture avec seuils, JUnit/artefacts CI et détection d’assets périmés/altérés | Matrice exhaustive de toutes les stories au fil des features ; parallélisation et fusion de couverture à industrialiser ; baselines de tous les écrans/états de la maquette |
| F-008 Studio UI | Préparé par les tokens, autorisations et audit du socle | Modèles/versionnement, schéma strict, validation contraste, preview isolée, publication atomique, rollback et resets granulaires/globaux ; aucun écran Studio livré |
| F-009 Studio contenus | Socle d’accès, assets et stockage préparé | Registre des pages/communications, versions/blocs/médias, droits de proposition par organisation, programmation, publication, rollback et resets ; aucun écran Studio livré |

Les seuls droits administratifs actuellement proposés correspondent au socle ou à sa préparation : `users.read`, `audit.read`, `content.manage`, `studio.read`, `studio.preview`. Aucun de ces droits ne confère les exclusivités du super-admin.

## Choix techniques vérifiables

- **Un seul flux d’assets** : sources sous `app/javascript/stylesheets`, polices via Fontsource, esbuild vers `app/assets/builds`. Les URLs de polices restent relatives pour que Propshaft applique son digest. La feuille homonyme initiale a été retirée de `app/assets/stylesheets`.
- **Schéma SQL** : `db/structure.sql` conserve les triggers append-only, contrairement au schéma Ruby standard. Les tests attaquent aussi les modifications SQL directes.
- **Sessions** : condensat SHA-256 d’un jeton aléatoire de 256 bits, expiration absolue 12 h, inactivité 30 min, résumé du navigateur sans IP. Les durées de conservation et la purge des lignes historiques restent à définir dans la politique de conservation.
- **Administration** : les sessions âgées de plus de 15 min doivent reconfirmer le mot de passe. Promotion/rétrogradation ordinaires limitées à `member/admin`, super-admins protégés ; premier super-admin initialisé par une commande locale auditée. En développement uniquement, les seeds proposent aussi un membre, un super-admin et une association vérifiée avec son responsable ; identifiants et commande dans le [README](../README.md#comptes-de-démonstration).
- **Stockage** : aucun endpoint Active Storage public n’est actif avant de disposer de validation des fichiers et de policies de téléchargement.
- **E-mails** : Devise utilise le transport fichier en développement et le transport test dans RSpec. Ce n’est pas encore l’adaptateur Gmail de F-006. Les corps des messages ne sont pas recopiés par le logger Action Mailer.
- **Sécurité navigateur** : CSP limitée à l’origine, cookies HTTP-only/SameSite et Secure en production, pages privées non mises en cache. Le socle complet reste `noindex` jusqu’aux vraies pages indexables de F-017.
- **Régression** : références initiales accueil/connexion aux largeurs 320, 375, 414, 768, 1024, 1280, 1440 ; captures complètes, largeur vérifiée, tolérance 0,5 %. Toute capture candidate se fait hors CI et n’écrase aucun PNG de référence.

## Vérification de cet incrément

Recette effectuée localement sur une **base SQLite neuve et isolée**, préparée par `RAILS_ENV=test DATABASE_URL=... bin/setup --skip-server` :

- **83 exemples RSpec, 0 échec**, ordre aléatoire `39523`, y compris système, comparaison PNG et accessibilité ; rapport JUnit généré.
- **100 % des lignes** (322/322) et **93,18 % des branches** (82/88) du code applicatif présent. Ces chiffres ne mesurent pas les features non implémentées.
- **14 références visuelles** comparées : accueil/connexion × 7 largeurs ; vérification de largeur réelle, absence de débordement et zoom 200 %.
- Contrôles axe WCAG 2.2 AA sur les écrans publics/authentification et les principaux écrans compte/admin. La recette manuelle avec lecteur d’écran reste à réaliser avant lancement.
- `bin/setup --skip-server`, préparation depuis `structure.sql` et présence des deux triggers d’audit vérifiés sur base vierge.
- `bin/dev` démarré sur un port de test : `/up` et `/` répondent 200 ; une modification CSS est reconstruite automatiquement par le watcher.
- `SECRET_KEY_BASE_DUMMY=1 RAILS_ENV=production bin/rails assets:precompile` réussi ; assets de précompilation locale nettoyés puis build de développement restauré.
- Contrôle négatif du build : modification des sources ou altération d’un artefact refusées ; fichiers restaurés ensuite.
- `zeitwerk:check`, `git diff --check` et RuboCop : réussis ; **76 fichiers Ruby inspectés** sans infraction.
- Brakeman : **0 avertissement, 0 erreur**. Bundler Audit et Yarn Audit : aucune vulnérabilité signalée lors de la vérification.
- Workflow GitHub Actions configuré et YAML vérifié. Son exécution distante n’a pas été déclenchée ; les commandes ci-dessus ont été exécutées localement.

Les commandes reproductibles figurent dans le README applicatif.

## Prochain chantier dans la phase 0

Terminer F-003/F-006 ensemble : Google OAuth, transport Gmail et notifications de sécurité avec file durable et reprise idempotente, puis pipeline média sécurisé. Construire ensuite F-008 et F-009 avec leurs modèles immuables, schémas de validation, previews, publication et resets. Chaque ajout conserve sa suite de policies, requêtes et systèmes avant de débloquer la phase 1.

## Références techniques vérifiées

- [Devise](https://github.com/heartcombo/devise) : modules et intégration Rails.
- [RSpec Rails](https://github.com/rspec/rspec-rails) : installation et framework de tests.
- [jsbundling-rails](https://github.com/rails/jsbundling-rails) : branchement du build à la précompilation.
- [Pundit](https://github.com/varvet/pundit) : policies et contrôle des autorisations.
- [setup-chrome](https://github.com/browser-actions/setup-chrome) : navigateur et driver verrouillés en CI.
