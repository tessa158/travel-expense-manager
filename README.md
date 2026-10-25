# Travel Expense Manager

A full-stack semester project: track trips, budgets and expenses, split group costs, convert currencies, upload receipts, download PDF/CSV reports, and manage the system from an admin panel.

**Stack:** React + Vite · Node.js + Express · MySQL (mysql2) · bcrypt + sessions · Recharts · Lucide · Axios · Multer · PDFKit

---

## 1. What you need to install (once)

| Tool | Version | Check in PowerShell |
|---|---|---|
| Node.js (LTS) | 20 or newer | `node -v` |
| MySQL Server + MySQL Workbench | 8.0 or newer | open Workbench and connect |
| VS Code | any | |

## 2. Create the database (MySQL Workbench)

1. Open **MySQL Workbench** and connect to your local server (the root connection is fine).
2. **File → Open SQL Script…** and choose `database/schema.sql`. Click the lightning-bolt **Execute** button. This creates the `travel_expense_manager` database and all tables.
3. **File → Open SQL Script…** and choose `database/seed.sql`, then Execute. This adds:
   - required data: roles, the six default categories, and settings;
   - **optional demo data** (a fake user `demo_user`, two demo trips and sample expenses, all labelled "DEMO DATA").
4. In the left *Schemas* panel press the refresh icon and check that `travel_expense_manager` has about 13 tables.

> Do not want demo data? Open `seed.sql` and delete everything below the line `Part 2`, or just delete the demo user's trips later.
> To start over completely: run `DROP DATABASE travel_expense_manager;` and repeat steps 2-3.

## 3. Configure the project

Open the project folder in VS Code (**File → Open Folder → travel-expense-manager**), then open a terminal (**Terminal → New Terminal**, PowerShell) and run:

```powershell
Copy-Item .env.example .env
node -e "console.log(require('crypto').randomBytes(48).toString('hex'))"
```

Open the new `.env` file and:
- paste the long random text after `SESSION_SECRET=`
- set `DB_PASSWORD=` to your MySQL password (and `DB_USER` if you do not use `root`)

Everything else can stay as it is. `.env` is in `.gitignore`, so your secrets are never committed.

## 4. Install dependencies

```powershell
npm run install:all
```

(This installs the backend and frontend packages. `bcrypt` downloads a prebuilt binary; if it ever fails, make sure you are on a current Node LTS version.)

Check that the database connection works:

```powershell
npm run check
```

You should see `OK` lines for the connection and every table. Fix any `FAIL` before continuing.

## 5. Create the administrator account

There is deliberately **no public admin sign-up**. Admins are created by someone with access to the server:

```powershell
npm run create-admin
```

Enter a username, email and a password (at least 10 characters, with letters and numbers). The password is hidden while typing and stored only as a bcrypt hash.

## 6. Run the app (two terminals)

**Terminal 1 - backend (port 4000):**
```powershell
npm run dev:backend
```
**Terminal 2 - frontend (port 5173):** click the **+** in the VS Code terminal panel to open a second terminal, then:
```powershell
npm run dev:frontend
```

Open **http://localhost:5173**

- Travellers: http://localhost:5173/login
- Administrators: http://localhost:5173/admin/login

**Demo traveller login:** `demo_user` / `Demo@12345` (only if you ran the demo part of `seed.sql`; this is a demo account).

## 7. Try the full workflow

1. **Register** a new account → you are sent to **Login** → log in → you land on the **Dashboard**.
2. **Trips → New trip** (name, destination, dates, budget, currency).
3. **Expenses → Add expense**. Try:
   - a different currency (e.g. a USD expense in an INR trip) — enter the rate manually (labelled *Manual rate*) or get a live rate if you configured `EXCHANGE_RATE_API_KEY`;
   - attaching a receipt (JPG/PNG/WEBP/PDF up to 5 MB) and opening it with the paperclip button.
4. **Dashboard / Budget**: watch totals, charts, the progress bar and daily allowance update. Push spending past your warning level to get a notification (bell icon).
5. **Group splits**: add participants, then add an expense with *Split this expense*. See *Who owes whom* and press **Settle** to record a payment.
6. **Reports**: pick a trip, then download the **PDF** or **CSV**.
7. Log out, then log in at **/admin/login** to see user management (activate/deactivate), categories, the system overview, settings, and **audit logs** (filter by action, result, date).

## 8. Optional: live exchange rates

Create a free key at https://www.exchangerate-api.com, put it in `.env` as `EXCHANGE_RATE_API_KEY=...` and restart the backend. Without a key the app **never invents rates**: you type the rate and it is labelled "Manual rate". The key stays on the server and is never sent to the browser.

## 9. Production-style run (optional)

```powershell
npm run build
$env:NODE_ENV="production"; npm run start --prefix backend
```
The backend then also serves the built React app at http://localhost:4000. In production use HTTPS (secure cookies are enabled automatically) and a strong `SESSION_SECRET`.

---

## Project layout

```
travel-expense-manager/
├─ frontend/            React + Vite app (pages, components, api, context, styles)
├─ backend/
│  ├─ src/config        env + database pool
│  ├─ src/middleware    auth, roles, validation, uploads, rate limits, error handler
│  ├─ src/routes        Express routers
│  ├─ src/controllers   request handlers
│  ├─ src/services      budget maths, currency, balances, reports
│  ├─ src/scripts       create-admin, check
│  └─ uploads/          private receipt files (never served as static files)
├─ database/schema.sql, seed.sql
├─ documentation/       API, database and test notes
├─ .env.example
└─ README.md
```

## Security summary

bcrypt password hashing (cost 12) · HTTP-only, SameSite session cookies stored in MySQL, new session id on login · every SQL statement parameterized · zod validation on the backend · role checks enforced on the server (`/api/admin/*` is admin-only; user APIs are user-only) · every trip/expense/receipt query is scoped to the logged-in user · uploads limited by type, size and file signature, stored under random names and served only through an ownership-checked route · login rate limiting · deactivated users are blocked immediately · audit log of sign-ins, account changes and admin actions · secrets only in `.env`.

## Troubleshooting

| Problem | Fix |
|---|---|
| `SESSION_SECRET is missing` | Complete step 3 (create `.env`, paste the generated secret). |
| `ER_ACCESS_DENIED_ERROR` | Wrong `DB_USER` / `DB_PASSWORD` in `.env`. |
| `Unknown database` / tables missing | Run `schema.sql` (step 2), then `npm run check`. |
| Browser says "Cannot reach the server" | Backend is not running (step 6, terminal 1). |
| Port 4000 or 5173 busy | Change `PORT` in `.env` (and the proxy target in `frontend/vite.config.js`). |
| Too many failed logins | Wait 15 minutes (login rate limit) or restart the backend. |

See `documentation/` for the API list, database notes and a manual test checklist.
