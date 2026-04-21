# Voice Actor Invoice Demo

This demo package is structured for quick import into Airtable and analysis in Tableau.

## Files

- `voice_actors.csv`: master list of 17 voice actors
- `invoices.csv`: invoice fact table with status, amounts, delivery channel, and review flags
- `payments.csv`: payment events for settled invoices

## Airtable Setup

Create three tables:

1. `Voice Actors`
2. `Invoices`
3. `Payments`

Recommended field mapping:

- `Voice Actors`
  - `actor_id` as primary key
  - `actor_name`
  - `agent_name`
  - `region`
  - `primary_language`
  - `rate_per_hour_usd`
  - `payment_terms`
  - `status`
  - `first_project_date`

- `Invoices`
  - `invoice_id` as primary key
  - `actor_id` linked to `Voice Actors.actor_id`
  - `project_name`
  - `client_name`
  - `invoice_date`
  - `due_date`
  - `payment_date`
  - `hours_worked`
  - `rate_per_hour_usd`
  - `invoice_amount_usd`
  - `status`
  - `payment_method`
  - `compression_review`
  - `delivery_channel`

- `Payments`
  - `payment_id` as primary key
  - `invoice_id` linked to `Invoices.invoice_id`
  - `actor_id` linked to `Voice Actors.actor_id`
  - `payment_date`
  - `amount_paid_usd`
  - `payment_method`
  - `payment_status`
  - `days_to_pay`

## Tableau Model

Use `invoices.csv` as the primary fact table.

Relationships:

- `Invoices.actor_id = Voice Actors.actor_id`
- `Invoices.invoice_id = Payments.invoice_id`

## Suggested Dashboard

Create one executive dashboard with these KPI cards:

- `Total Invoiced`
- `Total Paid`
- `Outstanding Amount`
- `Overdue Amount`
- `Invoice Count`
- `Average Days to Pay`

Recommended charts:

- Monthly invoiced amount trend
- Invoice status distribution
- Top 10 voice actors by billed amount
- Outstanding balance by actor
- Client-wise invoice totals
- Payment method split

## Tableau Calculated Fields

Use these formulas:

```text
Total Invoiced = SUM([invoice_amount_usd])
```

```text
Total Paid = ZN(SUM([amount_paid_usd]))
```

```text
Outstanding Amount = SUM([invoice_amount_usd]) - ZN(SUM([amount_paid_usd]))
```

```text
Overdue Amount =
SUM(
    IF [status] = "Overdue" THEN [invoice_amount_usd] ELSE 0 END
)
```

```text
Average Days to Pay = AVG([days_to_pay])
```

```text
Invoice Month = DATETRUNC('month', [invoice_date])
```

## Demo Storyline

This dataset supports a realistic operations story:

- 17 voice actors managed across multiple agencies and regions
- mixed payment terms (`Net 15`, `Net 30`)
- paid, pending, and overdue invoices
- delivery tracked across `Email`, `Portal`, and `S3 Upload`
- optional `compression_review` status for QA-oriented workflows

## Recommended Dashboard Title

`Voice Actor Invoice Operations Dashboard`
