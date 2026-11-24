// TP22 - test "smoke" : 1 utilisateur, 30 s, vérifie que tout répond avant un vrai test de charge
import http from 'k6/http';
import { check, sleep } from 'k6';

const BASE_URL = __ENV.BASE_URL || 'http://localhost:8080';

export const options = {
  vus: 1,
  duration: '30s',
  thresholds: {
    http_req_failed: ['rate<0.01'],     // moins de 1 % d'échecs
    http_req_duration: ['p(95)<1000'],  // 95 % des requêtes sous 1 s
    checks: ['rate>0.99'],
  },
};

export default function () {
  const home = http.get(`${BASE_URL}/`);
  check(home, {
    'accueil : statut 200': (r) => r.status === 200,
    'accueil : en-tête nosniff': (r) => r.headers['X-Content-Type-Options'] === 'nosniff',
  });

  const search = http.get(`${BASE_URL}/rest/products/search?q=apple`);
  check(search, {
    'recherche : statut 200': (r) => r.status === 200,
    'recherche : JSON success': (r) => r.json('status') === 'success',
  });

  sleep(1);
}
