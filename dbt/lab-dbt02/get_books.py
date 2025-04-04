import os
import duckdb
import kagglehub
import pandas as pd


dataset_path = kagglehub.dataset_download("thedevastator/books-sales-and-ratings")
books_path = os.path.join(dataset_path, os.listdir(dataset_path)[0])

# Create a DuckDB database
db_path = "bookstore.ddb"
con = duckdb.connect(database=db_path, read_only=False)

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
    print(f"Data successfully loaded into the 'books' table in '{db_path}'.")
except Exception as e:
    print(f"An error occurred while creating the table or inserting data: {e}")

# Close the connection
con.close()