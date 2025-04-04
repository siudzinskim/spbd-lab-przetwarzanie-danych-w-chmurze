import random
import csv
import json
from datetime import date, timedelta, datetime
from faker import Faker
import os
import io # Used for in-memory file handling
import kagglehub
import traceback # For detailed error logging

# --- Configuration ---
# Keep LOCALES and other constants if needed by your generation logic
LOCALES = ['en_GB', 'de_DE', 'fr_FR', 'es_ES', 'it_IT', 'pl_PL', 'de_AT', 'de_CH', 'de_DE']
DEFAULT_NUM_CUSTOMERS = 100
# Default dates might be less relevant if always provided in request, but good fallbacks
DEFAULT_START_DATE = date(2016, 1, 1)
DEFAULT_END_DATE = date(2024, 12, 31)
KAGGLE_DATASET = "thedevastator/books-sales-and-ratings"
KAGGLE_FILENAME = "Books_Data_Clean.csv" # Original filename in the dataset
BOOKS_LOCAL_PATH = f"/tmp/{KAGGLE_FILENAME}" # Lambda's writable temp directory

# Initialize Faker (can be done globally for efficiency)
fake = Faker(LOCALES)

# --- Helper Functions ---

def parse_date(date_str, default_date):
    """Safely parse date string, return default if invalid."""
    if not date_str:
        return default_date
    try:
        return datetime.strptime(date_str, '%Y-%m-%d').date()
    except (ValueError, TypeError):
        print(f"Warning: Invalid date format '{date_str}'. Using default: {default_date}")
        return default_date

# --- Core Generation Logic (Adapted from previous script) ---
# Note: Functions now write to/read from strings or specific /tmp paths

def generate_customers(num_customers):
    """
    Generates synthetic customer data using Faker.

    Args:
        num_customers (int): The number of customer records to generate.

    Returns:
        tuple(str, list[dict]): A tuple containing:
                                 - CSV data as a single string.
                                 - A list of customer dictionaries.
                                Returns (None, []) on error or if num_customers is 0.
    """
    if num_customers <= 0:
        print("Number of customers must be positive.")
        return None, []

    print(f"Generating {num_customers} customers...")
    header = [
        "customer_id", "first_name", "last_name", "email", "phone_number",
        "address", "city", "country", "postal_code", "age", "gender",
        "registration_date", "related_accounts"
    ]
    customers_data = []
    # Use io.StringIO to write CSV to memory
    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow(header)

    try:
        for customer_id in range(1, num_customers + 1):
            locale = random.choice(LOCALES)
            current_faker = Faker(locale)
            first_name = current_faker.first_name()
            last_name = current_faker.last_name()
            email = current_faker.email()
            phone_number = current_faker.phone_number()
            address = current_faker.street_address().replace('\n', '\\n')
            city = current_faker.city()
            try:
                country = current_faker.country()
            except AttributeError:
                 country = fake.country()

            postal_code = current_faker.postcode()
            age = random.randint(18, 80)
            gender = random.choice(['Male', 'Female', 'Other'])
            max_reg_days_ago = (date.today() - date(2010, 1, 1)).days
            reg_days_ago = random.randint(1, max(1, max_reg_days_ago))
            registration_date = date.today() - timedelta(days=reg_days_ago)

            related_accounts = [str(random.randint(1000, 9999)) for _ in range(random.randint(0, 3))]
            related_accounts_string = ','.join(related_accounts)

            row = [
                customer_id, first_name, last_name, email, phone_number,
                address, city, country, postal_code, age, gender,
                registration_date.strftime('%Y-%m-%d'), related_accounts_string
            ]
            writer.writerow(row)
            customers_data.append(dict(zip(header, row)))

        print(f"Customer data generated successfully.")
        return output.getvalue(), customers_data # Return CSV string and list
    except Exception as e:
        print(f"An unexpected error occurred during customer generation: {e}")
        traceback.print_exc()
        return None, []


def generate_transactions(customers_data, books_data, start_date, end_date):
    """
    Generates synthetic transaction data based on customer and book data.

    Args:
        customers_data (list[dict]): List of customer dictionaries.
        books_data (list[dict]): List of book dictionaries (must have 'book_id').
        start_date (date): Earliest transaction date.
        end_date (date): Latest transaction date.

    Returns:
        str | None: A newline-delimited JSON string of transactions, or None on error.
    """
    print(f"Generating transactions from {start_date.strftime('%Y-%m-%d')} to {end_date.strftime('%Y-%m-%d')}...")
    transactions = []
    transaction_id = 1

    if not customers_data:
        print("Error: No customer data provided.")
        return None
    if not books_data:
        print("Warning: No book data available. Transactions will lack valid book IDs.")
        books_data = [] # Proceed, but book IDs will be affected

    output = io.StringIO() # Use StringIO for NDJSON output

    try:
        for customer in customers_data:
            # Basic validation for required customer fields
            if not all(k in customer for k in ('customer_id', 'registration_date')):
                 print(f"Skipping customer due to missing essential keys: {customer.get('customer_id', 'ID Missing')}")
                 continue
            try:
                customer_id_str = str(customer['customer_id'])
                registration_date = date.fromisoformat(customer['registration_date'])
            except (ValueError, TypeError) as e:
                print(f"Skipping customer {customer.get('customer_id', 'ID Missing')} due to invalid registration date '{customer.get('registration_date')}': {e}")
                continue

            trans_start_date = max(registration_date, start_date)
            if trans_start_date > end_date: continue

            current_date = trans_start_date
            while current_date <= end_date:
                if random.random() < 0.3: # Transaction probability
                    max_days_offset = (end_date - current_date).days
                    if max_days_offset < 0: break
                    days_offset = random.randint(0, min(27, max_days_offset))
                    transaction_date = current_date + timedelta(days=days_offset)

                    items = []
                    num_items = random.randint(1, 5)
                    for _ in range(num_items):
                        unit_price = round(random.uniform(5.99, 49.99), 2)
                        quantity = random.choices([1, 2, 3], [0.8, 0.15, 0.05])[0]
                        book_id = random.choice(books_data)['book_id'] if books_data else "UNKNOWN"
                        items.append({"book_id": book_id, "unit_price": unit_price, "quantity": quantity})

                    if not items: continue

                    cash_register = random.randint(1, 50)
                    cashier = f'{cash_register}-{random.randint(1, 5)}'
                    transaction = {
                        "transaction_id": transaction_id, "customer_id": customer_id_str,
                        "transaction_date": transaction_date.strftime('%Y-%m-%d'),
                        "items": items, "cash_register": cash_register, "cashier": cashier
                    }
                    transactions.append(transaction)
                    # Write each transaction as a JSON line to the string buffer
                    output.write(json.dumps(transaction) + '\n')
                    transaction_id += 1

                current_date += timedelta(days=random.randint(25, 40)) # Advance time

        print(f"Transaction data generated. Total transactions: {len(transactions)}")
        return output.getvalue() # Return the NDJSON string
    except Exception as e:
        print(f"An unexpected error occurred during transaction generation: {e}")
        traceback.print_exc()
        return None

def load_books(books_file_path):
    """
    Loads book data from the specified CSV file path. Requires 'book_id' column.

    Args:
        books_file_path (str): The local path to the book CSV file (e.g., in /tmp).

    Returns:
        list[dict] | None: List of book dictionaries, or None on critical error.
                           Returns empty list if file not found but proceeds.
    """
    print(f"Loading books from {books_file_path}...")
    books = []
    try:
        with open(books_file_path, mode='r', newline='', encoding='utf-8') as file: # Specify encoding
            reader = csv.DictReader(file)
            # Check if 'Book_ID' or 'book_id' exists (handle case variations)
            fieldnames_lower = [f.lower() for f in reader.fieldnames or []]
            book_id_col = None
            if 'book_id' in fieldnames_lower:
                 book_id_col = reader.fieldnames[fieldnames_lower.index('book_id')]
            elif 'book id' in fieldnames_lower: # Check common variations
                 book_id_col = reader.fieldnames[fieldnames_lower.index('book id')]
            # Add more checks if the column name is different in Books_Data_Clean.csv

            if not book_id_col:
                 print(f"Error: Required header 'book_id' (or similar) not found in {books_file_path}. Found headers: {reader.fieldnames}")
                 return None # Critical error

            print(f"Using book ID column: '{book_id_col}'") # Debug print
            for row in reader:
                # Ensure the book_id is extracted using the correct key found
                books.append({"book_id": row[book_id_col]}) # Store only ID, or more if needed
        print(f"Successfully loaded {len(books)} books.")
        return books
    except FileNotFoundError:
        print(f"Error: Book file not found at {books_file_path}")
        return [] # Return empty list, allows proceeding with warnings
    except Exception as e:
        print(f"Error reading book file {books_file_path}: {e}")
        traceback.print_exc()
        return None # Indicate critical error


# --- Lambda Handler ---

def lambda_handler(event, context):
    """
    AWS Lambda handler function. Parses request body for generation parameters,
    downloads book data from Kaggle, generates requested data (customers/transactions),
    and returns it in the HTTP response body.
    """
    print("Lambda execution started.")
    print(f"Received event: {json.dumps(event)}")

    # 1. Parse Input Parameters from request body
    try:
        # API Gateway proxy integration wraps body in a string
        body = json.loads(event.get('body', '{}'))
    except json.JSONDecodeError:
        print("Error: Invalid JSON in request body.")
        return {'statusCode': 400, 'body': json.dumps({'error': 'Invalid JSON format in request body'})}

    generate_mode = body.get('generate', 'all').lower()
    num_customers = int(body.get('num_customers', DEFAULT_NUM_CUSTOMERS))
    start_date_str = body.get('start_date')
    end_date_str = body.get('end_date')

    # Use helper for safe date parsing
    start_date = parse_date(start_date_str, DEFAULT_START_DATE)
    end_date = parse_date(end_date_str, DEFAULT_END_DATE)

    # Basic validation
    if generate_mode not in ['customers', 'transactions', 'all']:
        return {'statusCode': 400, 'body': json.dumps({'error': "Invalid 'generate' mode. Use 'customers', 'transactions', or 'all'."})}
    if num_customers <= 0 and generate_mode != 'transactions':
         return {'statusCode': 400, 'body': json.dumps({'error': "'num_customers' must be positive."})}
    if start_date > end_date:
         return {'statusCode': 400, 'body': json.dumps({'error': "'start_date' cannot be after 'end_date'."})}


    # 2. Download Book Data from Kaggle (if needed for transactions)
    books_data = None
    if generate_mode in ['transactions', 'all']:
        try:
            print(f"Downloading Kaggle dataset '{KAGGLE_DATASET}' to /tmp...")
            # Ensure KAGGLE_USERNAME and KAGGLE_KEY are set as environment variables
            if not os.environ.get('KAGGLE_USERNAME') or not os.environ.get('KAGGLE_KEY'):
                 raise EnvironmentError("Kaggle credentials (KAGGLE_USERNAME, KAGGLE_KEY) are not set in Lambda environment.")

            # Download the specific file to /tmp
            kagglehub.login() # Uses environment variables KAGGLE_USERNAME and KAGGLE_KEY
            dataset_path = kagglehub.dataset_download(KAGGLE_DATASET, path="/tmp")
            print(f"Dataset downloaded to: {dataset_path}")

            # Construct the expected path to the CSV file within the downloaded structure
            # Note: kagglehub might place it in a subdirectory. Adjust if needed.
            expected_book_file_path = os.path.join(dataset_path, KAGGLE_FILENAME)

            if not os.path.exists(expected_book_file_path):
                 # Fallback: Check if it's directly in /tmp (less likely with recent kagglehub versions)
                 if os.path.exists(os.path.join("/tmp", KAGGLE_FILENAME)):
                      expected_book_file_path = os.path.join("/tmp", KAGGLE_FILENAME)
                 else:
                      # List files to help debug if path is wrong
                      print(f"Downloaded files in /tmp: {os.listdir('/tmp')}")
                      print(f"Downloaded files in {dataset_path}: {os.listdir(dataset_path)}")
                      raise FileNotFoundError(f"Expected book file '{KAGGLE_FILENAME}' not found in download path '{dataset_path}' or '/tmp'.")


            books_data = load_books(expected_book_file_path)
            if books_data is None: # Check for critical load error
                raise RuntimeError("Failed to load critical book data.")

        except Exception as e:
            print(f"Error during Kaggle download or book loading: {e}")
            traceback.print_exc()
            # Decide if critical: if transactions are needed, maybe error out
            if generate_mode == 'transactions':
                 return {'statusCode': 500, 'body': json.dumps({'error': f'Failed to get book data: {e}'})}
            else: # 'all' mode might proceed without books, but warn
                 print("Warning: Proceeding in 'all' mode without book data due to error.")
                 books_data = [] # Ensure it's an empty list

    # 3. Generate Data
    customers_csv_str = None
    customers_list = []
    transactions_ndjson_str = None
    output_body = ""
    content_type = "text/plain" # Default

    try:
        if generate_mode in ['customers', 'all']:
            customers_csv_str, customers_list = generate_customers(num_customers)
            if customers_csv_str is None: # Check for generation failure
                 raise RuntimeError("Customer generation failed.")

        if generate_mode == 'all':
            if customers_list: # Check we have customers to generate transactions for
                 # Use the book data loaded earlier (or empty list if failed)
                 transactions_ndjson_str = generate_transactions(customers_list, books_data, start_date, end_date)
                 if transactions_ndjson_str is None:
                      print("Warning: Transaction generation produced no output or failed.")
                      # Decide how to handle: return only customers? error?
                      # For now, return customers but log the warning.
            else:
                 print("Warning: Cannot generate transactions in 'all' mode as customer generation failed or yielded no data.")

        elif generate_mode == 'transactions':
             # This mode is tricky in standard Lambda without pre-existing customers from S3/etc.
             # For this example, we return an error indicating it's not supported this way.
             print("Error: Generating only transactions requires pre-existing customer data source not implemented in this basic Lambda.")
             return {'statusCode': 501, 'body': json.dumps({'error': "'transactions' only mode not implemented. Use 'all' or 'customers'."})}


        # 4. Prepare Response Body
        if generate_mode == 'customers':
            output_body = customers_csv_str
            content_type = 'text/csv'
        elif generate_mode == 'all':
            # Return both? Or just transactions? Let's return transactions if generated.
            if transactions_ndjson_str:
                output_body = transactions_ndjson_str
                content_type = 'application/x-ndjson'
            else: # Fallback to customers if transactions failed/empty
                 output_body = customers_csv_str
                 content_type = 'text/csv'
        # 'transactions' only mode already returned 501

        if not output_body: # If somehow body is still empty
             print("Warning: Generated output body is empty.")
             output_body = "{'message': 'Generation complete, but no data returned.'}"
             content_type = 'application/json'


        print(f"Data generation complete. Mode: {generate_mode}. Returning content type: {content_type}")
        return {
            'statusCode': 200,
            'headers': {'Content-Type': content_type},
            'body': output_body
        }

    except Exception as e:
        print(f"Unhandled error during generation: {e}")
        traceback.print_exc()
        return {
            'statusCode': 500,
            'body': json.dumps({'error': f'Internal server error during data generation: {e}'})
        }