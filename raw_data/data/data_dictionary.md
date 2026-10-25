# Data Dictionary — Operation Pulse (PulsePay Synthetic Dataset)

## Table: locations
| Column | Type | Key | Description | Expected Values | Nullable |
|---|---|---|---|---|---|
| location_id | VARCHAR | PK | Unique location identifier | LOC001–LOC010 | No |
| city | VARCHAR | | Nigerian city of operation | e.g. Lagos, Abuja, Kano | No |
| state | VARCHAR | | Nigerian state or FCT | e.g. Lagos, FCT, Kano | No |
| region | VARCHAR | | Nigerian geopolitical region | South West, South South, South East, North Central, North West | No |

## Table: services
| Column | Type | Key | Description | Expected Values | Nullable |
|---|---|---|---|---|---|
| service_id | VARCHAR | PK | Unique service identifier | SVC01–SVC08 | No |
| service_name | VARCHAR | | Name of the service offered | e.g. Bank Transfer, Airtime Top-up | No |
| service_category | VARCHAR | | Grouping of the service | Transfers, Bill Payments, Airtime/Data, Merchant Payments, Card Payments, Withdrawals | No |
| service_status | VARCHAR | | Whether the service is currently offered | Active | No |

## Table: channels
| Column | Type | Key | Description | Expected Values | Nullable |
|---|---|---|---|---|---|
| channel_id | VARCHAR | PK | Unique channel identifier | CH01–CH05 | No |
| channel_name | VARCHAR | | Name of the transaction channel | Mobile App, USSD, Web, POS, Agent | No |
| channel_type | VARCHAR | | Broad classification of the channel | Digital, Physical Agent | No |

## Table: customers
| Column | Type | Key | Description | Expected Values | Nullable |
|---|---|---|---|---|---|
| customer_id | VARCHAR | PK | Unique customer identifier | CUST000001–CUST010000 | No |
| registration_date | DATE | | Date customer registered on the platform | 2021-01-01 to ~2026-08-27 | No |
| age_group | VARCHAR | | Customer age bracket | 18-24, 25-34, 35-44, 45-54, 55+ | No |
| customer_segment | VARCHAR | | Business segment classification | Mass Market, Emerging, Affluent, High Value, Small Business (some rows contain casing/whitespace variants — a data-quality issue to clean) | No |
| occupation_category | VARCHAR | | Broad occupation grouping | Student, Trader/Business Owner, Civil Servant, Private Sector Employee, Artisan, Unemployed, Farmer, Professional (Medical/Legal/Eng.) | Yes (~6%) |
| location_id | VARCHAR | FK → locations.location_id | Customer's registered location | LOC001–LOC010 | No |
| acquisition_channel | VARCHAR | | How the customer was acquired | Referral, Social Media, Online Advertisement, Partner, Direct, Other | Yes (~4%) |
| customer_status | VARCHAR | | Current account status | Active, Inactive, Dormant | No |

## Table: transactions
| Column | Type | Key | Description | Expected Values | Nullable |
|---|---|---|---|---|---|
| transaction_id | VARCHAR | PK | Unique transaction identifier (unique per row; a small number of rows represent realistic duplicate submissions with distinct IDs but matching business details) | TXN00000001+ | No |
| customer_id | VARCHAR | FK → customers.customer_id | Customer who performed the transaction | | No |
| service_id | VARCHAR | FK → services.service_id | Service used | | No |
| location_id | VARCHAR | FK → locations.location_id | Location associated with the transaction | | No |
| channel_id | VARCHAR | FK → channels.channel_id | Channel used | | No |
| transaction_datetime | TIMESTAMP | | Date and time of the transaction | 2024-10-01 to 2026-09-01 | No |
| transaction_amount | NUMERIC | | Transaction value in Nigerian naira | Varies by service; a very small number of high-value outliers exist | No |
| transaction_status | VARCHAR | | Outcome of the transaction | Success, Failed, Pending | No |
| failure_reason | VARCHAR | | Reason for failure (or provisional note for some pending records) | Insufficient Funds, Network Error, Timeout, Service Unavailable, Invalid Details, Bank/Provider Error, System Error, Other, Awaiting Confirmation | Yes (NULL for most Success/Pending records) |
| processing_time_seconds | NUMERIC | | Time taken to process the transaction | Varies by status/channel; includes some unusually long values | Yes (~1.5%, missing at random) |
| fee_amount | NUMERIC | | Fee/revenue earned on the transaction | 0 for airtime/data; varies by service for others | No |
| device_type | VARCHAR | | Device used to initiate the transaction | Android, iOS, Web/Desktop, POS Terminal, USSD (some rows contain casing/whitespace variants — a data-quality issue to clean) | No |

## Table: support_interactions
| Column | Type | Key | Description | Expected Values | Nullable |
|---|---|---|---|---|---|
| interaction_id | VARCHAR | PK | Unique support interaction identifier (a small number of realistic duplicate records exist) | SUP000001+ | No |
| customer_id | VARCHAR | FK → customers.customer_id | Customer who contacted support | | No |
| transaction_id | VARCHAR | FK → transactions.transaction_id | Related transaction, if any | | Yes (~20%, interaction not tied to a specific transaction) |
| interaction_datetime | TIMESTAMP | | Date and time of the support contact | Within analysis period | No |
| support_category | VARCHAR | | Reason for the contact | Failed Transaction, Delayed Transaction, Account Issue, Payment Reversal, Card Issue, Refund Request, Account Access, Other | No |
| support_channel | VARCHAR | | Method used to contact support | Phone, Live Chat, Email, In-App Support, Social Media (some rows contain casing/whitespace variants — a data-quality issue to clean) | No |
| resolution_status | VARCHAR | | Current resolution state | Resolved, Pending, Escalated | No |
| resolution_time_minutes | NUMERIC | | Time taken to resolve/handle the interaction | Positive numeric values | No |
| customer_rating | NUMERIC | | Customer satisfaction rating | 1–5 | Yes (~22%, not every customer rates) |

## Relational overview
```
locations ──┐
services ───┼──< transactions >── support_interactions
channels ───┘         │                    │
customers ─────────────┴────────────────────┘
```
