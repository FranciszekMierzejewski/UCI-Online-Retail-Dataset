import pandas as pd
import os
import io
import psycopg2
from psycopg2.extras import execute_values
from dotenv import load_dotenv

load_dotenv()
df = pd.read_excel("data/Online Retail.xlsx")

df.columns = [
    "invoice_no",
    "stock_code",
    "description",
    "quantity",
    "invoice_date",
    "unit_price",
    "customer_id",
    "country"
]

df = df.fillna(None)
data = list(df.to_records(index=False)) # convert df to numpy record array

conn = psycopg2.connect(
    dbname = "retail_db",
    user = "postgres",
    password = os.getenv("DB_PASSWORD"),
    host = "localhost",
    port = "5432"
)

cur = conn.cursor()

insert_query = """
    INSERT INTO raw_transactions (
        invoice_no,
        stock_code,
        description,
        quantity,
        invoice_date,
        unit_price,
        customer_id,
        country
    )
    VALUES %s 
"""
# %s is placeholder for data rows when executing queries

execute_values(cur, insert_query, data)
conn.commit()
cur.close()
conn.close()

print("Successful insertion")