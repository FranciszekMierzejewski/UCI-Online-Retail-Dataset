/*
Entry examples to refer to:
536365 (invoice_no) -> 85123A, 71053 (stock_code)
71-53 (stock_code) -> 3.75, 3.39 (unit_price)

FDs:
    {stock_code}^+ = {stock_code, description}
    {customer_id}^+ = {customer_id, country}
    {invoice_no}^+ = {invoice_no, invoice_date, customer_id}
    {stock_code n customer_id}^+ = {stock_code, customer_id, quantity, unit_price}
    {stock_code u customer_id}^+ = {stock_code, customer_id, quantity, unit_price, description, country, invoice_date}

    Partial FDs:
        stock_code -> description
        invoice_no -> invoice_date, customer_id
    
    Transitive FDs:
        invoice_no -> country (via customer_id)

    Full Key FDs:
        stock_code, customer_id -> quantity, unit_price
*/


CREATE TABLE IF NOT EXISTS products (
    stock_code VARCHAR(20) PRIMARY KEY,
    description TEXT

    /*
    Due to data inconsistency, the same stock code may have different descriptions. Most common description will be used
    */
);


CREATE TABLE IF NOT EXISTS customers (
    customer_id VARCHAR(10) PRIMARY KEY,
    country TEXT NOT NULL
);


CREATE TABLE IF NOT EXISTS invoices (
    invoice_no VARCHAR(20) PRIMARY KEY,
    invoice_date TIMESTAMP NOT NULL,
    customer_id VARCHAR(10) NOT NULL REFERENCES customers(customer_id)
);


CREATE TABLE IF NOT EXISTS invoice_lines (
    serial_line_no SERIAL PRIMARY KEY,
    invoice_no VARCHAR(20) NOT NULL REFERENCES invoices(invoice_no),
    stock_code VARCHAR(20) NOT NULL REFERENCES products(stock_code),
    quantity INT NOT NULL,
    unit_price NUMERIC(10, 2) NOT NULL -- 10 digits, 2 dp
);