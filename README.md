# Health & Beauty Category Performance Diagnostic

A dbt + BigQuery + Looker Studio analytics project that diagnoses regional performance gaps in the `health_beauty` category of the Olist Brazilian E-commerce dataset, using an elimination-based diagnostic methodology to move from a surface-level metric gap to an actionable business recommendation.

> **TL;DR** — Revenue per seller varies by more than **80x** across Brazilian states. Sequentially testing and ruling out pricing, review scores, and delivery performance shows the gap is *not* a seller-execution problem — it points instead to demand-side or exposure-side market dynamics, which reframes the recommended intervention entirely.

---

## Table of Contents

- [Business Context](#business-context)
- [Dataset](#dataset)
- [Tech Stack](#tech-stack)
- [Project Architecture](#project-architecture)
- [Analytical Methodology](#analytical-methodology)
- [Key Findings](#key-findings)
- [Dashboard](#dashboard)
- [Repository Structure](#repository-structure)
- [Getting Started](#getting-started)
- [Key Learnings](#key-learnings)
- [Next Steps](#next-steps)

---

## Business Context

Most e-commerce analytics portfolios go broad (an all-purpose growth dashboard). This project deliberately goes narrow instead: a single high-revenue, geographically distributed category (`health_beauty`) is analyzed in depth, mirroring how a real category-analytics team would investigate a performance anomaly — starting from a metric, testing hypotheses against data, and ending with a resourcing recommendation a stakeholder can act on.

The guiding question:

> Sellers in some states generate far less revenue per head than sellers in others. Is this a seller-execution problem (pricing, service quality, fulfillment) — or something structural in the market itself?

## Dataset

[Olist Brazilian E-commerce Dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) (Kaggle), loaded into BigQuery as raw source tables:

| Table | Contents |
|---|---|
| `orders` | Order status and timestamps |
| `order_items` | Line-item price, freight, seller |
| `products` | Product category, dimensions |
| `customers` | Customer location |
| `sellers` | Seller location |
| `olist_order_reviews_clean` | Review scores (deduplicated) |
| `category_translation` | Portuguese → English category names |

## Tech Stack

- **BigQuery** — SQL warehouse and query engine
- **dbt** — staging → intermediate → mart modeling, tested and documented
- **Looker Studio** — interactive geo-visualization and KPI dashboard

## Project Architecture

```
sources (olist_raw)
      │
      ▼
staging/            -- type casting, renaming, one model per source table
      │
      ▼
intermediate/        -- joins across orders / items / products / sellers / reviews,
                         deduplicated to the correct analytical grain
      │
      ▼
marts/                -- category- and state-level aggregate tables
      │
      ▼
Looker Studio          -- state map, KPI scorecards, ranked tables
```

Design principles enforced throughout the project:

- **Grain discipline** — every join is preceded by a check of what grain each side is at; every aggregation is followed by a check of what grain the output represents.
- **Fan-out prevention** — line items and reviews are pre-aggregated to the target grain *before* joining, to avoid silently inflating revenue or review counts.
- **Single source of truth per concept** — category translation and state geography logic live in one layer only, not duplicated across staging and marts.

## Analytical Methodology

The core of this project is **elimination-based diagnosis**: rather than jumping to a single explanation for a metric gap, each plausible seller-side hypothesis is tested against a specific metric and explicitly ruled in or out before moving to the next layer.

```
Step 1  Confirm the gap is real           → revenue_per_seller by state
Step 2  Rule out pricing                  → avg/median item price, freight
Step 3  Rule out service quality          → avg review score (grain-safe join)
Step 4  Rule out delivery performance     → delivery days, on-time vs. estimate
Step 5  Reframe to market-level causes    → customer-side penetration vs.
                                             seller exposure (same-state sales %)
```

This structure is designed to answer not just *what* the data shows, but *why* a given metric was chosen and *what the data cannot yet confirm* — the three layers a stakeholder-facing analysis should be able to withstand follow-up questioning on.

## Key Findings

| Hypothesis | Metric | Result | Verdict |
|---|---|---|---|
| Underpricing to compensate for weak demand | Avg. item price | GO: R$116 — in line with peer states | ❌ Ruled out |
| Poor service quality / low reviews | Avg. review score | GO: 4.5 — 3rd highest in category | ❌ Ruled out |
| Slow / unreliable delivery | Avg. delivery days, late-delivery % | GO: 11.1 days, 3.8% late — top-tier | ❌ Ruled out |

With all three seller-execution hypotheses eliminated, the underperformance of states like **GO** and **MG** is more likely a **demand-side (local category adoption)** or **exposure-side (seller visibility on the platform)** issue — a materially different, and much less obvious, resourcing recommendation than "coach the sellers."

A secondary anomaly surfaced during the analysis: **MA** state shows the highest revenue per seller in the category, but also the *lowest* review score and *highest* late-delivery rate — explained by a near-monopoly market structure (a single active seller), which is flagged as a churn-risk signal rather than a best practice to replicate.

## Dashboard

**[Live dashboard →](https://datastudio.google.com/reporting/31fb1151-76b7-4e40-a7c5-b8cef5fb434a)**

The Looker Studio dashboard (`Olist Beauty & Health — State Performance Overview`) provides:

- A geo map sized by `revenue_per_seller`
- KPI scorecards: total revenue, seller count, average review score, late-delivery rate
- A ranked, filterable state-level table (revenue per seller, avg. price, avg. review, late-delivery %)

<p align="center">
  <img src="docs/images/dashboard_map_overview.png" alt="State-level geo map and KPI scorecards" width="800"/>
</p>

<p align="center">
  <img src="docs/images/dashboard_state_table.png" alt="Ranked state performance table" width="800"/>
</p>

## Repository Structure

```
.
├── models/
│   ├── staging/
│   │   └── stg_*.sql
│   ├── intermediate/
│   │   └── int_*.sql
│   └── marts/
│       ├── mart_category_state_performance.sql
│       └── mart_monthly_category_trends.sql
├── tests/
├── macros/
├── dbt_project.yml
├── sources.yml
└── README.md
```

*(Adjust to match your actual file tree before committing.)*

## Getting Started

```bash
# 1. Configure your BigQuery connection in profiles.yml

# 2. Install dependencies
dbt deps

# 3. Build the models
dbt run

# 4. Run data tests
dbt test

# 5. Generate and view docs
dbt docs generate
dbt docs serve
```

## Key Learnings

- **Grain discipline is the single biggest source of silent bugs.** Joining `order_items` or reviews at the wrong grain doesn't throw an error — it quietly inflates revenue and review counts. Every join needs an explicit grain check beforehand and after.
- **Deduplication logic depends on the target analytical grain**, not a fixed rule — deduplicating reviews at `order_id + seller_id` still over-counts when a seller has multiple line items in the same order; the correct grain has to match what the metric is meant to represent.
- **Ruling a hypothesis out is as valuable as confirming one.** The analytical value of this project comes from systematically eliminating the obvious seller-side explanations, not from the first plausible story.
- **Transactional data has a ceiling.** Once pricing, reviews, and delivery are exhausted as explanations, the honest move is to flag the gap in what the data can answer and propose a proxy analysis or qualitative research design — not to force a conclusion the data doesn't support.

## Next Steps

- Validate the demand-side vs. exposure-side hypothesis using customer-state penetration rate and same-state seller sales ratio (SQL designed, not yet executed).
- Design a short qualitative survey for GO/MG consumers (category awareness, online-trust, offline-competition dimensions) to complement the transactional analysis.
- Extend the market-concentration check (MA anomaly) into a recurring churn-risk monitor.

---

*Built as a portfolio project to demonstrate category-level analytical depth on BigQuery, dbt, and Looker Studio.*

