---
name: attribution-gap-analysis
description: Reconcile ad-platform reported conversions (Meta, Snap, TikTok, Google) against the MMP (Singular, AppsFlyer, Adjust) and the backend's own orders: click-only vs view-through tables, gap decomposition, new-vs-returning sanity checks, cost per order per source, root-cause diagnosis and a prioritized plan. Use when marketing numbers disagree, when deciding budget allocation, or when asked how to judge a media buyer.
---

# attribution-gap-analysis

You are explaining why three sources report three different numbers of orders for the same month, how much of the difference is counting method versus real orders, and what the owner should do about budget and measurement. Write for a business owner, not an analyst: every table gets a one-line reading underneath it.

## Inputs to collect first

1. **Backend**: total orders, revenue, average order value, new customers, returning customers; per platform if the backend stores a source per order (it usually does not; say so when missing).
2. **MMP** (Singular, AppsFlyer, Adjust): attributed purchases and revenue per source, click vs view where available, organic total, installs and re-engagements. Note any source that is entered manually or not connected.
3. **Each ad platform's dashboard**: spend, purchases split into click-through and view-through (engaged-view where it exists), purchase value, first-purchase vs repeat where the platform offers it, attribution window in force, and whether the number covers app only or app plus web.
4. **Exchange rate and currency** of every source; convert everything to the backend's currency once.

## Normalize before comparing

- Purchases, not buyers: some platforms (TikTok) report unique buyers. Use the purchases count.
- App vs web: compare like with like. If the MMP is app-only and a platform mixes web, note the web share from backend data.
- Attribution windows: name each platform's window (for example 28-day swipe for Snap, 7-day click + 1-day view for Meta) next to its number.
- Deduplication: the MMP gives each order to one source; platforms each count their own touch. Platform totals can legitimately exceed the MMP total; they can never legitimately exceed backend orders.

## Tables to produce (in this order)

**A. Click-only vs MMP**, per platform: platform click conversions, MMP attributed, difference, difference %.

**B. Click + view vs MMP**, same columns. This is the number the platform shows by default.

**C. Share of the gap explained by view-through**: gap (B), view-through claims, view share of gap, remaining gap after removing view. Exclude platforms that report less than the MMP (those point to missing postbacks, not inflation).

**D. New vs all customers sanity check**: platform click claims and click+view claims as a percentage of backend new customers and of all orders. Claims above 100% of new customers prove that returning customers are being claimed. Add the platforms' own first-purchase vs repeat split where available, and state that "first purchase" on a platform means first from that ad, not first on the store.

**E. Cost per order per source**: spend, cost per order on platform numbers, on click-only, on MMP numbers; cost per new customer overall (total spend / backend new customers, flagged as a lower bound). Flag any campaign whose cost per order exceeds the average order value by a wide margin.

## Diagnosis checklist (rank by size of effect, with the number next to each)

1. View-through counting (platform counts a purchase after an impression with no click).
2. Attribution window longer than the MMP's (Snap 28-day swipe is the usual case).
3. Returning customers claimed by acquisition campaigns.
4. The same order counted by more than one platform.
5. Scope mismatch: web orders inside platform numbers, app-only MMP.
6. Gaps on our side: duplicate purchase events in a shipped app version, a source entered manually in the MMP, iOS users who declined tracking counted as organic, no per-order source stored in the backend.
7. Budget allocation not following measured cost per new customer (a measurement finding that is also a money finding).

State plainly which part of the gap is counting method and which part, if any, suggests real missing orders.

## Decision rules to state in the report

- **Accounting number**: backend orders, revenue and new customers against total spend. This is what a media buyer is judged on.
- **Allocation number**: the MMP's per-source cost per order, because it counts every source the same way and gives each order to one source.
- **Optimization number**: platform dashboards, for the buyer's daily work only; never for judging performance.
- **Arbiter when sources disagree**: a holdout test (pause a platform in some cities for two weeks and compare backend orders) or the platform's own lift study.

## Plan template

- **Week 1 (no development)**: agree the three numbers above in writing; weekly platform reports split click vs view at a 7-day click / 1-day view window; stop or rebuild campaigns with cost per order far above AOV; request web orders by UTM from the backend.
- **2 to 4 weeks**: join backend orders to the MMP by order id or customer id so new vs returning per source exists; exclude existing customers from acquisition campaigns with hashed customer lists; ship the app fix for any duplicate event; connect any manual MMP source properly.
- **1 to 2 months**: run the holdout or lift test on the platform with the largest unexplained gap; reallocate budget by measured cost per new customer; measure repeat purchase of this month's new customers next month.
- **KPIs**: cost per new customer (backend), MMP cost per order per source, platform/MMP ratio, view-through share of platform claims, new-customer share of orders.

## Rules

- Mark every estimate as an estimate; mark every target you propose as a proposal, not a computed value.
- Never say numbers are "fake"; say which counting rule produced them.
- If a required input is missing (per-source backend data is the usual one), name it as the most important gap rather than guessing around it.
- Keep the report readable by someone who will act on it: tables first, one-line reading under each, diagnosis ranked, plan dated.
