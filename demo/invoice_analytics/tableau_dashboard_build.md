# Tableau Dashboard Build

Use this with the CSV files in the same folder to build a Tableau dashboard quickly.

## Dashboard Name

`Voice Actor Invoice Operations Dashboard`

## Data Model

Use relationships, not physical joins:

- `Invoices.actor_id = Voice Actors.actor_id`
- `Invoices.invoice_id = Payments.invoice_id`

Primary table:

- `Invoices`

## Calculated Fields

Create these fields in Tableau:

```text
Total Invoiced
SUM([invoice_amount_usd])
```

```text
Total Paid
ZN(SUM([amount_paid_usd]))
```

```text
Outstanding Amount
SUM([invoice_amount_usd]) - ZN(SUM([amount_paid_usd]))
```

```text
Overdue Amount
SUM(IF [status] = "Overdue" THEN [invoice_amount_usd] ELSE 0 END)
```

```text
Invoice Count
COUNTD([invoice_id])
```

```text
Average Days to Pay
AVG([days_to_pay])
```

```text
Invoice Month
DATETRUNC('month', [invoice_date])
```

```text
Outstanding by Invoice
[invoice_amount_usd] - ZN([amount_paid_usd])
```

## Worksheets

Create these 8 worksheets.

### 1. KPI Total Invoiced

- Marks: `Text`
- Text: `SUM([invoice_amount_usd])`
- Format as currency

### 2. KPI Total Paid

- Marks: `Text`
- Text: `ZN(SUM([amount_paid_usd]))`
- Format as currency

### 3. KPI Outstanding

- Marks: `Text`
- Text: `Outstanding Amount`
- Format as currency

### 4. KPI Overdue

- Marks: `Text`
- Text: `Overdue Amount`
- Format as currency

### 5. Monthly Invoiced Trend

- Columns: `Invoice Month`
- Rows: `SUM([invoice_amount_usd])`
- Marks: `Line`
- Show month labels

Expected totals from the demo data:

- `2026-01`: `$16,468.50`
- `2026-02`: `$13,145.00`
- `2026-03`: `$5,951.00`

### 6. Invoice Status Split

- Columns: `status`
- Rows: `COUNTD([invoice_id])`
- Marks: `Bar`
- Color by `status`

Expected counts:

- `Paid`: `18`
- `Pending`: `10`
- `Overdue`: `6`

### 7. Top Actors by Billed Amount

- Rows: `actor_name`
- Columns: `SUM([invoice_amount_usd])`
- Marks: `Bar`
- Sort descending
- Filter: Top `10` by billed amount

Top actors in this dataset:

- `Mason Patel`: `$2,805.00`
- `Charlotte Reed`: `$2,755.00`
- `Daniel Nguyen`: `$2,632.50`
- `Sofia Ramirez`: `$2,537.50`
- `Benjamin Davis`: `$2,520.00`

### 8. Outstanding Balance by Actor

- Rows: `actor_name`
- Columns: `SUM([invoice_amount_usd]) - ZN(SUM([amount_paid_usd]))`
- Marks: `Bar`
- Color: use a single alert color
- Sort descending

## Dashboard Layout

Use a fixed desktop size around `1400 x 900`.

Top row:

- `KPI Total Invoiced`
- `KPI Total Paid`
- `KPI Outstanding`
- `KPI Overdue`

Middle row:

- `Monthly Invoiced Trend` on the left, about 60 percent width
- `Invoice Status Split` on the right, about 40 percent width

Bottom row:

- `Top Actors by Billed Amount` on the left
- `Outstanding Balance by Actor` on the right

## Filters

Add these dashboard filters:

- `invoice_date`
- `status`
- `client_name`
- `actor_name`
- `payment_method`

Apply all filters to all worksheets.

## Recommended Formatting

- Paid: `#1F7A5C`
- Pending: `#D9A441`
- Overdue: `#C44536`
- Neutral card background: `#F5F1E8`
- Dark text: `#1E2430`

Use compact numeric formatting:

- Currency in `$#,##0`
- Average days to pay in `0.0`

## Reference Numbers

These are the expected headline values for the demo data:

- `Total Invoiced`: `$35,564.50`
- `Total Paid`: `$16,730.50`
- `Outstanding Amount`: `$18,834.00`
- `Overdue Amount`: `$7,889.00`
- `Invoice Count`: `34`
- `Average Days to Pay`: `23.1`
