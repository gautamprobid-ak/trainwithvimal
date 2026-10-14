# Har screen, har button — behaviour spec

Ye file batati hai ki **har screen pe kya-kya hai, har button/row/chip click karne pe kya hota hai, kaun sa modal / drawer / sheet / dropdown khulta hai, usme kaun se option hain, aur mock data me kya dikh raha hai.**

**Source:** design canvas artifact ke live boards — har board ka markup + uska `DCLogic` script. Clash hone pe **ye file jeetti hai** (purane design sets aur use-case notes se upar).

**Padhne ka tarika**
- Har screen ka ek section: *Kya hai → Har control → Modals/drawers → Mock data*.
- UI labels English me hi likhe hain (jaisa design me hain), baaki explanation Hinglish me.
- "Web" = 1440 board, "Phone" = 390 board. Jahan phone alag behave karta hai wahin likha hai; warna phone web jaisa hi hai sirf layout chhota.
- Jo cheez design me *abhi* mock hai (koi backend call nahi) wo "mock" likh ke mark ki hai.

---

## 1. Shell — sidebar, header, phone nav

### Sidebar (web, admin + trainer)
240 px ka left rail, har web page pe. Items 34 high, radius 8; hover aur active dono #FAFAFA + 1px line, active ka icon accent blue.

| Control | Click pe |
|---|---|
| Koi bhi nav item | Us page pe chale jaate ho. Rail wahin rehta hai, sirf right panel badalta hai. |
| `Approvals` ka count chip (5) | Alag se clickable nahi — sirf batata hai kitne waiting hain. |
| Edge chevron (round 28) | Rail 240 ↔ 68 collapse/expand. Collapsed me labels tooltip, group labels divider, count corner badge. |
| Brand block | Click target nahi — admin: "Owner workspace", trainer: "Trainer workspace". |

**Admin rail:** Dashboard · Clients · Approvals · Trainers · Calendar · Activity log — **Build:** Programs · Exercises · Nutrition & foods · Habits & supplements · Forms & check-ins · Content library — **Engage:** Automations · Emails & alerts — **Workspace:** Settings.

**Trainer rail:** Dashboard · My clients · Check-ins · Calendar — **Library:** Programs · Exercises · Nutrition & foods · Habits & supplements · Content library — **You:** My profile.

### Page header
Title left, actions right ek line me. Title 28 → 20 shrink, max 2 line. ~760px se neeche outline buttons icon-only; phone pe har button icon-only. Search icon → search focus. Bell → notifications (dot jab unread). Profile (round 36) → account menu. Main action → page ka primary drawer/modal.

### Phone nav
Bottom bar, 5 tab. **Admin:** Home · Clients · Approvals (badge 5) · Calendar · More. **Trainer:** Home · Clients · Check-ins · Calendar · More. **Client:** Home · Train · Food · Progress · More.

**More page** (admin/trainer) — upar account card (naam + role, tap → Settings / My profile), fir groups rows ki tarah, sabse neeche laal `Log out` (→ login screen).

---

## 2. Admin

### 2.1 Dashboard — `AdminDashboard` / `AdminDashboardMobile`
Greeting **"Good evening, Vimal"**, neeche *"Thursday, 8 October · 3 things need you today"*. Upar se: 4 stat cards → 6 "at a glance" tiles → Needs action + Trainer performance, At-risk clients + Recent activity.

**Stat cards:** Active clients **142** (+8 this month) · Pending approvals **5** (Oldest waiting 2 days) · Check-in rate **86%** (−2% vs last week) · Avg adherence **81%** (+3% vs last week). Upar wala delta green, neeche wala red.

**At a glance tiles:** Clients 156 (142 active · 14 paused → Clients) · Trainers 8 (1 over capacity, amber → Trainers) · Check-ins to review 12 (4 waiting over 48 h, amber → Check-ins) · Onboarding pending 5 (2 forms not complete → Clients onboarding filter) · Nutrition plans pending 4 (Clients without a meal plan → Nutrition) · Programs ending 2 (This week · plan what is next → Programs).

**Needs action:** kind chips `All` · `Approvals` · `Clients` · `Check-ins` · `Trainers` · `Programs` (count; zero-row kinds hidden). Row CTA (`Review` / `Open` / `Assign` / `Rebalance` / `Plan` / `View`) → us kaam ki screen. Row × → dismiss (permanent in mock). `Show all N` / `Show less` (5 ↔ all). Sab dismiss → *"All clear. Nothing needs you right now."* Rows oldest first. Mock: 5 sign-ups waiting · 4 check-ins waiting over 48 hours · 3 clients need a trainer · Arjun Rao is over capacity (24 of 20) · 2 programs end this week · Aisha Sheikh flagged low energy · 2 clients have not logged in 7 days · Neha Jain asked to change trainer · Meera Shah has 5 replies pending.

**Trainer performance:** Trainer · Clients · Adherence (bar) · Avg reply. Lowest adherence first, 5 rows, `Show all 8 trainers`. Load `24 / 20` red when over. `This week` select (mock).

**At-risk clients:** 3 rows, `Show all 7`, row `Remind`. Header `Remind all` → modal **"Remind 7 at-risk clients?"** with checked *"Skip clients reminded in the last 24 hours (2)"*, `Cancel` + `Remind 5 clients`.

**Recent activity:** 5 rows (kaun + kya + kab), long text tooltip. `View all` → Activity log.

### 2.2 Clients — `Clients` / `ClientsMobile`
Title **Clients**, sub *"14 clients · 11 active · 3 need a trainer"*. Header `Invite link` (outline) + `Add client` (primary). Tabs `All 14` · `Active 11` · `Pending` · `Paused` · `At risk`. Search *"Search name or email"*, `Filter`, `Export`.

**Filter:** Trainer (Anyone / Aman Verma / Meera Shah / Neha Joshi / Sahil Kapoor / No trainer) · Goal (Any / Fat loss / Muscle gain / Strength / Recomp / General fitness) · Onboarding (Any / Done / Not started / In progress) · Next check-in (Any / Today / This week / Overdue) · Joined (Any time / Last 30 days / This year). Pick → chip, `Filter · 2`, `Clear filters`. Export → CSV (mock). Row → profile. 3-dot: `View profile` · `Edit details` · `Change trainer` · `Pause` · `Delete client` (red). Status: `Active` green · `Pending` amber · `Paused` grey · `No trainer` amber · `At risk` red. Phone: rows → cards, tap → actions bottom sheet.

**Add client drawer:** Full name (`Kavya Menon`) · Phone (`+91`, hint *"No client or sign-up with this number"*) · Email (*"For login links and receipts"*) · Gender (`Female`) · DOB (`DD / MM / YYYY`) · City (`Bengaluru`) · Goal (`Lose fat`) · Current weight (`62 kg`) · Height (`160 cm`) · Target weight (`68 kg`) · Health notes (*"Back pain, thyroid, recent surgery…"*) · Trainer (`Aman Verma · 24 / 30`, *"You can change this later"*) · Program (`Pick later`) · Start date (`Mon, 12 Oct`, *"Her day 1 for workout and meal plans"*). Toggles *"Send her the login link"* and *"Ask her to fill the health form (PAR-Q)"*. Mode chips **`Active now`** (*"She can log in as soon as she opens the link."* → button `Add client`) / **`Send to Approvals`** (*"She shows up in Approvals first, like people who sign up with a link."* → `Add and send to Approvals`). Footer *"Only name and mobile are needed"*.

**Invite link drawer** (3 tabs): **Invite link** — `trainwithvimal.app/join/AMAN-4821`, `Copy link` · `WhatsApp` · `Email` · `Download QR`; Link settings: trainer (*"This trainer sees them first"*), toggle **"New sign-ups wait in Approvals"** (*"You approve each person before they can log in"*; on → *"She waits in Approvals. You or Aman Verma approve her, then she can log in."*, off → *"She can log in straight away. Aman Verma gets a notice."*); preview *"What she sees when she opens the link"*; `Done`. **New link** — Trainer · label (`Instagram · October`, *"Only you see this"*) · Expiry (`30 days · till 8 Nov`) · Max people (`No limit`) · Code (`AMAN-5530`, *"Made from the trainer name"*) · *"The old links keep working"*; `Create link` → new link on top, opens in Invite link tab. **All links N** — code, label, trainer · made · till, `N joined`, `N waiting`, status `On`/`Off`/`Ended`; row → opens link; 3-dot `Open link and QR` · `Copy link` · `Turn off`/`Turn on` · `Delete link`; summary *"4 of 5 links are on"*. Mock: AMAN-4821 (6 joined, 1 waiting) · VIMAL-0007 "Website" (41) · NEHA-3307 "Instagram · Sept" (20 people · 3 used) · SAHIL-1190 (9) · MEERA-2210 "Yoga batch" (Ended 8 Oct).

**Mock clients:** Riya Sharma (Active, Done) · Rohan Kapoor (40%) · Neha Jain (Pending, Not started) · Kabir Mehta · Ananya Iyer (Paused, 9 d ago) · Sana Khan (No trainer) · Aisha Sheikh (At risk) · Priya Reddy (20%).

### 2.3 Approvals — `Approvals` / `ApprovalsMobile`
Sub *"5 people waiting · oldest waiting 2 days · new sign-ups from invite links land here"*. Header `Invite link` + `Add client` (same drawers). Tabs `Waiting 5` · `History 6`.

Waiting row: person · Invited by · Profile setup (5 pips `3 of 5`) · Health note badge · Signed up from (Web / Android app / iPhone app) · Waiting (amber >1 day, red >2 days) · `Review`. Filter (Waiting): Invited by · Profile setup (Any / All 5 done / Not finished) · Waiting (Any time / Over 1 day / Over 2 days) · Health note · Signed up from. Filter (History): Decision · Decided by · When. Empty: *"No one matches these filters."* Footnote *"Showing N of 5. Sorted oldest first. Amber after 1 day, red after 2 days."* Invite-link summary card (top 3 links).

**Review drawer:** `‹` `›` between waiting people (wraps). Profile setup 5 steps: Account made · Basic details · Goal and body · Health and PAR-Q (7 questions) · Food preferences (*"Not done"*). From her onboarding: Goal / Body / Trains / Food (empty → *"She has not filled her goal and body details yet. Ask for info to remind her."*). Health note (Pooja Nair — *"High blood pressure, on medicine. Ask for a doctor note before hard sessions."*). Trainer list with load bar and tags `Invited her` / `Good fit` / `Full` (full not clickable; default = inviter; *"5 of 7 have space"*). When you approve toggles: *"Tell her on WhatsApp and email"*, *"Ask her to finish setup"*. Footer `Reject` · `Ask for info` · **`Approve and assign`** (5/5) / **`Approve anyway`**.

**Reject modal:** `Not a fit for our coaching` · `Already has an account` · `Wrong or fake details` · `No trainer free right now` · `Something else`; message box; toggle *"Tell her by email"*; `Cancel` + `Reject`.
**Ask for info modal:** multi-select `Finish profile setup` · `Fill the health form again` · `Send a doctor note` · `Add a profile photo` · `Check her phone number`; channels `WhatsApp` (on) · `Email` (on) · `App notice` (off); `Send request`, *"2 things asked"*.
**History:** decision `Approved`/`Rejected`, reason/trainer, decided by, when; `Move back` → modal explaining effects, toggle, `Move back`.

Mock waiting: Pooja Nair (2 days, health note, 3/5) · Ishaan Mehta (1 day, 5/5) · Neha Jain (5 h, 2/5) · Ananya Gupta (3 h, 4/5, health note) · Rohit Sinha (40 min, 5/5).

### 2.4 Exercise library
Sub *"28 built-in · 0 custom by your team"*. `New exercise`. Cards: thumb, name, muscle · equipment · level badge (Beginner green, Intermediate amber), *"2 programs"* / *"No program yet"*. Filter panel categories Muscle · Equipment · Level · Source, multi-select with tick, chips with ×, `Clear all`. `Sort`. Default Muscle = Chest. Counts: Chest 5, Back 5, Legs 5, Shoulders 3, Arms 3, Core 2, Cardio 1.

### 2.5 Exercise detail
`Exercises › Barbell Bench Press`, thumb (0:42), *"Chest · Barbell · Built-in exercise"*. `Duplicate to edit` · `Add to program` · 3-dot. Default sets: `kg × reps` · Sets 4 · Reps 6–8 · Rest 2 min · RPE 8/10 · Tempo 3-1-1. Tabs `How to 4` · `Form cues 3` · `Muscles 3` (default Muscles: Primary Chest · Pectorals; Also works Triceps `Strong`, Front shoulders `Light`; body map Front/Back). Video card · Details card · Used in 2 programs (Fat Loss Phase 1 · Upper A · 12 workouts · 4 clients; Hypertrophy · Push / Pull / Legs · Push A · 8 workouts · 4 clients) → Program builder.

### 2.6 Add exercise
Name, muscle, equipment, level, video + cover, How to steps and Form cues (add/remove), default sets/reps/rest/RPE/tempo, muscles (primary + also-works Light/Strong). Save → detail.

### 2.7 Trainers
Sub *"8 in the team · 7 active · 129 clients"*. `Add trainer`. Stats: Active trainers 7 (1 inactive) · Client spots 129 / 215 (86 spots free) · Check-ins to review 11 (Karan has the most (4)) · Avg adherence 82% (+2% vs last week). Tabs `All 8` · `Active 7` · `Full 1` · `Inactive 1`. Row: speciality · clients bar (amber 80%+, red + `Full`) · check-ins · adherence (<80% amber) · access · status · joined · 3-dot (`Open profile` · `Access and permissions` · `Edit details` · `Move clients to another trainer` · `Deactivate`; inactive: `Reactivate`). Deactivate modal explains clients. Filter: Access · Space · Speciality · Check-ins. Add trainer drawer: Full name (`Tara Pillai`) · Phone · Email · Gender · Speciality · Max clients (30) · Bio · Joining date; access chips Assigned / All / Custom with explanation lines; toggles *"Send the login invite"*, *"Give them clients now"*; footer *"They cannot add trainers or change gym settings"*.

### 2.8 Activity log
Sub *"Every change by your team, your clients and the system."* `Export`. Grouped by day (Today · Yesterday · Wed, 7 Oct · …). Row: who + what · change (`60 s → 90 s`) · kind · when. Date range (`Today` · `Last 7 days` default · `Last 30 days` · `Last 3 months` · `All time`). Kind chips `All` · `Check-in` · `Plan` · `Workout` · `Meal` · `Body` · `Client` · `Content` · `System`. Filter Who / Person. `Show more` (+8), *"Showing 8 of 24"*. Empty *"Nothing matches. Try a longer date range or fewer filters."*

### 2.9 Calendar
Sub *"Your team's sessions, 5 – 11 Oct 2026"*. `Availability` + `New session`. Stats: Sessions this week · Done · On a call · Busiest trainer. Toolbar `‹` `›` · `Today` · trainer dropdown (non-working hours grey, `Day off`) · `Week`/`Day` · legend `1:1 session` 60 · `Quick call` 15 · `Program review` 30. Session drawer: kind, client, trainer, time, place/call, note, status `Done`/`Booked`; `Open profile` · `Reschedule` (→ "Move session") · `Mark as done`/`Mark as not done` · `Cancel session` (confirm, toggle *"Tell the client"*, `Keep it` / `Cancel session`). New session drawer: kind chips, client (*"Their client"*), trainer (*"Their trainer"*), week strip, hour + minute chips, In person (`Andheri gym floor`) / Call (`meet.google.com/abc-defg-hij`), note, *"Tell the client"*, live clash check (*"Aman is free at this time"* / *"Aman already has Riya Sharma at 7 – 8 am"* disables create / outside working hours). Availability drawer per weekday toggle + times, `Save availability`. Body scan kind parked.

### 2.10 Programs
Sub *"Master plans for your clients. Change one and everyone following it gets the update."* Tabs `Active 5` · `Archived 1`. Card: name, goal, weeks, days/week, 7-dot week pattern, avatars, *"Edited 2 Oct"* / *"Not assigned"*. 3-dot `Open` · `Duplicate` (toast + Undo) · `Archive`/`Restore` · `Delete` (confirm *"…unassigned from 4 clients. Workouts they already logged stay safe."*). `New program` modal: name, Weeks stepper (1–24, 8), Days per week (1–7, 4), preview. Mock: Fat Loss Phase 1 (12 wk, 5 d, 4) · Hypertrophy · Push / Pull / Legs (8 wk, 4) · Beginner Full Body (4 wk, 1) · Yoga Strength (6 wk, 2) · Strength Base (10 wk, 0) · Shoulder-safe Upper Body (Archived).

### 2.11 Program builder
Header name + *"12 weeks · 5 days / week · edited 2 Oct"*, 3-dot (`Rename` · `Duplicate program` · `Archive`/`Restore` · `Delete`), `Assign`. Week strip `W1…W12` + `Copy week N → N+1`. Day cards (summary, first 3 exercises, `+2 more`, rest days, `Add`). Day panel: `≈ 55 min · 16 sets · 6 exercises`, day 3-dot (`Rename` · `Move earlier` · `Move later` · `Make rest day`/`Make workout day` · `Remove day`). Exercise rows (tags 1,2,3 / A1,A2), 3-dot (`Edit sets and rest` · `Edit for this program` · `Reset to library version` · `Exercise details` · `Move up` · `Move down` · `Make superset with next`/`Remove from superset` · `Remove`). Modals: Edit sets and rest (steppers, live summary line), Add exercise picker (muscle chips, multi-select, `On this day` disabled, `Add 3 exercises`), Edit for this program, Add day, Rename day. Assign drawer (`Save · 4 clients`), Clients drawer (`Master`/`Custom` tags). Mock week: Upper A · Push Day · Rest · Pull Day · Legs · Cardio · Rest.

### 2.12 Nutrition & foods
Tabs `Meal plans 4` · `Food library 41`. Meal plans: diet chips, plan cards (kcal + P/C/F bar, `Published`/`Draft`, clients), 3-dot `Open in builder` · `Duplicate` · `Delete`; `New plan` modal (name, diet chips, calories stepper 1200–4000 default 2000). Mock: Cut · Eggetarian (2150, 3 clients) · Lean gain · Non-veg (2800, 1) · Fat loss · Veg (1700, 1, Draft) · Maintenance · Vegan (2200, 0, Draft). Food library: group chips, diet dropdown, table 10/page, per 100 g / per serving toggle, 3-dot Edit / Duplicate / Delete. Food drawer: name, brand, diet, group, serving units (1 g base + suggestions), default serving, nutrition per 100 g or per serving (saved per 100 g), calorie check, alternatives with match %, used in, live preview. Import from Excel (2 steps: choose file → check and import with duplicates choice, calories differ, egg toggle, mappings, preview, `Import 28 foods`). Recipes parked.

### 2.13 Meal plan builder
Header *"Eggetarian · Master plan · 3 clients, 1 custom version"*, 3-dot, `Assign`, `Publish`. Targets card (Calories · Protein · Carbs · Fat · Fibre · Water), `Edit targets`. Meals Breakfast 8:00 am 520 · Lunch 1:30 pm 640 · Snack 5:00 pm 260 · Dinner 8:30 pm 730 with option tabs (`Default` badge), meal 3-dot, `Add meal`, option menu (Blank / Duplicate current option), option 3-dot, `Add food` picker, food panel (quantity + unit, swaps, remove). Client permissions toggles. Assign, client 3-dot (version note / reset to master / remove). Publish modal.

### 2.14 Habits & supplements
Tabs `Habits 8` · `Supplements 3`; master-detail editor with live phone preview, unsaved bar (`Discard` / `Save changes`), `Assign`, `New habit`. Mock habits: Drink 3 L water · 8,000 steps · Sleep by 11 pm · Hit protein target (150 g) · 10 min mobility (Mon, Wed, Fri) · Morning sunlight · No sugary drinks · Strength session (3 times a week). Supplement plans: Muscle gain basics · Fat loss support · Vegetarian essentials; items grouped by timing; quick add chips.

### 2.15 Forms & check-ins
Type dropdown, tabs `All 8` · `Archived 0`. Row: name · type · questions · sent by automation · status · edited · 3-dot (`Edit questions` · `Preview` (fillable) · `Duplicate` · `Archive`/`Restore` · `Delete form`). `Create form` modal: 5 types + `Template` / `Blank form`. Mock: New client questionnaire (15) · PAR-Q health screening (7) · Weekly check-in (9) · Morning check-in (5) · Bridal Shred intake (7) · Monthly feedback (4, Draft) · Liability waiver (3) · Photo consent (2).

### 2.16 Form builder
Header 3-dot, `Preview`, `Publish`. Questions with number, type, `Required`. Question 3-dot. Add question — 9 types. Editor: text, options, "Other" toggle, help, Required. Side: Automation, Answers.

### 2.17 Content library
Categories rail (Exercise videos · Form tutorials · Onboarding · Nutrition guides · Mindset & sleep), kind filter, cards, 3-dot (`Open` · `Edit` · `Assign to clients` · `Delete`), detail drawer (player, shared with, used in, stats), new/edit drawer per kind, assign drawer.

### 2.18–2.20 Automations / New automation / Automation builder
Stats: Automations on 3 of 5 · Clients in a flow 43 · Messages this month 214 · Tasks for trainers 9. Cards with trigger + step chips + status + toggle. Mock: Client onboarding · Weekly check-in · Missed workouts nudge (Off) · Renewal reminder · Birthday wish (Draft). Starters: Client onboarding · Weekly check-in · Missed check-in reminder · Missed workouts nudge · Renewal reminder · Welcome week · Birthday wish + Blank. Builder: 15 triggers in groups Client / Schedule / Activity / Progress with settings blocks, scope, *"Stop when the client responds"*, steps (Wait / Send message / Send form / Assign task; channels Email · Push · WhatsApp · In-app), preview, runs log.

### 2.21 Emails & alerts
Tabs `Client messages` · `Team alerts` · `Sender`. Templates grouped Access · Coaching · Packages; channel tabs with toggles, counters, variables, reset, live preview; `New template` modal. Team alerts events + quiet hours 10:00 pm – 7:00 am. Sender identity.

### 2.22 Settings
Gym profile · Regional & defaults · Branding (logo, accent, theme, preview, Reset / Apply) · Roles & permissions (Admin / Trainer / Client cards, permission matrix, admin locked) · Integrations (WhatsApp, Email domain with DNS table, Health app; Disconnect confirm).

### 2.23 Client profile
Header RS **Riya Sharma** `Active` *"Fat loss · 68 kg goal"*; `Edit profile` · `Assign plan` ▾ · 3-dot. Stats `86%` (+4% vs last month) · `71.2 kg` (−3.6 kg since start) · `14 of 16` (Done in last 30 days) · `6 of 7` (Week 6 waiting for review). Tabs Overview · Plans (4) · Logs · Progress · History · Content (8) · Forms (4) · Activity · Notes (4). Overview cards: About Riya · Weight trend (range picker) · Last 7 days · Latest note · Needs attention (Knee pain on deep squats · Week 6 check-in to review · Missed Upper B on Monday) · Coaching · Current plans (Fat Loss Phase 1 week 6 of 12 · 1,650 kcal high protein · 2 supplements · 3 habits) · Check-ins and schedule. Plans tab: 4 slots, badges, 3-dot (`Duplicate and edit` · `Replace with another plan` · `Reset to master` · `Open master plan` · `End this plan`), Up next, Plan history, Compare plans. Logs: Workouts · Meals · Daily check-ins · Weekly check-ins · Habits · Supplements. Progress, History timeline, Content, Forms, Activity, Notes (staff only).

### 2.24 Trainer profile
**Aman Verma** `Active` *"Strength, fat loss"*; `Edit details` · `Assign clients` · 3-dot. Stats `24 / 30` · check-ins · `84%` · `3 h`. Tabs Overview · Clients (24) · Access and permissions · Activity · Documents (6) · What clients see. Access levels + permission groups (Clients / Training / Nutrition / Check-ins / Schedule). Docs: ACE CPT (Verified) · Precision Nutrition L1 (Verified) · First aid and CPR (Expires in 33 days) · K11 Diploma (Not checked) · Aadhaar card (Verified) · Trainer agreement (Signed). What clients see toggles with live preview.

### 2.25 More (phone) — Pages: Trainers · Activity log · Build: Programs · Exercises · Nutrition & foods · Habits & supplements · Forms & check-ins · Content library · Engage: Automations · Emails & alerts · Workspace: Settings · Log out.

---

## 3. Trainer area
Trainer ko sirf apne clients dikhte hain (jab tak `All clients` access na ho); settings, trainers, automations, emails kabhi nahi.

### 3.1 Dashboard — *"Good evening, Aman"*, bell (`Mark all read`), `New session`. Stats My clients 24 / 30 · Check-ins to review · adherence · reply time. Cards: Today (sessions, `Done`, 3-dot `Mark as missed` · `Mark as not done` · `Open client profile` · `Cancel session`), Clients who need you (chips `All` · `Missed workouts` · `Not logging` · `Plan ending` · `Feeling low`; `Remind` → toast + Undo → `Reminded`), Check-ins to review (reply box with 3 quick replies), Tasks (from automations), This week, Notices. New session modal (client, date, time, length 30/45/60/90, Gym floor / Video call, note).
### 3.2 My clients — *"24 clients given to you · 21 active · 2 at risk"*, tabs, search, filter, export, row 3-dot `View profile` · `Edit details`, Add client + Invite link drawers (trainer-scoped).
### 3.3 Check-ins — tabs `To review` · `Reviewed` · `All`, kind filter `All types` · `Weekly` · `Daily` · `Monthly`, detail with answers, photos, `Compare with last time`, reply + quick replies, `Open profile`, `Mark as not reviewed`.
### 3.4 Calendar — own sessions, `My working hours`, `New session`, `Today`; session panel and cancel confirm as admin.
### 3.5 Me — tabs Overview · Documents · What clients see · My access (read only, `Ask for more access`) · My activity · Account (password, sessions with `Log out`, notification toggles).
### 3.6 Client profile (trainer) — same as 2.23, breadcrumb `My clients / Riya Sharma`, no `Change trainer`.
### 3.7 More (phone) — Library: Programs · Exercises · Nutrition & foods · Habits & supplements · Content library, `Log out`.

---

## 4. Client app
Tabs Home · Train · Food · Progress · More. Client plan badal nahi sakta, sirf log karta hai: *"Want something changed? Tell Aman in your weekly check-in."* Toast kinds `ok` / `info` / `warn` / `err` / `del` / `star`, Undo where possible.

### 4.1 Home — `Fri, 9 Oct · Week 6 of 12`, bell + `RS`. Today's workout (`Upper A · Strength`, exercises, `+ N more`, `See all exercises`; tick → *"Bench press logged — 1 of 6 done"*, last → *"Workout done! — Aman can see it now"*), Session with, Water (`+250 ml · 1 glass` / `−250 ml`, goal → *"Water goal complete!"* star, too much → warn), Next meal (`Ate it` → toast + Undo, `Log food`, `See all`), Habits (steps stepper `Save steps`, sleep `Save sleep`), Supplements (Whey protein · Vitamin D3 · Magnesium, `Take` → toast + Undo → `Taken`), Coming up, Notices (`Mark all as read`). Targets 1,650 kcal · 120 g protein · 170 g carbs · 52 g fat.
### 4.2 Train — week strip (Mon Upper A ✓ · Tue Lower A ✓ · Wed Rest · Thu Upper B ✓ · Fri Cardio today · Sat Lower B · Sun Rest), `Today · Fri, 9 Oct`, `Completed today`, `History`, blocks Cardio / Conditioning / Core, exercise detail sheet (Today's target, Last time, How to, Form cues, Muscles, PR), `Start workout`.
### 4.3 Workout logger — timer, rest chip, 3-dot (`Past workouts` · `Restart workout` · `Remove logged work`), `Finish`. Per exercise target + PR + `How to do it`, kg/Bodyweight, set rows (Prev, weight, reps, Done; `Delete set` + Undo; `Add set`; warm-up / working toggle), rest timer (`−15s` / `+15s` / `Skip rest`), `Previous` · `Next exercise` · `Finish workout`. Finish: Where the time went · How hard was it? · Note for Aman · `Save and send to Aman` (*"Workout saved — 18 of 22 sets"*). Discard / restart confirms. `New best` badge.
### 4.4 Food — meal cards with `Mark as eaten` / `Undo` / `Swap` / `Edit portions` (sheet, `Save portions`) / `Ate something else` / Skip (warn) / `Eaten after all`.
### 4.5 Log food — `Add to` meal, search, groups, recent foods, `+`, tags `Mine` / `Off-plan`, Quick add (kcal required), Create custom food (`Save food`), `Done · back to meal plan`.
### 4.6 Nutrition — `Today's calories` ring, This week bars, water widget, logged entries (delete + Undo), `Log food`, `Copy yesterday`, `Open full meal plan`, info modal.
### 4.7 Progress — Weight chart (71.2 kg, Goal 68 kg, ranges `4 wk` · `12 wk` · `6 mo` · `All`, `Log weight` modal), Measurements, Progress photos (`Add photos`, `Compare`), Lifts (Bench press 30 → 45 kg), Adherence (92, 90, 82, 85, 80, 86).
### 4.8 Habits & supplements — 9-day strip, habits with `Details` sheet, supplements plan "Fat loss basics" with `Take` / un-tick toasts.
### 4.9 Check-ins — tabs Weekly · Daily; daily scales + send toast; weekly 6 questions + photos + review + send; history.
### 4.10 Library — filters `All` · `Videos` · `PDFs` · `Images` · `Articles` · `Saved`, pills `New` / `Done`, viewers.
### 4.11 More — tabs Overview · Notifications · My activity; Profile, Your plan, My trainer, Reminders, Units, Privacy, Help, About, Account (Delete account, Log out confirm), footer `Train With Vimal · Version 1.0.0`.
### 4.12 About — Contact, App, terms/privacy, `© 2026 Train With Vimal · Made in India`.

---

## 5. Login, join link, onboarding
- **Log in** — Email + Password, `Forgot password?`, `Need help?`, *"New here? Open the invite link your coach sent you."*, approval pending state (*"Aman is still reviewing your account"*, `Check status`, `Log out`), forgot password flow, terms sheet.
- **Welcome / setup** — 5 steps: Your goal · About you · Training days · Health & injuries (injuries None/Knee/Lower back/Shoulder/Neck/Wrist/Ankle; conditions None/Diabetes/Thyroid/High BP/PCOS/Asthma/Heart condition; `Tell Aman more`) · Food preferences. `Finish later` → confirm (`Keep going` / `Save & leave`). Review → `Go to Home`.
- **Intro slides** — `Skip` · `Next` · `Get started`.
- **Join from a link** — invite link (`You're invited`, `Link works`, form, store buttons) / coach login link (`Your coach added you`, `Create my account`) / broken states (expired, turned off, full).
- **Verify email** — `Resend email`, `Change email`, `Log out`, `Confirm my email` → `Continue`.
- **Reset password** — `Send reset link` → new password → `Save new password`; expired → `Send a new link`.
- **Permissions** — Notifications (after verify) · Camera (first progress photo) · Photos (first pick); app sheet then OS dialog; `Not now` / `Open settings`.

---

## 6. Common patterns
- **Data table** — sticky header, right-aligned numbers, row click = detail, last column 3-dot, footnote. Phone: rows → cards, actions in bottom sheet.
- **Filter** — `Filter · 2`, groups with `Any` first, chips with ×, `Clear filters`, empty state.
- **3-dot menu** — red item last, one menu at a time.
- **Modal vs drawer** — modal for small decisions/confirms (destructive copy says what stays); drawer (phone: full sheet) for forms with fixed footer `Cancel` + primary.
- **Toast** — slides up, ~4 s, one at a time, past-tense title, grey detail line, `Undo` before ×. Admin/trainer: dark #1F1F1F, 360 wide, radius 14, Undo light blue. Client: same box, colour per kind (done/milestone accent; info/water #7CC4FF; warn #FFD166; error #FF7A45; delete #2A2C25), round 32 icon tile.
- **Empty states** — title + line + action (`Clear filters` or `New …`).
- **Badges** — `b-ok` green · `b-warn` amber · `b-bad` red · `b-neu` grey.
