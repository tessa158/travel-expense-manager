# Manual test checklist

Run through this after setup. Tick each line.

**Auth**
- [ ] Register with a new username/email → redirected to Login → log in → Dashboard
- [ ] Registering the same username or email again shows an error under the field
- [ ] Wrong password shows an error; 11 wrong attempts in 15 min shows the rate-limit message
- [ ] Logging in at /login with an admin account is refused; /admin/login works for the admin
- [ ] A normal user opening /admin is redirected, and `GET /api/admin/stats` returns 403 for them
- [ ] After Log out, the Back button cannot show private pages (API returns 401)

**Trips and expenses**
- [ ] Create two trips with different currencies; each keeps its own budget and expenses
- [ ] Add, edit, search, filter and delete expenses; Dashboard and Budget totals change immediately
- [ ] Spend past the warning level → notification + yellow alert; past the budget → red alert
- [ ] USD expense in an INR trip: rate is labelled Manual (or Live if an API key is set); original amount, rate and converted amount are shown in the table
- [ ] Receipt: a .txt file is rejected; a file over 5 MB is rejected; a valid file can be opened
- [ ] A second user cannot open the first user's trip (`/api/trips/<id>` → 404)

**Groups and reports**
- [ ] Add participants, add an equal split and a custom split; "Who owes whom" matches by hand
- [ ] Settling more than owed is rejected; a valid settlement reduces the balance; Undo restores it
- [ ] Reports: PDF and CSV open and match the on-screen numbers

**Admin**
- [ ] Deactivate a user → they are logged out and cannot sign in; reactivate restores access
- [ ] Add / rename / deactivate a category (deactivated one disappears from the expense form but old expenses keep it)
- [ ] Audit logs show logins (success and failure), status changes, category changes; filters work
