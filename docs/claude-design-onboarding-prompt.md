# Bedrock — Onboarding Research & Design Brief

> Read this whole brief before you do anything. It is long on purpose: every section changes what "good" means for this project. Work through the phases in order and stop at the two marked checkpoints.

---

## 0. The short version

Bedrock is an iPhone app that blocks porn, and it is built so that the 2am version of you can't undo what the daytime version of you decided. Tagline: **"Your Last Blocker."**

I need the best onboarding in this category. It has to feel premium, calm and smooth. It has to be short enough that people don't drop off and honest enough that a cynical user who has deleted five blockers trusts it. It also has to convert to premium without a single dark pattern.

Your job, in order:

1. Research every serious competitor in depth: their actual screens, copy, animations, paywalls, permission timing, how easy they are to disable, and what real users say about them.
2. Turn that research into insight: what works, what's manipulative, what nobody does well.
3. Explore several genuinely different directions, test them against the research, and pick the best one (or a hybrid), explaining what you cut and why.
4. Design the final flow down to every word, every animation curve, every haptic, every edge case.
5. Deliver a clickable high-fidelity prototype plus a spec an engineer can build directly in SwiftUI.

Don't give me a generic onboarding. Don't guess when you can find out. Don't present anything you haven't stress-tested yourself.

---

## 1. Who you are on this project

Work as a full team, and let these perspectives argue with each other, not just nod along:

- **Product strategist**: positioning, the one belief the onboarding must create, scope discipline.
- **Behavioral scientist** who understands compulsive behavior and recovery: shame, relapse, motivation, commitment devices, implementation intentions. Not clinical, but evidence-literate.
- **Growth and monetization lead** for subscription apps: onboarding funnels, paywall design, trials, drop-off, LTV.
- **Senior iOS product designer** fluent in the Human Interface Guidelines and iOS 26 (Liquid Glass).
- **Motion and haptics designer**: choreography, springs, timing, Core Haptics.
- **Copy chief**: voice, rhythm, cutting words.
- **Accessibility specialist**: VoiceOver, Dynamic Type, Reduce Motion, Reduce Transparency.
- **Former App Store reviewer**: guideline compliance, Family Controls usage, subscription rules.

---

## 2. The product (context you need)

### 2.1 What Bedrock is

A porn blocker and recovery companion for iPhone. It uses Apple's Screen Time frameworks (FamilyControls, ManagedSettings, DeviceActivity) to block content on the device. Its wedge against every other blocker is that it is **designed to be hard to undo in a weak moment**: an uninstall lock, a Screen Time passcode the user doesn't hold, and a deliberate "disable gauntlet" that turns a 5-second impulse into a 30-minute decision involving their future self and, optionally, another person.

### 2.2 Who it's for

Primarily men, roughly 18–40, who want to stop compulsive porn use. Typical states when they download:

- **Mid-urge or just after a relapse**, often late at night, feeling shame. Wants the wall up *now*.
- **A quiet decision** after something happened (a partner found out, a bad week, feeling numb). Determined, but fragile.
- **Sent by someone**: a partner, spouse, friend or therapist suggested it.
- **The skeptical veteran**: has tried NoFap streaks, Covenant Eyes, blockers, and bypassed every one. Cynical about promises.

Treat these as starting hypotheses and validate or replace them with what you find in reviews and forums.

### 2.3 Positioning

"Your Last Blocker": the one you keep, because it's the one you can't casually take down.

The honesty problem: nothing on iOS is literally impossible to disable (a determined person can erase a phone). We will never claim literal impossibility in a way a user or reviewer could disprove. Find framing that is both true and powerful. Example of the right spirit (not mandatory copy): *"Not impossible to undo. Just impossible to undo at 2am."*

### 2.4 What's already built

The onboarding must sell and set these up **truthfully**. Don't promise anything not on this list without flagging it as a proposed new feature.

**Free (forever):**
- Blocking of chosen apps, categories and websites through Apple's picker, plus Safari's adult-content filter. Re-applied on a daily schedule.
- The Intercept / SOS button ("The urge is here"): breathing / urge-surfing → name what's underneath → a replacement action → log the outcome (rode it out / called my person / slipped). The user's own "why" is shown at the top.
- **Foundation**: a streak that **never resets**. A relapse adds a visible *crack* to their stone monolith that gets repaired; the total foundation days never go down. This is a deliberate anti-shame mechanic and a real differentiator against streak-reset apps.

**Premium (RevenueCat entitlement `pro`):**
- **Strict Mode**: uninstall lock (iOS prevents deleting the app) plus a Screen Time passcode the user doesn't know, in one of two models:
  - **Partner-held**: a trusted person sets and keeps the Screen Time passcode.
  - **Bedrock-held**: the app generates a code and walks the user through entering it into iOS settings digit by digit without being able to memorize it ("blind entry"). The code is released only through the disable gauntlet.
- **The disable gauntlet** (what happens if they try to turn protection off): read a letter from their committed self (forced dwell) → urge-surf breathing plus an urge rating → type a commitment passage (paste blocked, a typo resets it) → message to their partner → a server-validated cooldown that resets if they leave the app → partner approval. It escalates with repeated attempts and has a "sleep on it" option.
- **Accountability partner**: invite by code or link (`thebedrock.app/join/CODE`). The partner sees status, approves disable requests, and gets a supportive "you haven't heard from them in a while" alert if the app goes dark (deleted, Screen Time turned off, phone off).
- **Insights**: on-device detection of the user's "danger windows" (day-of-week × time-of-day), a heatmap, and optional local nudges just before their hardest hours.

**Account and privacy model:**
- No account before using the app. Everything personal stays on the device; the server only knows a random device ID unless the user opts into accountability.
- Optional Sign in with Apple, offered **after** the paywall, so purchases and settings follow them to a new phone.
- Full account deletion in Settings.
- The app icon and name ("Bedrock") are deliberately discreet.

### 2.5 Platform facts that shape the flow (verify each against iOS 26 before you rely on it)

- iOS 26.4 minimum, iPhone only, SwiftUI, iOS 26 Liquid Glass design language.
- **Screen Time permission** is a system prompt we can't restyle. We can design the moment before it (the pre-prompt) and handle approve/deny afterwards. Never mimic the system dialog.
- **The app/website picker** (FamilyActivityPicker) is a system sheet. The selections come back as opaque tokens, so we can't display what they chose by name, only counts.
- The **Safari adult-content filter** can be switched on without the picker.
- The **shield** (what appears when a blocked app or site is opened) is customizable: background, icon, title, subtitle, two buttons. It is the most-seen Bedrock surface in the whole product, and the onboarding is effectively a promise about it.
- **The real lock is the Screen Time passcode.** Without one the user doesn't know, anyone can revoke Bedrock's access in Settings in seconds. Research exactly what a user can still do on iOS 26 (passcode recovery via their Apple Account? device erase? other bypasses discussed on Reddit) and design honest copy around the real answer.
- Deep links into specific Settings screens are limited. Don't design a flow that depends on private URL schemes. Assume we can open our own Settings page and give clear instructions, then detect when the user comes back.
- Notifications permission is the standard system prompt.
- Nothing Screen-Time-related works in the Simulator, so design the "unavailable" state as well, for review and demo builds.

### 2.6 Business model

- RevenueCat, entitlement `pro`, offering `default`.
- Current plans: **Weekly $5.99**, **Annual $69.99 with a 3-day free trial** (the default), **Lifetime $149** (non-consumable).
- A free tier (basic blocking) exists forever, so a free path out of the paywall is always available.
- You may recommend changes to how plans are presented. Raise any change to prices or the trial as a question, with evidence.

### 2.7 Brand and current design system

- **Metaphor:** geology. Bedrock, foundation, strata, stone that cracks and gets repaired, a molten ember core, dawn light.
- **Aesthetic:** obsidian and ember. Cinematic, quiet, weighty. Never cute or gamified.
- **Tokens:**

  | Role | Value |
  |---|---|
  | Background | `#0E0D0C` |
  | Surface | `#1A1917` |
  | Surface raised | `#242220` |
  | Primary ember | `#C8743C` |
  | Accent glow | `#E8A05C` |
  | Ink (text) | `#F4F1EC` |
  | Muted text | `#7D7770` |
  | Border | `#2A2724` |

- **Type intent:** two voices. A high-contrast serif for emotional lines (Canela / GT Sectra / Reckless class) and a clean grotesque for UI and data (Inter Tight / Geist / Söhne class), plus mono eyebrows with wide tracking. Fonts are not licensed yet; tell me licensing implications and a system-font fallback.
- **Motion vocabulary from earlier specs** (keep, rename or replace):
  - **Carve**: text etched in glyph by glyph.
  - **Settle**: an element arrives with mass and a slight overshoot.
  - **Strata**: staggered planes rise in sequence.
  - **Ember**: one key word warms from ink to ember.
  - **Breath**: a slow 1.0 → 1.02 scale loop on held moments.
  - **Lock**: a hard snap into a final position with a heavy haptic.
- The metaphor and the warm-dark palette are the anchor. Everything else is open to improvement if you can justify it.

### 2.8 History: what we've tried and what we learned

1. **First version** (~32 screens): a strong porn-blocker focus (good), but it used a computed "addiction/verdict score", an "hours lost" calculator and fabricated statistics. That's unacceptable: it destroys trust with a cynical audience and risks App Review rejection.
2. **A rebuild drifted** into philosophical "write your personal constitution" territory and was **rejected because it lost the porn-blocker focus**. Identity work is fine only when it serves the blocker.
3. **Two later specs (28–29 screens)** were honest and interaction-first, with good ideas, but **too long**.
4. Ideas from those specs worth evaluating. Keep, adapt or kill each one, with reasons:
   - **Recognize**: tap the specific behaviors that are true for you, instead of being told about yourself.
   - **Reckon**: the user drags a dial to estimate how much of their day it takes, the honest replacement for a fabricated "hours lost" number.
   - **Affirm**: a reflection that quotes their answers back, ending in a "Yes — that's me" tap.
   - **Best-self word**: "Who are you at your best?" becomes a North Star word reused later in the flow.
   - **Oath stone**: type your name into a one-line commitment, then press and hold to "set the cornerstone" with a haptic ramp.
   - **Build the wall**: each guardrail chosen lays a stone in a wall, with the Screen Time permission requested in that moment.
   - **Walk the loop**: tap trigger → relief and watch the groove deepen, then hold "Let it pass" and watch it fill back in.
   - **Hold the door**: try to hold a door shut while a willpower meter drains; then a wall drops in and simply holds.
   - **Scrub the timeline**: drag along an honest road of what the first days and weeks feel like.
   - **Name your why**: their words are carved into stone and surface at the urge moment.
   - **Rehearse the lifeline**: on Day One, press the urge button once so the real moment isn't its first use.

**Lessons to carry forward:** stay focused on the porn blocker, stay honest, and keep it shorter.

---

## 3. What success looks like

### 3.1 The onboarding's jobs, in priority order

1. **Disarm.** The right user feels seen and un-shamed within seconds.
2. **Create one belief:** *"This one I can't undo in a weak moment."*
3. **Activate.** Blocking is actually on before they leave the flow. Decide with evidence whether basic blocking goes on before or after the paywall.
4. **Convert** to premium at the moment of highest belief, with zero dark patterns.
5. **Hand off** into a first day that keeps every promise the onboarding made: the first shield, the first nudge, the Intercept button.

### 3.2 Length and friction

The founder's words: *premium, smooth, and not long.* Treat these as default budgets; deviate only with evidence you can show me:

- Paywall reached in **about 2–3 minutes** at a natural, engaged pace.
- **Roughly 12–18 screens** including the paywall (system permission sheets don't count). **Hard ceiling: 20.** Every screen must pass an "earns its place" test you define and apply.
- **No more than 5–6 questions**, and **every answer must visibly pay off later**. Name where each one does, or cut the question.
- Body copy of about **25 words per screen**; up to ~40 on a small number of deliberate "gift" moments.
- **Friction principle: easy to start, hard to undo.** Strip friction from everything except the one place where friction *is* the product: the lock.
- Evaluate a **fast lane**: someone mid-urge should be able to get the wall up in about 60 seconds and personalize afterwards. Decide whether it's a separate path, a skip, or unnecessary, and justify it.

### 3.3 Metrics to design for

Define the funnel and name the analytics events. At minimum:

- Step-by-step completion and drop-off
- Time to paywall
- Screen Time permission grant rate
- Blocking actually active at the end of onboarding
- Trial start rate and paywall → purchase rate
- Strict Mode set up within 24 hours
- Day-1 and Day-7 retention

Any benchmark number you cite needs a source. Otherwise label it as an assumption.

---

## 4. Non-negotiables

**Honesty**
- No fabricated scores, "hours lost" figures, user counts, fake "analyzing your answers…" theater, fake timers, fake discounts, countdowns or invented testimonials.
- Social proof must be real, or clearly marked as a placeholder with `// VERIFY BEFORE LAUNCH`.
- Every science claim must be sourced and hedged. No "rewire your brain in 90 days" over-promises.

**Tone**
- Calm, grounded, a mentor who's been there.
- Never explicit. Never shaming. Never clinical. No fear-first openings. No emoji, no exclamation marks, no hype.
- Secular but respectful (several competitors are faith-based; we are not).
- The word "porn" is allowed when directness is the honest choice. Graphic language never is.

**Focus**
- It's a porn blocker first. Identity and motivation work exists only to make the blocker hold.

**Discretion**
- Anything visible on the lock screen or to someone glancing at the phone (notification text, shield screens, Live Activities, widgets) must **never reveal what the app is for**.

**Privacy**
- No account before value. Nothing personal leaves the device during onboarding.
- Say "Stored on your device" only where it's literally true.

**Apple compliance**
- Human Interface Guidelines and App Review Guidelines, especially:
  - 3.1.1 / 3.1.2 subscriptions: clear price and period, trial terms, auto-renew disclosure, Restore, Terms and Privacy links, an easily found close / free path.
  - 5.1.1 data collection.
  - Family Controls entitlement usage.
  - No forced or incentivized reviews.
  - Permission pre-prompts must not imitate system dialogs.
- Age rating 17+.

**Accessibility**
- Every screen and every interaction ships with a Reduce Motion version, a Reduce Transparency solid version, full VoiceOver labels and a tap-operable equivalent for every gesture (holds, drags, swipes).
- Works at the largest accessibility Dynamic Type sizes.
- Meets contrast requirements; nothing communicated by color alone.
- Haptics are respectful; sound is off by default.

**Safety**
- A quiet, always-available "If you're really struggling, you're not alone" link to crisis resources at a few sensible points.

---

## 5. How to work: phases

### Phase 0 — Questions and capture list → ⏸ CHECKPOINT 1

Before researching or designing:

1. **Ask me up to 10 questions** whose answers would *materially* change the result. Give your **default assumption** for each, so I can reply "go with defaults." Questions you should at least consider:
   - Is the Strict Mode / Screen Time passcode setup part of onboarding, or a guided setup right after purchase?
   - Should basic blocking be switched on before the paywall?
   - Do we have any real social proof yet?
   - Is the accountability-partner invite path (someone opening `thebedrock.app/join/CODE` to *support* a friend) in scope, and should supporters ever see a paywall?
   - Gender inclusivity of the copy.
   - Font licensing budget.
   - Languages.
   - Which analytics tool we use.
   - Whether prices are open for discussion.
   - Whether I can provide competitor screen recordings.
2. **Give me a capture list**: the 6–8 competitor apps whose onboarding you most need to see *for real*, and exactly what to screen-record in each:
   - full onboarding through the paywall
   - permission pre-prompts
   - the shield / blocked screen
   - the flow for turning protection off
   - the subscription cancel path
   - whatever else matters

   I'll download them and send you the recordings so your analysis rests on real screens, not memory.

Then wait for my answers.

### Phase 1 — Competitive research (deep)

**Competitor set.** Verify that each is still live and relevant as of now; add any app with real traction you find by searching the App Store for "porn blocker", "quit porn", "nofap", "porn addiction" and "accountability".

- **Direct** (porn recovery / blocking / accountability): Quittr, Brainbuddy, Fortify, Relay, Covenant Eyes, Ever Accountable, Canopy, BlockerX, Remojo, plus whatever else you find.
- **Adjacent** (blockers and screen-time tools known for craft or "hard to disable" mechanics): Opal, one sec, Brick, Clearspace, ScreenZen, Jomo, Freedom.
- **Best-in-class onboarding / paywall benchmarks from any category:** Duolingo, Headspace, Noom, Cal AI, Finch, Rise, plus any others you consider the current state of the art.

**Sources to use (use web search and browsing):**

- App Store listings: screenshots, descriptions, What's New, ratings.
- App Store reviews: filter for onboarding, paywall, "too long", subscription anger, "easy to bypass", "deleted it".
- Reddit: r/pornfree, r/NoFap, r/NoSurf, r/digitalminimalism. Look for threads about these apps and about bypassing blockers on iOS.
- YouTube and TikTok onboarding walkthroughs, plus each app's **ads**. Check whether the ad's promise matches the first screens.
- Design libraries (Mobbin, Screensdesign, Page Flows) where accessible.
- Founder interviews and growth posts.
- RevenueCat's subscription-app reports and published paywall/onboarding research (Adapty, Superwall and similar).
- Apple's HIG and App Review Guidelines.

**Evidence rules (mandatory):**

- Tag every claim **[Seen]** (you saw the screen or recording), **[Reported]** (reviews, Reddit, articles, with a link) or **[Inferred]** (your reasoning).
- Link sources and note dates. Prices are for the US region unless stated.
- **Never invent a screen you haven't seen.** If you couldn't access a flow, say so plainly and put it on the capture list.

**Teardown per competitor:**

- Positioning and core promise; the ad promise vs. the first screen
- Screen-by-screen flow map: number, purpose, visible copy verbatim, interaction type, question asked, data collected
- Counts: screens to paywall, number of questions, text density, estimated time
- Permission timing and pre-prompt copy
- Personalization "theater", and how honest it is
- Paywall: layout, plans, prices, trial, anchoring, urgency tactics, close-button visibility and delay, free path
- Visual style: color, type, illustration, density
- Motion and haptics: what moves, how it feels
- Voice and tone; how shame and fear are handled
- What happens right after the paywall: activation, first session
- **How hard it is to disable:** the mechanism, and the bypasses users report
- Review sentiment about onboarding, paywall and bypassing, with representative quotes (anonymized)
- Steal / adapt / avoid
- Scores out of 5 on this rubric:
  - clarity of promise
  - shame safety
  - feeling understood
  - perceived premium quality
  - motion craft
  - copy craft
  - speed to value
  - honesty
  - activation (is blocking actually on at the end)
  - paywall ethics
  - lock strength

### Phase 2 — Synthesis

1. **Pattern library:** 20–40 onboarding and paywall patterns you observed. Examples: quiz-to-score, sunk-cost long quiz, signed commitment, testimonial wall, "analyzing" loader, scarcity timer, permission priming, value before paywall, hard vs. soft paywall, trial-reminder promise. For each:
   - who uses it
   - the evidence for its effect
   - an ethics rating
   - fit for Bedrock: **steal / adapt / avoid**, and why
2. **Gap map:** what nobody in the category does well. These are our openings. Hypotheses to test: honest personalization, real activation before the paywall, a streak that doesn't reset, *demonstrating* the lock instead of claiming it, a proper partner path, a discreet shield.
3. **User insight:**
   - The emotional states, fears and objections of the target user, from real reviews and forum posts, with cited, anonymized quotes. Cover exposure fear, shame, cynicism ("I'll just bypass it"), price resentment, faith-based tone elsewhere, and anything else you find.
   - Refine the personas from 2.2.
   - For each persona, what it needs to **feel, believe and do** in the first 30 seconds, at the lock moment and at the paywall.
4. **The single sentence** the whole onboarding must make true in the user's mind.

### Phase 3 — Diverge, then converge → ⏸ CHECKPOINT 2

1. **At least 3 genuinely different full-flow concepts** — different philosophies, not variations. For example:
   - "Lock-first": the wall is up in 60 seconds, then personalize.
   - "Mirror": understood → believe → commit → lock.
   - "Ritual": build your foundation with your hands.

   For each, give the screen list and flow map, the signature moment, estimated time, how it converts, how it activates, and its main risk.
2. **A bank of 30 or more micro-ideas**: signature interactions, copy hooks, transitions, proof moments, trust moments. Score each on impact, effort, honesty and risk. Include and judge every prior idea in 2.8. Also consider, among others:
   - a live **"test the wall"** moment: open a blocked site and see the Bedrock shield, then return
   - a **preview of the disable gauntlet**: "here's what happens if you try to turn this off at 2am"
   - showing the **no-reset Foundation** before the paywall
3. **Quick motion sketches of the 2–3 riskiest signature moments** before committing. Judge them honestly.
4. **Pick a winner or a hybrid.** Score every concept against the personas and the success criteria. State plainly what you're cutting and why.

Present to me: a short summary of the research findings, the concepts, your recommendation and the runner-up. Then wait.

### Phase 4 — The final onboarding (full spec)

**Flow map with every branch:**

- main path
- fast lane (if kept)
- Screen Time permission denied, then granted later
- user already has their own Screen Time passcode set
- child or managed device where Family Controls isn't available
- free path out of the paywall → basic blocking active
- purchase → premium lock setup
- Restore
- trial-ineligible user
- app backgrounded mid-flow → resumes exactly where they left off
- partner-invite entrant → separate short supporter flow
- returning user
- Simulator / unavailable state

**Every screen, using this template:**

```
S{n} — {Name}   [{verb: watch / read / tap / drag / hold / type}]   ~{seconds}s   (cumulative: {time})
Job:                one sentence
Earns its place:    why cutting it would hurt
Layout:             description (hi-fi lives in the prototype)
Copy (final, every string):
  Eyebrow / Headline / Body / Primary button / Secondary / Links
  Error + empty states
  VoiceOver labels and hints
Interaction:        exactly what the user does; what's disabled until when
Data captured →     where it visibly pays off later (screen IDs)
Motion:             element-by-element choreography with timestamps
                    (t=0, t=120ms…), duration, curve or spring
                    (response / dampingFraction), and haptic type at each moment
Transition out:     how this screen hands off to the next
Reduce Motion:      the static / fade equivalent
Edge cases:         …
Analytics:          event_name {properties}
```

**Give extra design depth to these:**

1. **The lock.** How the user picks lock strength. An honest explanation of what each level does and doesn't prevent. How we guide them through iOS Settings to set a Screen Time passcode they won't know (partner-held or Bedrock-held blind entry): exact step-by-step instructions, how we detect that they came back and verify it worked, and recovery if they mess it up. Also how we **preview the disable gauntlet** so they trust it.
2. **The shield screen** (blocked app/site): full design and copy, discreet to onlookers, with what the two buttons do.
3. **Permission moments:** exact timing and pre-prompt copy for Screen Time and for notifications, plus approve and deny handling.
4. **The paywall:**
   - Outcomes, not a feature list.
   - Plan presentation and trial copy shown only when the user is eligible.
   - The free path visible from second zero, with an honest label.
   - Legal footer, Restore, the post-purchase moment, then the optional Sign in with Apple.
   - Test: **delete the price and the screen should still read as a satisfying ending.**
5. **The first 24 hours:** the hand-off into the home screen, the first shield they'll hit, the first nudge (discreet copy), and the Intercept button. Every promise the onboarding made should be kept here.

**Copy depth:**
- For the first three screens, the lock moment, the paywall headline and the final screen, write **at least five alternatives each**, pick one and say why.
- For every signature animation, propose **2–3 motion treatments** and pick one.

Finish with a **timing table** for the whole flow: per-screen seconds and cumulative time to the paywall.

### Phase 5 — Systems

- **Visual:** refined tokens; type pairing with licensing and system fallback; spacing grid; corner radii; rules for where Liquid Glass is and isn't used, with Reduce Transparency solids; iconography; illustration or 3D direction for stone, strata and ember. Show it, don't just describe it.
- **Motion:** a named primitive library with exact parameters, mapped to SwiftUI (`.spring(response:dampingFraction:)`, timing curves, durations). Include:
  - a haptic map (impact light / medium / heavy / rigid / soft, selection, notification; Core Haptics patterns for press-and-hold ramps)
  - choreography rules (one hero motion per screen, stagger rules, the contrast between slow emotional beats and snappy interactions)
  - a performance budget (smooth at 120 Hz, no stacked heavy blurs)
  - Reduce Motion fallbacks
- **Copy:**
  - a voice and tone guide
  - a banned-words list (seed: "journey", "warrior", "king", "fap", calling the user an "addict", exclamation marks, emoji)
  - word-count limits and reading level
  - how we talk about relapse, privacy and money

### Phase 6 — Prototype

- A high-fidelity, clickable prototype of the final flow at **iPhone 17 Pro size (402 × 874 pt)**, dark mode.
- Every screen, including the permission-denied branch, the free path and the lock setup.
- Transitions and animations as close to final as your tools allow. Where the tool can't express a motion, annotate exactly what it should do.
- Real copy everywhere. No lorem ipsum, no "TBD", no grey boxes standing in for decisions.

### Phase 7 — Red team, then revise

Critique your own result through each of these lenses. List the concrete problems, fix them, and show me the before and after for anything significant.

1. The guy at 2am, mid-urge
2. The cynic who has deleted six blockers
3. A partner or spouse who sent him the app
4. Apple App Review
5. A growth lead focused only on trial-start rate
6. A recovery-informed clinician (shame, safety, over-promising)
7. An accessibility auditor: VoiceOver, largest Dynamic Type, Reduce Motion
8. A motion director
9. A copy chief who wants 30% fewer words
10. An iOS engineer estimating the SwiftUI effort and flagging anything expensive or impossible

### Phase 8 — Handoff

Package it for implementation (the app is built in SwiftUI with Claude Code):

- the screen spec
- component inventory
- design and motion tokens as Swift-ready constants
- the haptic map
- asset list
- analytics event list
- A/B test candidates with the metric each one moves
- remaining open questions

If you can export a handoff bundle for Claude Code, do.

---

## 6. Quality bar: don'ts

- No generic SaaS onboarding, feature-carousel slides, stock illustration, emoji or confetti.
- No pattern copied from a competitor without adapting it to Bedrock and justifying it.
- No unsourced numbers, no placeholder copy, no "etc."
- No hand-waving like "add a nice animation here". Specify it.
- No more than one hero animation per screen.
- No question whose answer isn't visibly used later.
- No exceeding the screen and time budget without evidence.
- No hiding the free path. No delayed close buttons. No guilt-trip "No thanks, I like being weak" decline copy.
- No claims about the lock that aren't true on iOS 26.
- No drifting away from the porn blocker.
- No overconfidence: if you're unsure, say so and show your reasoning briefly.

## 7. Deliverables checklist

1. Phase 0 questions and the competitor capture list
2. Research dossier: teardowns with evidence tags and sources
3. Pattern library and gap map
4. User insight and personas with real cited quotes
5. Concepts, the idea bank with scores, motion sketches, recommendation
6. Final flow spec: every screen, every string, every motion, every edge case, plus the timing table
7. Visual, motion and copy systems
8. Clickable high-fidelity prototype
9. Red-team findings and revisions
10. Engineering handoff package

## 8. Before you hand anything to me, confirm

- [ ] Every competitor claim is tagged [Seen] / [Reported] / [Inferred] and sourced.
- [ ] The flow is within the screen and time budget, or the deviation is justified with evidence.
- [ ] Every question's payoff is named.
- [ ] Blocking is genuinely on by the end of the flow, on the free path too.
- [ ] Every claim about the lock is true on iOS 26, and the copy says nothing that a reviewer could disprove.
- [ ] Nothing visible on the lock screen reveals what the app is for.
- [ ] Zero fabricated numbers, testimonials, timers or "analysis".
- [ ] Every gesture has a VoiceOver / tap equivalent, and every animation has a Reduce Motion version.
- [ ] The paywall passes Apple 3.1.2 and passes the "delete the price" test.
- [ ] Every single string in the prototype is final.
