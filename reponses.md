# TP22 : réponses et tableaux

> Les valeurs entre crochets `[ ]` sont à recopier depuis **tes** rapports. Les rapports ZAP sont dans `reports/`,
> et `scripts/04-baseline-proxy.sh` affiche le tableau de comparaison automatiquement.

## SAST, SCA et DAST

| | SAST (TP10) | SCA (TP10) | DAST (TP22) |
|---|---|---|---|
| Ce qui est analysé | le code source | les dépendances (versions, CVE) | l'application **en fonctionnement**, en boîte noire |
| Moment | dès le commit | dès le commit | après déploiement (env. de test ou de staging) |
| Ce qu'il voit | failles dans le code (injection, secrets…) | bibliothèques vulnérables | configuration réelle : en-têtes, cookies, TLS, erreurs, comportement HTTP |
| Limites | faux positifs, ne voit pas la config du serveur | ne voit pas si la faille est atteignable | ne voit que ce qu'il explore : couverture limitée (pages derrière login, logique métier), lent, scan actif destructif, pas de localisation de la ligne de code fautive |

## Partie 1 : scan baseline direct (http://localhost:3000)

Code retour obtenu : `[2]` (des WARN, aucun FAIL sans fichier de règles).

| Alerte | ID | Risque | URL | Preuve (evidence) | Solution | CWE |
|---|---|---|---|---|---|---|
| Content Security Policy (CSP) Header Not Set | 10038 | Medium | `http://localhost:3000/` | en-tête `Content-Security-Policy` absent | définir une CSP (d'abord en Report-Only) | CWE-693 |
| Cross-Domain Misconfiguration | 10098 | Medium | `http://localhost:3000/` | `Access-Control-Allow-Origin: *` | restreindre CORS aux origines de confiance | CWE-264 |
| Server Leaks Information via "X-Powered-By" | 10037 | Low | `http://localhost:3000/…` | `X-Powered-By: Express` | supprimer l'en-tête (`app.disable('x-powered-by')` ou `proxy_hide_header`) | CWE-497 |

*(Vérifie les URL, preuves et CWE exactes dans `reports/baseline-direct.html` et adapte si ZAP en a remonté d'autres.)*

**Configuration ou code ?**
- **Configuration** (corrigeable au niveau du serveur ou du proxy, sans toucher au code) : CSP absente, anti-clickjacking, X-Content-Type-Options, divulgation de version (`Server`, `X-Powered-By`), CORS trop large, Permissions-Policy, attributs des cookies posés par le serveur.
- **Code** (corrigeable seulement dans l'application) : cookies créés en JavaScript côté client sans `HttpOnly`/`SameSite`, fonctions JS dangereuses (`eval`, `innerHTML`), commentaires suspects ou horodatages dans les réponses, et toutes les failles du scan actif (injection SQL, XSS).

## Partie 2 : scan actif et scan d'API

Alertes qui **n'apparaissent qu'avec le full scan** (attaques réelles) : `[à recopier depuis reports/full.html]`. On y trouve typiquement :
- **SQL Injection** (40018), par exemple sur `/rest/products/search?q=` ou le login ;
- **Cross Site Scripting (Reflected / DOM)** (40012, 40026) ;
- **Path Traversal** (6) ou **Remote File Inclusion** (7) ;
- **Application Error Disclosure** (90022), les erreurs 500 avec stack trace ;
- **Buffer overflow / format string** et autres injections, selon la durée du scan.

Le baseline ne les voit pas : il ne fait que **lire** les réponses, sans **envoyer de charges malveillantes**.

**Scan d'API sur contact-api** (`reports/api.html`) : la validation **Zod** (`.strict()`, longueurs, format e-mail) renvoie un **400 JSON** pour toute entrée invalide. Le JSON mal formé renvoie **400 `invalid_json`**, et un corps trop gros renvoie **413**. Aucune stack trace n'est exposée (gestionnaire d'erreurs global) et aucune donnée n'est réfléchie dans la réponse. On attend donc **aucune alerte High** : seulement des alertes informatives ou Low. Résultat obtenu : `[à recopier]`.

## Partie 3 : avant / après durcissement

| Alerte | Direct (3000) | Via proxy durci (8080) |
|---|---|---|
| X-Content-Type-Options manquant | `[présente / absente]` | absente (`nosniff` ajouté) |
| Anti-clickjacking | `[présente / absente]` | absente (`X-Frame-Options` + `frame-ancestors`) |
| Divulgation de version | présente (`X-Powered-By: Express`) | absente (`proxy_hide_header`, `server_tokens off`) |
| CSP absente | présente | absente (socle CSP appliqué + Report-Only) |
| **Nombre total de types d'alertes** | `[N]` | `[M]` (affiché par `scripts/04-baseline-proxy.sh`) |

**Pourquoi d'abord `Content-Security-Policy-Report-Only` ?**
Une CSP stricte bloque toute ressource non autorisée : scripts inline, styles inline, CDN, `eval`, connexions WebSocket, images `data:`. En mode **Report-Only**, le navigateur **signale** les violations (console et `report-uri`) **sans rien bloquer**. On observe en conditions réelles ce qui serait cassé, on ajuste la politique, puis on passe en mode appliqué.

**Risque d'une CSP stricte appliquée sans test** : l'application casse en production. Ça peut aller jusqu'à une page blanche (Angular ne charge plus), des boutons inactifs, des styles absents, un paiement ou un widget tiers bloqué, ou des WebSocket refusés. C'est une panne causée par une mesure de sécurité. Ici, on applique donc un **socle sans risque** (`frame-ancestors`, `object-src`, `base-uri`, `form-action`) et la politique complète reste en Report-Only.

## Partie 4 : règles bloquantes (zap/rules.tsv)

- **FAIL** (bloque la livraison) : ce que le proxy corrige et qui ne doit **jamais régresser**, à savoir 10020 (clickjacking), 10021 (nosniff), 10037 (X-Powered-By), 10038 (CSP absente) et 10098 (CORS `*`).
- **WARN** : ce qui demande une correction dans le code ou plus tard, comme les cookies, le flag Secure en HTTP, les faiblesses de la CSP ou le `Server: nginx` sans version.
- **IGNORE** : uniquement avec une justification écrite (faux positifs connus, informations sans impact).
- Option `-I` : les WARN ne font pas échouer le pipeline, seuls les FAIL bloquent.

| Scan | Code retour attendu | Obtenu |
|---|---|---|
| direct (3000) + rules.tsv | 1 | `[1]` |
| proxy durci (8080) + rules.tsv | 0 | `[0]` |

## Partie 5 : k6

Résumé du test de charge (VUS = 20) :

| Métrique | Valeur |
|---|---|
| http_req_duration p(90) | `[…] ms` |
| http_req_duration p(95) | `[…] ms` |
| http_req_failed | `[…] %` |
| iterations | `[…]` |
| Seuils respectés ? | `[✓ / ✗]` |

**Point de rupture** (`scripts/08-breaking-point.sh` + `docker stats` dans un autre terminal) :

| VUs | p95 global | p95 recherche | Échecs | CPU juice-shop | Mémoire juice-shop | Seuil franchi |
|---|---|---|---|---|---|---|
| 20 | | | | | | |
| 50 | | | | | | |
| 100 | | | | | | |
| 200 | | | | | | |

**p95 < 500 ms pour toutes les routes ?** Non. Les routes n'ont pas le même coût ni le même enjeu pour l'utilisateur. Seuils réalistes proposés :

| Type de route | Exemple | Seuil p95 proposé |
|---|---|---|
| Statique ou mise en cache | `/`, JS, CSS, images | < 200 à 300 ms |
| Lecture simple (API) | `GET /rest/products/1/reviews` | < 300 à 500 ms |
| Recherche ou listing (requête en base) | `GET /rest/products/search` | < 800 ms |
| Écriture | `POST /api/contact`, panier | < 1 s |
| Opération lourde | paiement, export, génération PDF | < 2 à 3 s, ou traitement asynchrone |
| Health check | `GET /api/health` | < 100 ms |

Dans tous les cas, on ajoute **`http_req_failed < 1 %`** avec `abortOnFail`, pour arrêter tout de suite un test qui écroule l'application.

## Partie 6 : intégration continue

Le workflow `.github/workflows/dast-perf.yml` démarre la cible, lance ZAP baseline avec `rules.tsv` (rapport en artefact), puis k6 smoke et load. Chaque étape échoue si son code retour est non nul : **1** pour un FAIL ZAP, **99** pour un seuil k6 franchi.

**Démonstration** : une Pull Request qui supprime `add_header X-Content-Type-Options` du proxy fait réapparaître l'alerte **10021 (FAIL)**. ZAP renvoie 1, le job est **rouge** et la PR ne peut pas être fusionnée.

**Où placer ces contrôles dans DEV → STAGING → PRODUCTION ?**

| Étape | Contrôles | Bloquant ? |
|---|---|---|
| DEV (chaque PR) | SAST, SCA, ZAP **baseline** (rapide, passif), k6 **smoke** | oui |
| STAGING (avant promotion) | ZAP **full scan** et **API scan** (actifs : jamais en prod), k6 **load** avec seuils | oui : la promotion vers la prod est bloquée si un seuil ou un FAIL est franchi |
| PRODUCTION | ZAP baseline **passif** planifié, monitoring (TP21 : SLO, alertes), k6 smoke léger après déploiement | alerte, pas de blocage (rollback si besoin) |

Le scan actif et les tests de charge lourds ne se lancent **jamais** en production : ils modifient des données et peuvent provoquer un déni de service.
