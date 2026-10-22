# Income Manager

A personal finance web app using plain HTML/CSS/JavaScript, Supabase Auth + PostgreSQL, GitHub, and Netlify.

## Features
- English UI, BDT (৳), responsive card-grid layout
- Email/password authentication
- Income, expenses, loans, repayments: create, edit, delete
- Dashboard, charts, date filters, reports and CSV export
- JSON backup and restore
- Light/dark theme
- Row Level Security (RLS) policies
- Starts with no demo transactions

## Files
- `index.html` — complete frontend
- `supabase.sql` — schema, indexes, triggers and RLS policies

## Setup

### 1. Create Supabase project
1. Open https://supabase.com and create a project.
2. Open **SQL Editor**, create a new query, paste all of `supabase.sql`, and run it.
3. Open **Project Settings → API** (or API Keys).
4. Copy the Project URL and the **publishable key** (or legacy `anon` key). Never use a `service_role` or secret key in browser code.

### 2. Configure the frontend
Open `index.html` and find:
```js
const SUPABASE_URL = 'YOUR_SUPABASE_PROJECT_URL';
const SUPABASE_ANON_KEY = 'YOUR_SUPABASE_PUBLISHABLE_OR_ANON_KEY';
```
Replace the two placeholder strings with your actual Project URL and publishable/anon key. These browser keys are intended for public clients; database security must come from RLS. Do not put any secret/service-role key in this file.

### 3. Create your account and restrict signups
1. For first setup, deploy the site and use **Create your account** with your own email and a strong password.
2. Confirm your email if Supabase requires it.
3. After you have your account, go to **Supabase Dashboard → Authentication → Sign In / Providers** and disable public signups if the option is available for your configuration. If you need to regain access later, use Supabase Dashboard/admin tooling rather than leaving public signups open.
4. In Authentication URL Configuration, set the production site URL and allowed redirect URLs to your Netlify URL. If email confirmation is enabled, verify the confirmation link returns to the correct site.

### 4. Deploy with GitHub + Netlify
1. Create a GitHub repository, e.g. `income-manager`.
2. Upload `index.html`, `supabase.sql`, and `README.md` to the repository root.
3. In Netlify, choose **Add new site → Import an existing project**, connect GitHub, select the repository.
4. Build command: leave blank. Publish directory: `.` (repository root).
5. Deploy. Every push to the connected branch will trigger a new deployment.

### 5. Verify
- Sign in with your own account.
- Confirm dashboard amounts begin at ৳0.00.
- Add one test income, expense, loan and repayment; verify totals and outstanding debt.
- Create a second test account only in a controlled test project if you want to test RLS; confirm one user cannot see another user's records.
- Test JSON export, then restore only after downloading a fresh backup.
- Test mobile layout and theme toggle.

## Financial calculation rules
- Net Balance = Total Income − Total Expenses.
- Borrowing is not income.
- Loan repayments reduce outstanding debt; they are not included in ordinary expense totals.
- Outstanding loan = loan principal − recorded repayments.
- This app is a personal ledger; net balance is not a bank-account/cash balance unless you separately track opening cash and transfers.

## Important limitations / hardening before relying on it
- The first version uses a single static HTML file and CDN dependencies. It is easy to deploy, but production hardening should include pinning dependency versions, a Content Security Policy, stronger error handling, and automated tests.
- The current frontend's backup restore is not a single database transaction. If import fails partway through, restore from the saved backup and inspect records before using it again.
- Public signup must be disabled in Supabase after your own account is created if this is intended for personal use only.
- RLS protects row access, but it does not replace account security: use a strong password, enable MFA if available, and secure your email account.
- Keep regular off-site JSON backups. Do not store a secret key in frontend code or GitHub.
