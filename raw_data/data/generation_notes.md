# Generation Notes — Operation Pulse (PulsePay Synthetic Dataset)

This document describes how the dataset was generated: methodology, assumptions,
distributions, relationships, deliberately introduced data-quality issues, and
known limitations. It does **not** describe or hint at the analytical findings
the data may contain — those are for the analyst to discover.

## 1. Overall approach

The dataset was generated programmatically (Python, NumPy/pandas, seeded RNG for
reproducibility) as six relational tables mirroring a plausible operational
export from a Nigerian digital financial-services platform. Values were drawn
from probability distributions rather than fixed rules, so relationships
between fields are tendencies, not guarantees — every "typical" pattern in the
data has exceptions.

Random seed used: `20260926` (deterministic; re-running the exact script
reproduces the same files).

## 2. Table generation summary

- **locations** (10 rows): fixed list of real Nigerian cities/states/regions.
  Popularity weights for use in downstream tables were drawn from a Dirichlet
  distribution so that no two locations are equally represented.
- **services** (8 rows): six required categories plus two additional services
  (TV Subscription Payment, split airtime into Airtime Top-up and Data Bundle
  Purchase) for realism. Popularity weights again drawn from a Dirichlet
  distribution.
- **channels** (5 rows): Mobile App, USSD, Web, POS, Agent, with uneven
  popularity weights.
- **customers** (10,000 rows): age group, segment, occupation, acquisition
  channel, and status were each sampled independently from weighted
  categorical distributions (weights were chosen to be plausible but
  arbitrary, not calibrated to produce a specific finding). Registration
  dates were sampled with a mild recency skew (more registrations in more
  recent periods, consistent with a growing platform) across a window from
  January 2021 through late August 2026. Account status probabilities shift
  gradually with account age (older accounts have a somewhat higher chance
  of being Inactive/Dormant), but this is probabilistic — many old accounts
  remain Active and many newer ones do not.
- **transactions** (~155,000 rows before final additions, ~155,079 total):
  see detailed notes below.
- **support_interactions** (~20,000 rows, plus a small number of duplicates):
  see detailed notes below.

## 3. Transaction generation details

- **Customer selection**: each customer was given a latent "transaction
  propensity" combining their segment (Small Business and High Value
  customers transact somewhat more on average), their account status
  (Dormant customers transact much less), and individual log-normal noise.
  Transactions were then sampled proportionally to these propensities — this
  produces realistic customer-level variation in transaction counts without
  hard-coding any customer as anomalous.
- **Service, location, channel assignment**: each was sampled from weighted
  distributions with mild, probabilistic tilts (e.g., Small Business and
  High Value customers are somewhat more likely to use transfer/card/
  merchant services; customers in three larger metro locations are somewhat
  more likely to use digital channels; other locations skew slightly toward
  USSD/Agent). ~8% of transactions occur away from the customer's home
  location, representing travel or agent use.
- **Timing**: transaction dates span roughly 23 months (October 2024–
  September 2026). Daily volume combines a mild organic growth trend, a
  weekday/weekend effect (weekends somewhat quieter), a gentle cyclical
  wobble, and multiplicative noise — intentionally not a dramatic,
  easily-labeled trend. Hour-of-day follows a realistic overnight-quiet /
  daytime-busy curve. No transaction was placed before its customer's
  registration date.
- **Amount**: each service has its own log-normal distribution with
  service-specific bounds (e.g., airtime purchases are small; transfers and
  merchant payments have wider ranges). About 55% of amounts within each
  service are rounded to plausible "clean" values; the rest retain more
  granular values. A very small fraction (~0.15%) of transactions are
  deliberately large outliers, unrelated to any specific customer, service,
  or location.
- **Status**: base rates were approximately 88.5% Success / 8.5% Failed / 3%
  Pending, with small additive tilts by channel and service (e.g., POS/Agent
  channels and card/merchant services have a marginally higher failure
  tendency). Actual realized rates in the final data differ slightly from
  these targets because of interaction effects and rounding — they were not
  forced to match any specific number.
- **Failure reason**: assigned only to Failed transactions (and, rarely, as
  a provisional note on Pending transactions) from a weighted list; no
  single reason was forced to dominate beyond its base sampling weight.
- **Processing time**: modeled with a gamma distribution, with different
  shape/scale parameters by status (Pending transactions tend to show
  longer processing times) and by channel. A small fraction (~0.4%) of
  transactions have deliberately very long processing times as unlabeled
  outliers. ~1.5% of processing-time values are missing at random.
- **Fee amount**: computed per-service using different logics — flat fees,
  percentage-of-amount with a cap, tiered flat fees, or zero fees (airtime
  and data bundles carry no fee) — rather than one universal formula.
  Failed/Pending transactions generally carry no fee, with a small chance
  of a nominal retry-related charge.
- **Device type**: sampled per channel from a channel-specific distribution
  (e.g., POS channel is overwhelmingly POS Terminal; USSD channel skews
  toward USSD and Android). Not deterministic — every channel has some
  device variety.

## 4. Support interaction generation details

- Roughly 55% of interactions are linked to a Failed or Pending transaction,
  ~25% are linked to a Successful transaction (e.g., card issues, refund
  requests unrelated to a failure), and the remaining ~20% have no linked
  transaction at all (general account issues, access problems, etc.).
- Interaction timestamps follow the linked transaction's timestamp plus an
  exponentially-distributed delay (for transaction-linked interactions), or
  a random timestamp within the analysis window (for unlinked interactions).
- Support category, resolution status, resolution time, and customer rating
  are each drawn from weighted distributions that shift depending on the
  referenced transaction's status (e.g., interactions tied to Failed
  transactions are more likely — not certain — to be categorized as "Failed
  Transaction" and to receive lower ratings when escalated). These are
  probabilistic tendencies with substantial overlap and exceptions by design.
- ~22% of interactions have no customer rating (not every contact is rated).

## 5. Deliberately introduced data-quality issues

These are present so an analyst has real cleaning/validation work to do.
Their exact locations and counts are not enumerated here beyond what is
described:

- **Missing values**: `occupation_category` (~6% of customers),
  `acquisition_channel` (~4% of customers), `processing_time_seconds`
  (~1.5% of transactions), `customer_rating` (~22% of support interactions),
  and `failure_reason` is legitimately NULL for the large majority of
  Success/Pending records (not a defect, but relevant to note when auditing
  nulls).
- **Inconsistent categorical casing/whitespace**: a small percentage of
  `customer_segment`, `device_type`, and `support_channel` values appear in
  mixed case or with trailing whitespace (e.g., "affluent" vs "Affluent" vs
  "AFFLUENT ").
- **Duplicate records**: a small number of transactions (45) and support
  interactions (25) were duplicated — each duplicate received its own
  primary key (as a double-logged/double-submitted record would in a real
  system) but otherwise matches the original record's business fields,
  sometimes with a slightly shifted timestamp. These are identifiable by
  comparing non-key fields, not by looking for repeated primary keys.
- **Unusual/outlier values**: a very small number of unusually large
  transaction amounts, unusually long processing times, and short bursts of
  closely-timed, similar-amount transactions from a handful of customers
  were included as potential signals for investigation. None of these are
  labeled, flagged, or guaranteed to indicate fraud — they are simply
  present in the raw data as any real operational export might contain.

## 6. What was intentionally NOT done

- No `fraud_flag`, `risk_score`, `is_suspicious`, or similar derived/label
  column was created anywhere in the dataset.
- No location, service, channel, segment, or time period was deliberately
  engineered to be "the worst" or "the best" performer. Weights and
  parameters were chosen for plausibility and variety, not to produce a
  predetermined conclusion.
- No analytical findings, summary conclusions, or "the main issue is X"
  statements are provided anywhere in this documentation or the data itself.

## 7. Known limitations

- This is synthetic data generated from parametric distributions; it will
  not perfectly reproduce every nuance of a real fintech's transaction
  patterns (e.g., real seasonal spikes around holidays, salary-day effects,
  or macroeconomic shocks are not modeled).
- Some derived tendencies (e.g., segment → service mix, channel → failure
  rate) are the result of explicit, modest probability adjustments described
  above; a sufficiently deep statistical investigation would find that these
  patterns exist by construction, but their strength, direction, and
  practical significance were not tuned to hit a specific target number.
- The dataset does not model multi-currency activity, chargebacks/refund
  ledger entries as separate transactions, or KYC/compliance fields.
