import pandas as pd
import psycopg2
import os
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