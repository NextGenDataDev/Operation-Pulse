import os
from pathlib import Path

import psycopg2
from dotenv import load_dotenv

load_dotenv()

# The folder this script lives in, so it works no matter where you run it from.
BASE = Path(__file__).parent

connection = psycopg2.connect(
    host=os.getenv("DB_HOST"), database="pulsepay",
    user=os.getenv("DB_USER"), password=os.getenv("DB_PASSWORD"),
    port=os.getenv("DB_PORT"))
cursor = connection.cursor()

# 1. Create the tables from the schema file.
with open(BASE / "pulsepay_schema.sql", encoding="utf-8-sig") as f:
    cursor.execute(f.read())

# 2. Load each CSV straight into its table.
for table in ["locations", "services", "channels", "customers", "transactions", "support_interactions"]:
    with open(BASE / "raw_data" / "data" / f"{table}.csv", encoding="utf-8-sig") as f:
        cursor.copy_expert(f"COPY {table} FROM STDIN WITH (FORMAT csv, HEADER true)", f)
    print(f"Loaded {table}")

connection.commit()
cursor.close()
connection.close()
print("Done.")