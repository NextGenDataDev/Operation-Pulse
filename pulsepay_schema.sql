-- PulsePay database schema (PostgreSQL)
-- Run by load_data.py on a fresh database called "pulsepay".

CREATE TABLE locations (
    location_id VARCHAR(10) PRIMARY KEY,
    city        VARCHAR(50),
    state       VARCHAR(50),
    region      VARCHAR(50)
);

CREATE TABLE services (
    service_id       VARCHAR(10) PRIMARY KEY,
    service_name     VARCHAR(80),
    service_category VARCHAR(50),
    service_status   VARCHAR(20)
);

CREATE TABLE channels (
    channel_id   VARCHAR(10) PRIMARY KEY,
    channel_name VARCHAR(50),
    channel_type VARCHAR(50)
);

CREATE TABLE customers (
    customer_id         VARCHAR(15) PRIMARY KEY,
    registration_date   DATE,
    age_group           VARCHAR(10),
    customer_segment    VARCHAR(30),
    occupation_category VARCHAR(60),
    location_id         VARCHAR(10),
    acquisition_channel VARCHAR(40),
    customer_status     VARCHAR(20)
);

CREATE TABLE transactions (
    transaction_id          VARCHAR(15) PRIMARY KEY,
    customer_id             VARCHAR(15),
    service_id              VARCHAR(10),
    location_id             VARCHAR(10),
    channel_id              VARCHAR(10),
    transaction_datetime    TIMESTAMP,
    transaction_amount      NUMERIC(14,2),
    transaction_status      VARCHAR(20),
    failure_reason          VARCHAR(50),
    processing_time_seconds NUMERIC(10,2),
    fee_amount              NUMERIC(12,2),
    device_type             VARCHAR(30)
);

CREATE TABLE support_interactions (
    interaction_id          VARCHAR(15) PRIMARY KEY,
    customer_id             VARCHAR(15),
    transaction_id          VARCHAR(15),
    interaction_datetime    TIMESTAMP,
    support_category        VARCHAR(50),
    support_channel         VARCHAR(30),
    resolution_status       VARCHAR(30),
    resolution_time_minutes NUMERIC(10,2),
    customer_rating         NUMERIC(3,1)
);
