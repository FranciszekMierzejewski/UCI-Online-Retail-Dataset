import pandas as pd
import os
import io
import psycopg2
from psycopg2.extras import execute_values
from dotenv import load_dotenv

load_dotenv()
df = pd.read_excel("data/Online Retail.xlsx", dtype=str) 


df.columns = [ # change col names to lowercase and to snake case
    "invoice_no",
    "stock_code",
    "description",
    "quantity",
    "invoice_date",
    "unit_price",
    "customer_id",
    "country"
]

#df = df.where(pd.notna(df), None) # keep value if not missing, else None
# .fillna("")  is only suitable for text types, not date and num type


buffer = io.StringIO()
df.to_csv(buffer, index=False, header=False)
buffer.seek(0) # rewind buffer to start

conn = psycopg2.connect(
    dbname = "retail_db",
    user = "postgres",
    password = os.getenv("DB_PASSWORD"),
    host = "localhost",
    port = "5432"
)

cur = conn.cursor()
cur.execute("TRUNCATE TABLE raw_transactions;") # wipe table to not have dupe rows

# with insert, psycopg cannot handle numpy types. COPY instead of changing to text type or dict of key (numpy type) to value (python native type) conversion
# COPY reads empty csv field in text type column, stores as null

cur.copy_expert(
    """
    COPY raw_transactions ( 
        invoice_no,
        stock_code,
        description,
        quantity,
        invoice_date,
        unit_price,
        customer_id,
        country
    )
    FROM STDIN WITH (FORMAT CSV)
    """, 
    buffer
)

conn.commit()
cur.close()
conn.close()

print("Successful insertion")