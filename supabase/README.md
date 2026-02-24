# Supabase Backend

This directory contains:

- `migrations/`: versioned SQL schema and policy migrations
- `functions/`: Supabase Edge Functions (Terra webhook/connect/status/admin metrics)
- `seed.sql`: local trial data seeding

## Local usage

```bash
supabase start
supabase db reset
```

`db reset` applies migrations and `seed.sql`.
