import os
import shutil

import duckdb
import kagglehub
import pandas as pd

dataset_path = kagglehub.dataset_download("thedevastator/books-sales-and-ratings")
books_path = os.path.join(dataset_path, os.listdir(dataset_path)[0])
shutil.copy(books_path, 'books.csv')

# Create a DuckDB database
DB_PATH = "bookstore.ddb"
try:
    os.remove(DB_PATH)
except Exception:
    pass
con = duckdb.connect(database=DB_PATH, read_only=False)

# Read the CSV file into a pandas DataFrame
try:
    df = pd.read_csv(books_path)
except pd.errors.EmptyDataError:
    print(f"Error: The file at {books_path} is empty.")
    exit()
except FileNotFoundError:
    print(f"Error: The file at {books_path} was not found.")
    exit()
except Exception as e:
    print(f"An unexpected error occurred while reading the CSV file: {e}")
    exit()

# Create the 'books' table and insert the data from the DataFrame
try:
    con.execute("CREATE TABLE books AS SELECT * FROM df")
    print(f"Data successfully loaded into the 'books' table in '{DB_PATH}'.")
except Exception as e:
    print(f"An error occurred while creating the table or inserting data: {e}")

# Close the connection
con.close()
