# API reference

All routes are under `/api`. Responses are JSON; errors look like `{ "message": "...", "errors": { "field": "..." } }`.
"User" routes need a logged-in account with role `user`; "Admin" routes need role `admin` (checked on the server).

## Auth
| Method | Path | Notes |
|---|---|---|
| POST | /auth/register | username, email, password, full_name? |
| POST | /auth/login | traveller login (rate limited) |
| POST | /auth/admin/login | admin login (rate limited) |
| POST | /auth/logout | |
| GET | /auth/me | current user |

## User
| Method | Path | Notes |
|---|---|---|
| GET/POST | /trips | list (`?archived=true|false|all`), create |
| GET/PUT/DELETE | /trips/:id | |
| PATCH | /trips/:id/archive | `{archived: bool}` |
| PATCH | /trips/:id/threshold | warning % |
| GET | /trips/:id/budget | totals, daily allowance, category breakdown |
| GET/POST | /trips/:id/participants | PUT/DELETE `/trips/:id/participants/:pid` |
| GET | /trips/:id/balances | who owes whom |
| GET/POST | /trips/:id/settlements | DELETE `/trips/:id/settlements/:sid` |
| GET/POST | /expenses | list filters: trip_id, search, category_id, payment_method, from, to, page, limit. POST is multipart (receipt file optional) |
| GET/PUT/DELETE | /expenses/:id | PUT is multipart |
| GET | /receipts/:id | private receipt download (owner only) |
| GET | /categories | active categories |
| GET | /currency/config, /currency/rate?from=&to= | rate needs EXCHANGE_RATE_API_KEY |
| GET | /dashboard | `?trip_id=` or `?currency=` |
| GET | /reports/trips/:id, /csv, /pdf | |
| GET/POST | /notifications, /notifications/read-all, /notifications/:id/read | |

## Admin
| Method | Path |
|---|---|
| GET | /admin/stats |
| GET | /admin/users, /admin/users/:id |
| PATCH | /admin/users/:id/status |
| GET/POST/PUT/PATCH | /admin/categories, /admin/categories/:id, /admin/categories/:id/status |
| GET/PUT | /admin/settings |
| GET | /admin/audit-logs (filters: action, status, from, to, search, page) |

## Money rules
- `Remaining = Total budget - Total expenses`; `Daily allowance = Remaining / Remaining trip days` (no allowance when 0 days are left; a negative balance gives 0).
- Every expense stores the original amount, currency, exchange rate, rate source (`same` / `manual` / `api`) and the converted amount in the trip's currency. Editing an expense without changing the currency/rate keeps the stored rate.
- A trip's currency cannot change once it has expenses.
- Split shares are stored in the trip currency; equal splits distribute leftover cents to the first people; custom shares must add up to the amount.
- "Who owes whom" is pairwise (net of both directions) and reduced by recorded settlements. There is no multi-person debt optimization by design.
