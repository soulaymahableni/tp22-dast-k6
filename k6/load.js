// TP22 - Partie 5 : test de charge (montée, plateau, descente) avec seuils bloquants
// Exemples :
//   docker run --rm -i --network host -e BASE_URL=http://localhost:8080 grafana/k6 run - < k6/load.js
//   ... -e VUS=50 ...   (recherche du point de rupture : 20, 50, 100, 200)
import http from 'k6/http';
import { check, group, sleep } from 'k6';

const BASE_URL = __ENV.BASE_URL || 'http://localhost:8080';
const VUS = Number(__ENV.VUS || 20);
const TERMS = ['apple', 'banana', 'juice', 'lemon', 'melon', 'orange', 'egg', 'water'];

export const options = {
  // Paliers : montée -> plateau -> descente
  stages: [
    { duration: '30s', target: VUS },
    { duration: '1m', target: VUS },
    { duration: '20s', target: 0 },
  ],
  thresholds: {
    // Taux d'erreur : arrêt immédiat du test (abortOnFail) si l'application s'écroule
    http_req_failed: [{ threshold: 'rate<0.01', abortOnFail: true, delayAbortEval: '10s' }],
    // Latence globale
    http_req_duration: ['p(90)<400', 'p(95)<500'],
    // Un seuil par groupe (les routes n'ont pas le même coût)
    'http_req_duration{group:::accueil}': ['p(95)<300'],
    'http_req_duration{group:::recherche}': ['p(95)<800'],
    'http_req_duration{group:::avis}': ['p(95)<600'],
    checks: ['rate>0.99'],
  },
  summaryTrendStats: ['avg', 'min', 'med', 'max', 'p(90)', 'p(95)', 'p(99)'],
};

export default function () {
  group('accueil', () => {
    const r = http.get(`${BASE_URL}/`);
    check(r, { 'accueil 200': (res) => res.status === 200 });
  });

  group('recherche', () => {
    const q = TERMS[Math.floor(Math.random() * TERMS.length)];
    const r = http.get(`${BASE_URL}/rest/products/search?q=${q}`, { tags: { name: 'search' } });
    check(r, {
      'recherche 200': (res) => res.status === 200,
      'recherche JSON': (res) => res.json('status') === 'success',
    });
  });

  group('avis', () => {
    const id = 1 + Math.floor(Math.random() * 10);
    const r = http.get(`${BASE_URL}/rest/products/${id}/reviews`, { tags: { name: 'reviews' } });
    check(r, { 'avis 200': (res) => res.status === 200 });
  });

  sleep(1);
}
