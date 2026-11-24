// contact-api (version TP8 simplifiée) : cible du scan ZAP API
'use strict';

const express = require('express');
const { z } = require('zod');

const app = express();
app.disable('x-powered-by');
app.use(express.json({ limit: '10kb' }));

// En-têtes de sécurité minimaux pour une API JSON
app.use((_req, res, next) => {
  res.set({
    'X-Content-Type-Options': 'nosniff',
    'Cache-Control': 'no-store',
    'Content-Security-Policy': "default-src 'none'; frame-ancestors 'none'",
    'X-Frame-Options': 'DENY',
  });
  next();
});

const contactSchema = z
  .object({
    name: z.string().trim().min(2).max(100),
    email: z.string().trim().email().max(254),
    message: z.string().trim().min(10).max(2000),
  })
  .strict(); // refuse les champs inconnus

app.get('/api/health', (_req, res) => res.json({ status: 'ok' }));

app.post('/api/contact', (req, res) => {
  const parsed = contactSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({
      error: 'validation',
      details: parsed.error.issues.map((i) => ({ field: i.path.join('.'), message: i.message })),
    });
  }
  // Ici : envoi d'e-mail / stockage. On ne renvoie jamais les données brutes.
  return res.status(201).json({ status: 'received' });
});

// 404 JSON pour toute autre route
app.use((_req, res) => res.status(404).json({ error: 'not_found' }));

// Gestion d'erreurs : jamais de stack trace vers le client
// eslint-disable-next-line no-unused-vars
app.use((err, _req, res, _next) => {
  if (err.type === 'entity.parse.failed') return res.status(400).json({ error: 'invalid_json' });
  if (err.type === 'entity.too.large') return res.status(413).json({ error: 'payload_too_large' });
  console.error(err);
  return res.status(500).json({ error: 'internal_error' });
});

const port = Number(process.env.PORT || 3000);
app.listen(port, () => console.log(`contact-api sur le port ${port}`));
