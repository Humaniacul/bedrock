# A/B test candidates

Run one test at a time on the paywall and one elsewhere at most. Use PostHog feature flags; each running test adds an `ab_*` property to every onboarding event (see `OnboardingContext.experiments`). Size each test with PostHog’s experiment calculator against your real traffic before starting; nothing here assumes a traffic number.

## Guardrails on every test

A variant that wins its metric but breaks a guardrail loses.

- **Refund rate** and refund requests within 7 days (App Store Connect, RevenueCat).
- **One-star reviews** that mention charges, being trapped or being judged.
- **Blocking active at the end of onboarding** (`onb_completed` with the wall applied and authorisation still approved).
- **Day-7 retention**, split by path.
- **Strict Mode within 24h** of purchase (`onb_strict_sealed`).

## Never tested

These would raise a number and break a rule in the brief: hiding or shrinking the free path, delaying the close button, removing the late-night block, hiding the trial timeline, countdowns or fake urgency, invented social proof, guilt-trip decline copy.

## Candidates

| # | Test | Variants | Metric it moves | Why it’s worth running |
|---|---|---|---|---|
| 1 | **Trial length** (D2, the first test) | 3-day trial (control) · 7-day trial | Trial start rate; trial → paid; revenue per paywall view after 30 days | RevenueCat’s 2026 report found trials of 17–32 days convert at 42.5% against 25.5% under 4 days, and 55.4% of 3-day cancellations happen on day 0. A longer trial may also give Strict Mode time to prove itself. |
| 2 | **Where Lifetime sits** | Yearly + Lifetime side by side (control) · Yearly alone, Lifetime under Other plans | Paywall → purchase; revenue per paywall view; plan mix | Lifetime at $149 may anchor Yearly, or may pull buyers away from it. Only a test says which. |
| 3 | **S9’s opening beat** | “Right now, this wall has a door.” (control) · “Hold the door” (willpower drains, then the wall drops in; the idea bank’s runner-up) | S9 → S12 continuation; paywall → purchase | Control teaches “this structure can’t be undone”; the variant teaches “structure beats willpower”. Both are true; one may sell Strict Mode better. |
| 4 | **The crack demonstration on S8** | The seam appears on their own stone (control) · on a small example stone beside it | S8 → S9 continuation; Day-7 retention | Some people may read a crack on their brand-new stone as a prediction of failure. |
| 5 | **When notifications are asked** | S14 in onboarding (control) · the first time Home opens after onboarding, with the same preview | Notification grant rate; heads-up opens in week 1; Day-7 retention | S14 is the 11th ask; moving it out shortens onboarding by about 8 seconds but loses the S5 context. |
| 6 | **A founder’s line on the paywall** | No line (control) · one signed sentence under the headline, in the founder’s own words | Paywall → purchase; refund rate | From the idea bank. Only run it with a real sentence you wrote; never a stand-in. |
| 7 | **The wall test (S4)** | Open the test page (control) · skip S4 entirely | Onboarding completion; time to paywall; trial start rate; refund rate | S4 costs about 12 seconds. The bet is that seeing Apple block the page builds the trust the paywall needs. Test the bet. |
| 8 | **Finish later visibility** | Text button from S4 (control) · only from S8 | Onboarding completion; share reaching S12; blocking active at the end | Finish later protects the 2am builder, but may let people leave before the story lands. |

## Reading results

- Decide the primary metric and the run length before starting; don’t stop early on a good day.
- Split every result by `local_hour_bucket`: a variant that wins in the afternoon and loses at night is telling you something about the person at 2am.
- Report trial tests on revenue per paywall view after the trial window plus 30 days, not on trial starts alone.
