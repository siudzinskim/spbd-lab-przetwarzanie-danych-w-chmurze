## Kontekst

W tym ćwiczeniu będziemy opracowywać nowoczesny, minimalistyczny, platform-agnostic system przetwarzania i analizy
danych.
Wykorzystywana infrastruktura będzie oparta o AWS, jednak wykorzystywać będzie narzędzia open-source: `DuckDB` oraz
`dbt`.

W celu utworzenia infrastruktury będziemy wykorzystywać elementy utworzone w ramach poprzednich laboratoriów, jednak
wszystkie wymagane komponenty będą dostarczone w ramach tego repozytorium, wystarczy jedynie auaktualnić konfigurację.

## Lab01

W tym laboratorium utworzymy wymaganą infrastrukturę, zawierającą:

#### Komponenty związane z S3 (z pliku `s3.tf`)

* **`aws_s3_bucket.public_bucket`**:
    * Jest to publicznie dostępny bucket S3, który służy do przechowywania danych.
    * Nazwa bucketa to `"spdb-siudzinskim-public"`.
    * `acl = "public-read"`: To sprawia, że bucket jest publicznie czytelny.

* **`aws_s3_bucket_public_access_block.public_bucket_access_block`**:
    * Ten komponent konfiguruje blokady dostępu publicznego dla bucketa S3.
    * Ustawienia `block_public_acls`, `block_public_policy`, `ignore_public_acls`, `restrict_public_buckets` są
      ustawione na `false`, co oznacza, że bucket jest publicznie dostępny.

* **`aws_s3_bucket_policy.public_bucket_policy`**:
    * Jest to polityka dostępu, która definiuje, kto i co może robić z zasobami w buckecie S3.
    * W tym przypadku polityka zezwala wszystkim użytkownikom (`Principal = "*"`) na odczyt obiektów z tego bucketa (
      `Action = ["s3:GetObject"]`).

#### Komponenty związane z EC2 (z pliku `ec2.tf`)

* **`data.aws_ami.amazon_linux`**:
    * Źródło danych, które wyszukuje najnowszą wersję obrazu Amazon Machine Image (AMI) dla systemu Amazon Linux 2.
    * Parametry wyszukiwania zawężają wynik do obrazów o architekturze `x86_64` i typie wirtualizacji `hvm`.

* **`aws_instance.lab_instance`**:
    * Instancja maszyny wirtualnej EC2.
    * Używa obrazu znalezionego w `data.aws_ami.amazon_linux`.
    * Typ instancji to `t2.micro`.
    * Jest umieszczona w podsieci zdefiniowanej przez `subnet_id`.
    * `key_name = "kp"` - klucz SSH.
    * Ustawienie `associate_public_ip_address = true` powoduje przypisanie publicznego adresu IP do instancji.
    * Nazwa tej instancji, ustawiana przez tag `Name`, to `"lab-ec2"`.
    * Skrypt uruchamiany na starcie instancji znajduje się w pliku `startup.sh` i jest kodowany przy użyciu funkcji
      `filebase64()`.
    * `security_groups = [aws_security_group.allow_ssh.id]` - przypisana grupa bezpieczeństwa.

* **`aws_ebs_volume.example`**:
    * Wolumin EBS o rozmiarze 10 GB i typie `gp2`, który będzie dołączony do instancji EC2.
    * Nazwa tego woluminu to `"lab-volume"`.

* **`aws_volume_attachment.ebs_att`**:
    * Definicja dołączenia woluminu EBS do instancji EC2.
    * Wolumin `aws_ebs_volume.example` jest dołączany do instancji `aws_instance.lab_instance` jako urządzenie
      `/dev/sdh`.

* **`aws_security_group.allow_ssh`**:
    * Grupa bezpieczeństwa, która kontroluje ruch sieciowy do instancji EC2.
    * Umożliwia ruch przychodzący na porcie 22 (SSH) z dowolnego adresu IP (`cidr_blocks = ["0.0.0.0/0"]`).
    * Umożliwia cały ruch wychodzący.
    * `vpc_id = aws_vpc.main.id` - przypisanie do vpc.
    * Nazwa tej grupy bezpieczeństwa to `"allow_ssh"`.

### Podsumowanie

W folderze `lab-dbt01` zdefiniowane są komponenty do stworzenia: publicznego bucketa S3, grupy bezpieczeństwa, woluminu
EBS, oraz instancji EC2 z dołączonym woluminem. Dodatkowo kod definiuje źródło danych dla obrazu AMI. Komponenty te
tworzą podstawową infrastrukturę na AWS.


> UWAGA: podczas laboratorium korzystaj koniecznie z systemu Linux, w celu uniknięcia problemów z kompatybilnością.

### Instrukcja:

1. Zaloguj się do konsoli `AWS Academy Learner Lab` i uruchom laboratorium:
2. W zakładce `AWS Details` znajduje się sekcja `Cloud Accsess`, rozwiń `AWS CLI`, kilkając przycisk `Show`, a następnie
   skopiuj dane logowania i wklej je do pliku `~/.aws/credentials`
3. W konsoli AWS przejdź do `Key Pairs` w sekcji `EC2 -> Network & Security`, a następnie utwórz parę o nazwie `kp`.
   Podczas tworzenia plik zostanie pobrany do folderu `Downloads`.
4. Przejdź do folderu `lab-dbt01`, a następnie utwórz elementy infrastruktury za pomocą Terraform.
5. Zwróć uwagę na zawartość pliku `startup.sh`, wytłumacz jaka jaest jego funkcja i jakie czyności zostaną wykonane
6. Utwórz tunel SSH do utworzonej instancji na porcie 8888, który umożliwi połączenie z usługą uruchomioną na zdalnej
   maszynie. Pomocny będzie terraform output. Wytłumacz jak działa taki tunel?
7. Otwórz przeglądarkę i połącz się z localhost:8888
8. W oknie przeglądarki w aplikacji VSCode utwórz plik `hello`, a następnie przejdź do konsoli AWS i usuń wirtualną
   maszynę. Ponownie utwórz ją korzystając z polecenia `terraform apply`. Czy po ponownym podłączeniu do serwera VSCode
   plik `hello` istnieje?

## Lab02

W tym laboratorium zajmiemy się generowaniem danych testowych. Jest to praktyka, którą możemy wykorzystywać kiedy znamy
strukturę danych, jednak nie mamy jeszcze dostępu do danych testowych lub produkcyjnych.

W laboratorium będziemy wykorzystywać gotowy zestaw danych z
Kaggle: https://www.kaggle.com/datasets/thedevastator/books-sales-and-ratings, zwierający następujące kolumny:

```
The file Books_Data_Clean.csv contains comprehensive information on book sales, ratings, and genres, including publishing year, author details, ratings, sales performance data, and genre classification

* Publishing Year: The year in which the book was published. (Numeric)
* Book Name: The title of the book. (Text)
* Author: The name of the author of the book. (Text)
* language_code: The code representing the language in which the book is written. (Text)
* Author_Rating: The rating of the author based on their previous works. (Numeric)
* Book_average_rating: The average rating given to the book by readers. (Numeric)
* Book_ratings_count: The number of ratings given to the book by readers. (Numeric)
* genre: The genre or category to which the book belongs. (Text)
* gross sales: The total sales revenue generated by a specific book. (Numeric)
* publisher revenue: The revenue earned by a publisher from selling a specific book. (Numeric)
* sale price: The price at which a specific book was sold. (Numeric)
* sales rank: The rank of a particular book based on its sale performance. (Numeric)
* units sold: The number of units sold for any particular book. (Numeric)
```

Pozostałe dane będą syntetyczne i będziemy generować je za pomocą generatora.

### Instrukcja:

1. Sklonuj repozytorium (https://github.com/siudzinskim/spbd-lab-przetwarzanie-danych-w-chmurze.git) do lokalnego
   folderu na serwerze VSCode.
2. Przejdź do folderu `dbt/lab-dbt02` i uruchom:

```shell
python get_books.py
```

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; W folderze powinny pojawić się 2 pliki: `books.csv` oraz `bookstore.ddb`.

3. UWAGA! Plik `books.csv` jest wymagany przez generator, bez niego wygenerowane dane będę nieprawidłowe!
4. Uruchom:

```shell
python generator.py
```

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; W folderze powinny pojawić się 2 pliki: `customers.csv` oraz `transactions.json`

5. Zainstaluj DuckDB CLI uruchamiając:

```shell
curl https://install.duckdb.org | sh
export PATH=$PATH:/config/.duckdb/cli/latest/
```

6. Uruchom DuckDB podłączając się do bazy `bookstore.ddb`:

```shell
duckdb bookstore.ddb
```

7. Zapoznaj się z interfejsem DuckDB. Wykonaj kwerendę `.help`, następnie przetestuj kilka przykładowych metod, np.
   `.show`, `.databases`, `.tables`, `.schema`
8. Wykonaj zapytanie `from books;`, pomijając "SELECT *". Zwróć uwagę, że możliwe jest skrócenie komendy.
9. Wykonaj kwerendę `.columns`, a następnie ponownie zapytanie `from books`. Co się stało? wytłumacz format wyjściowy. Jak
   powrócić do normalnego trybu?
10. Wykonaj polecenie:

```
.import customers.csv customers
```

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; Następnie wykonaj kwerendę `from customers;`. Zwróć uwagę na liczbę kolumn.

11. Spróbuj wykonać:

```
.import customers.csv customers --csv
```

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; Co należy zrobić najpierw, aby umożliwić wykonanie polecenia?

12. Spróbuj wykonać import pliku `transactions.json`
13. Wykonaj polecenie:

```python
CREATE
OR
REPLACE
TABLE
transactions
AS
SELECT * FROM
read_json_auto('transactions.json');
```

14. Zamknij DuckDB za pomocą polecenia `.quit`
15. Uruchom DuckDB bez wskazywania ścieżki pliku:

```shell
duckdb
```

Zwróć uwagę na komunikat:

```
Connected to a transient in-memory database.
```

16. Podłącz się ponownie do bazy wykonując `.open bookstore.ddb`

## Lab03

To laboratorium pokazuje w jaki sposób można zrealizować funkcję generatora, która umożliwi uruchomienie generatora jako
Lambda. Niestety ze względu na ograniczenia środowiskowe funkcjonalności są ograniczone.

## Lab04

W czwartej części laboratorium utworzymy nowy projekt dbt.

**Cel:** To laboratorium ma na celu zapoznanie Cię z podstawowymi koncepcjami i funkcjami `dbt` (Data Build Tool) przy
użyciu DuckDB jako silnika bazy danych. Zbudujemy prosty pipeline transformacji danych dla fikcyjnej księgarni.

**Wymagania wstępne:**

1. **Skonfigurowany VSCode Server:** Upewnij się, że masz dostęp do serwera VSCode uruchomionego w ramach laboratorium
   `lab-dbt01`.
2. **Pliki startowe:** Korzystając z generatora utworzonego w ramach laboratorium `lab-dbt01`, przygotuj następujące
   pliki:
    * `bookstore.ddb`: Baza zawierająca tylko tabelę `books`.
    * `customers.csv`: Plik CSV z danymi klientów.
    * `transactions.json`: Plik JSON z danymi transakcji.

**Struktura projektu:**

Na potrzeby tego laboratorium zakładamy następującą strukturę plików i katalogów:

```shell
lab-dbt04/dbt_bookstore_lab/
├── data/
│   ├── bookstore.ddb
│   ├── customers.csv
│   └── transactions.json
├── bookstore_dwh.ddb
└── dbt_project/  <-- Tutaj zainicjujemy projekt dbt
```

#### Krok 1: Inicjalizacja projektu dbt

1. Przejdź do katalogu `dbt_bookstore_lab` w terminalu.
2. Uruchom komendę inicjalizującą projekt `dbt`:

   ```bash
   dbt init dbt_project
   ```

   Wybierz `duckdb` z listy adapterów, gdy zostaniesz o to poproszony. `dbt` utworzy podstawową strukturę katalogów
   wewnątrz `dbt_project/` (m.in. `models`, `seeds`, `tests`).

#### Krok 2: Konfiguracja połączenia (profiles.yml)

`dbt` przechowuje konfiguracje połączeń w pliku `profiles.yml`, domyślnie w `~/.dbt/`.

1. Otwórz lub utwórz plik `~/.dbt/profiles.yml`.
2. Dodaj konfigurację dla DuckDB, wskazując ścieżkę do pliku `bookstore_dwh.ddb`. Pamiętaj, aby użyć **pełnej (absolutnej)
   ścieżki** do pliku `bookstore_dwh.ddb` lub ścieżki względnej *do miejsca, z którego uruchamiasz `dbt`*. Dla uproszczenia
   użyjmy ścieżki względnej zakładając, że `dbt` będzie uruchamiane z katalogu `dbt_bookstore_lab/dbt_project/`:

   ```yaml
   # ~/.dbt/profiles.yml

   bookstore_analytics: # Nazwa profilu - musi pasować do 'profile' w dbt_project.yml
     target: dev
     outputs:
       dev:
         type: duckdb
         path: ../bookstore_dwh.ddb  # Ścieżka do pliku bazy danych (względna do dbt_project/)
         # Opcjonalnie: Możesz dodać rozszerzenia DuckDB, np. httpfs
         # extensions:
         #   - httpfs
         #   - parquet
   ```

3. **Weryfikacja połączenia:** Przejdź do katalogu `dbt_project/` i uruchom:

   ```bash
   dbt debug
   ```
   Jeśli wszystko jest poprawnie skonfigurowane, powinieneś zobaczyć komunikat o pomyślnym połączeniu (
   `Connection test: OK connection ok`).

#### Krok 3: Ładowanie danych statycznych (Seeds)

`Seeds` w `dbt` służą do ładowania małych, statycznych zestawów danych (zwykle z plików CSV) bezpośrednio do bazy
danych. Użyjemy tego mechanizmu do załadowania danych klientów.

1. **Skopiuj plik:** Przenieś plik `customers.csv` z katalogu `data/` do katalogu `dbt_project/seeds/`. 
2. **Uruchom `dbt seed`:** W katalogu `dbt_project/` wykonaj komendę:

   ```bash
   dbt seed
   ```
   `dbt` odczyta plik `customers.csv` i utworzy w bazie `bookstore.ddb` tabelę o nazwie `customers` (zgodnej z nazwą
   pliku) w schemacie zdefiniowanym w `profiles.yml`.

   Podczas ładowania pliku seed wystąpi błąd związany z niepoprawnie rozpoznanymi typami kolumn. Możemy temu zapobiec przez zdefiniowanie "sztywnego" schematu:
   
   - Utwórz plik konfiguracyjny: W katalogu dbt_project/seeds/ stwórz plik o nazwie np. properties.yml (nazwa pliku YAML w katalogu seeds nie ma większego znaczenia, dbt odczyta wszystkie pliki .yml).

   - Dodaj konfigurację typów kolumn: Wklej do tego pliku następującą zawartość, dostosowując nazwy kolumn i typy do struktury Twojego pliku customers.csv. Na podstawie fragmentu błędu, zakładam przykładowe nazwy kolumn:
     ```yaml
     version: 2
     
     seeds:
       - name: customers  # Nazwa seeda musi odpowiadać nazwie pliku CSV (bez rozszerzenia)
         config:
           column_types:
             customer_id: bigint       # Zgodnie z sugestią sniffera (BIGINT zamiast INTEGER)
             first_name: varchar
             last_name: varchar
             email: varchar
             phone: varchar
             address: varchar
             city: varchar
             country: varchar
             postal_code: varchar      # Często kody pocztowe lepiej trzymać jako tekst
             age: integer
             gender: varchar
             registration_date: date   # Możesz potrzebować określić format daty, jeśli nie jest standardowy
             related_accounts: varchar # Kluczowa zmiana: Wymuszenie typu tekstowego (VARCHAR)
     ```

3. **(Opcjonalnie) Inspekcja:** Możesz użyć DuckDB CLI, aby sprawdzić, czy tabela została utworzona:
    ```bash
    duckdb ../bookstore.ddb # Uruchom z katalogu dbt_project/
    ```
    Wewnątrz DuckDB CLI:
    ```sql
    FROM customers LIMIT 5;
    .q
    ```

#### Krok 4: Definiowanie źródeł (Sources)

Źródła (`Sources`) w `dbt` pozwalają zadeklarować istniejące, "surowe" dane w bazie, które nie są zarządzane przez
`dbt` (np. tabele ładowane przez inne procesy ETL lub, jak w naszym przypadku, początkowa tabela `books`).

1. **Skonfiguruj połączenie zewnętrzne:** W pliku `dbt_project.yml` dodaj następujące linijki:
    ```yaml
    on-run-start:
     - "ATTACH '{{ '../data/bookstore.ddb' }}' AS external_db (READ_ONLY);"
    
    on-run-end:
     - "DETACH external_db;" # Dobra praktyka, aby odłączyć bazę po zakończeniu
    ```
2. **Utwórz plik `schema.yml`:** W katalogu `dbt_project/models/staging/` (utwórz katalog `staging`, jeśli nie istnieje)
   stwórz plik `schema.yml` (lub o innej nazwie, np. `sources.yml`).
3. **Zdefiniuj źródło:** Dodaj następującą zawartość do pliku `schema.yml`, definiując tabelę `books` jako źródło:

    ```yaml
    # models/staging/schema.yml
    version: 2
    
    sources:
     - name: raw_data  # Dowolna nazwa grupy źródeł
       description: "Źródłowe dane z bazy bookstore.ddb"
       path: ../data/bookstore.ddb
       database: bookstore # Opcjonalnie, jeśli baza danych jest inna niż domyślna z profilu
       schema: bookstore   # Schemat, w którym znajduje się tabela (domyślny w DuckDB)
    
       tables:
         - name: books
           description: "Tabela zawierająca informacje o książkach."
           # Możesz tutaj dodać testy dla danych źródłowych!
           # columns:
           #   - name: book_id
           #     tests:
           #       - unique
           #       - not_null
    ```
    * `name`: Nazwa logiczna grupy źródeł. 
    * `database`, `schema`: Lokalizacja tabel źródłowych.
    * `tables`: Lista tabel w tym źródle.

#### Krok 5: Tworzenie Modeli (Models)

Modele (`Models`) są sercem `dbt`. Są to pliki `.sql` zawierające zapytania `SELECT`, które `dbt` wykonuje, aby stworzyć
nowe tabele lub widoki w bazie danych.

1. **Model Staging dla Książek:** Utwórz plik `dbt_project/models/staging/stg_books.sql`:

    ```sql
    -- models/staging/stg_books.sql
    -- Prosty model wybierający wszystkie dane ze źródłowej tabeli books, ujednolicający nazewnictwo kolumn
    
    select
        index as book_id,
        "Publishing Year" as publishing_year,
        "Book Name" as book_name,
        "Author" as author,
        language_code,
        "Author_Rating" as author_rating,
        "Book_average_rating" as book_average_rating,
        "Book_ratings_count" as book_ratings_count,
        genre,
        "gross sales" as gross_sales,
        "publisher revenue" as publisher_revenue,
        "sale price" as sale_price,
        "sales rank" as sales_rank,
        "Publisher " as publisher,
        "units sold" as units_sold
    from {{ source('raw_data', 'books') }} -- Użycie funkcji source() do odwołania się do źródła
    ```
    * Funkcja `{{ source('raw_data', 'books') }}` instruuje `dbt`, aby odwołał się do tabeli `books` zdefiniowanej w
      źródle `raw_data`. `dbt` automatycznie wstawi poprawną, pełną nazwę tabeli (`main.books`).

2. **Model Staging dla Klientów:** Utwórz plik `dbt_project/models/staging/stg_customers.sql`:

    ```sql
    -- models/staging/stg_customers.sql
    -- Model wybierający dane z tabeli załadowanej przez 'dbt seed'
    
    select
       *
    from {{ ref('customers') }} -- Użycie funkcji ref() do odwołania się do seeda (lub innego modelu)
    ```
    * Funkcja `{{ ref('customers') }}` instruuje `dbt`, aby odwołał się do obiektu (tabeli) stworzonego przez seed
      `customers`. `dbt` zarządza zależnościami i wstawi poprawną nazwę.

3. **Model Staging dla Transakcji (czytanie JSON):** DuckDB potrafi odczytywać pliki JSON bezpośrednio za pomocą SQL.
   Wykorzystamy to do stworzenia modelu dla transakcji. Utwórz plik `dbt_project/models/staging/stg_transactions.sql`:

    ```sql
    -- models/staging/stg_transactions.sql
    -- Model odczytujący dane bezpośrednio z pliku JSON przy użyciu funkcji DuckDB
    
    select
       *
    from read_json_auto('../data/transactions.json') -- Ścieżka względna do pliku JSON (od dbt_project/)
    ```
    * `read_json_auto()` to funkcja DuckDB. `dbt` po prostu przekaże to zapytanie do wykonania.
    * Używamy ścieżki względnej do pliku JSON, zakładając uruchamianie `dbt` z katalogu `dbt_project/`.
    * Dodaliśmy rzutowanie typów dla lepszej struktury danych.

4. **Model zdenormalizowany:** Stwórzmy model łączący dane z modeli stagingowych. Utwórz katalog `marts` w `models` i plik
   `dbt_project/models/marts/fct_book_transactions.sql`:

    ```sql
    -- models/marts/fct_book_transactions.sql
    -- Model faktów łączący transakcje z klientami i książkami
    
    {{
      config(
        materialized='table' 
      )
    }}
    
    with transactions as (
        select *, unnest(items) as item from {{ ref('stg_transactions') }}
    ),
    customers as (
        select * from {{ ref('stg_customers') }}
    ),
    books as (
        select * from {{ ref('stg_books') }}
    )
    
    select
        t.transaction_id,
        t.transaction_date,
        c.customer_id,
        c.first_name,
        c.last_name,
        c.email,
        b.book_id,
        b.title as book_title,
        b.author as book_author,
        t.item.unit_price as book_price,
        t.item.quantity as units,
        (t.item.unit_price * t.item.quantity) as total_amount
    from transactions t
    left join customers c on t.customer_id = c.customer_id
    left join books b on t.item.book_id = b.book_id
   ```
    * Używamy `{{ ref(...) }}` do odwołania się do naszych modeli stagingowych. `dbt` automatycznie zbuduje graf
      zależności i wykona modele w odpowiedniej kolejności.
    * `{{ config(materialized='table') }}`: Ta konfiguracja instruuje `dbt`, aby fizycznie stworzył tabelę
      `fct_book_transactions` w bazie danych, zamiast domyślnego widoku (`view`). Inne opcje to `incremental` i
      `ephemeral`.

#### Krok 6: Uruchamianie Modeli (dbt run)

Teraz, gdy modele są zdefiniowane, możemy je uruchomić.

1. **Wykonaj `dbt run`:** W katalogu `dbt_project/` uruchom:

   ```bash
   dbt run
   ```
   `dbt` przeanalizuje zależności między modelami (i seedami/źródłami) i wykona je w poprawnej kolejności:
    * `stg_books` (zależy od `source 'raw_data', 'books'`)
    * `stg_customers` (zależy od `seed 'customers'`)
    * `stg_transactions` (nie ma zależności w `dbt`, ale czyta plik)
    * `fct_book_transactions` (zależy od `stg_books`, `stg_customers`, `stg_transactions`)

   Domyślnie modele zostaną utworzone jako widoki (`VIEW`) w schemacie deweloperskim (np. `main`), chyba że
   skonfigurowano inaczej (jak `fct_book_transactions`, który będzie tabelą).

2. **Inspekcja:** Sprawdź bazę `bookstore_dwh.ddb` za pomocą DuckDB CLI, aby zobaczyć nowo utworzone widoki i
   tabelę.
    ```sql
    SHOW TABLES;
    SELECT * FROM fct_book_transactions LIMIT 5;
    ```
    Następnie wykonaj kwerendę:
    ```sql
    FROM stg_books;
    ```
    Zwróć uwagę, że powstał błąd, jednak dane w tabeli pochodnej (t.j. `fct_book_transactions`) zostały zapisane prawidłowo. Przyczyną tego zjawiska jest zastosowanie domyślnej materializacji, a tabela źródłowa pochodzi z zewnętrznej bazy danych, więc DuckDB nie może uzyskać do niej dostępu. Wykonaj teraz:
    ```sql
    .schema
    ```
   Zauważysz, że tabele `stg_*` są widokami, a nie tabelami.
3. **Zmiana typu materializacji:** Zmodyfikuj następujące pliki:
    - `stg_books.sql`
    - `stg_customers.sql`
    - `stg_transactions.sql`
   Dodając przed klauzulą `select` następujący blok:
    ```sql
    {{
      config(
        materialized='table' 
      )
    }}
    ```
   Finalnie np. plik `stg_transactions.sql` powinien wyglądać następująco:
    ```sql
    -- models/staging/stg_transactions.sql
    -- Model odczytujący dane bezpośrednio z pliku JSON przy użyciu funkcji DuckDB
   
    {{
      config(
        materialized='table' 
      )
    }}

   select
        *
    from read_json_auto('../data/transactions.json') -- Ścieżka względna do pliku JSON (od dbt_project/)
    ```
4. **Usuwanie przykładowych modeli:** po utworzeniu projektu za pomocą komendy `dbt init` zostały utworzone przykładowe modele w folderze `dbt_project/models/example`. Są zapisane w naszej bazie danych, jednak są niepożądane. Usuń pliki z tego folderu (lub cały folder) w celu usunięcia przykładowych modeli.
5. **Ponowne uruchomienie `dbt`:** ponownie uruchom `dbt run`
6. **Powtórna inspekcja:** Ponownie sprawdź zawartość tabel `stg_*` oraz wyświetl wynik kwerendy `.schema`. Jak widać modele `stg_*` zostały zapisane w bazie danych. Jednak modele `my_first_dbt_model` oraz `my_second_dbt_model` nadal istnieją w bazie! Zapamiętaj, że usunięcie modelu nie powoduje usunięcia tabel z docelowej bazy danych!

#### Krok 7: Testowanie Danych (dbt test)

`dbt` pozwala na łatwe definiowanie testów w celu zapewnienia jakości i spójności danych.

1. **Dodaj testy do `schema.yml`:** Uzupełnij plik `models/staging/schema.yml`, dodając testy do modeli stagingowych:

   ```yaml
   # models/staging/schema.yml
   version: 2

   sources:
     # ... definicja źródła books (jak wcześniej) ...

   models:
     - name: stg_books
       description: "Model stagingowy dla książek."
       columns:
         - name: book_id
           description: "Unikalny identyfikator książki."
           tests:
             - unique
             - not_null

     - name: stg_customers
       description: "Model stagingowy dla klientów."
       columns:
         - name: customer_id
           description: "Unikalny identyfikator klienta."
           tests:
             - unique
             - not_null
         - name: email
           description: "Adres email klienta."
           tests:
             - unique # Zakładamy, że email jest unikalny

     - name: stg_transactions
       description: "Model stagingowy dla transakcji (z pliku JSON)."
       columns:
         - name: transaction_id
           description: "Unikalny identyfikator transakcji."
           tests:
             - unique
             - not_null
         - name: customer_id
           tests:
             - not_null
             # Test referencyjny - sprawdza czy każdy customer_id istnieje w stg_customers
             - relationships:
                 to: ref('stg_customers')
                 field: customer_id
   ```
    * `unique`, `not_null`: Wbudowane testy generyczne.
    * `relationships`: Wbudowany test sprawdzający spójność referencyjną (klucze obce).

2. **Uruchom `dbt test`:** W katalogu `dbt_project/` wykonaj:

   ```bash
   dbt test
   ```
   `dbt` wygeneruje i wykona zapytania SQL odpowiadające każdemu zdefiniowanemu testowi. Zostaniesz poinformowany, które
   testy zakończyły się sukcesem (`PASS`), a które porażką (`FAIL`), wskazując na potencjalne problemy z danymi.

#### Krok 8: Dokumentacja Projektu (dbt docs)

`dbt` potrafi automatycznie generować dokumentację dla Twojego projektu.

1. **Dodaj opisy:** Możesz dodać `description` do modeli i kolumn w plikach `schema.yml` (jak pokazano w poprzednim
   kroku), aby wzbogacić dokumentację.
2. **Wygeneruj dokumentację:**

   ```bash
   dbt docs generate
   ```
   Ta komenda kompiluje informacje o Twoim projekcie (modele, źródła, testy, opisy, zależności) do plików
   `manifest.json` i `catalog.json`.

3. **Uruchom serwer dokumentacji:**

   ```bash
   dbt docs serve
   ```
   Uruchomi to lokalny serwer WWW (zwykle na porcie 8080). Otwórz przeglądarkę pod wskazanym adresem (
   `http://127.0.0.1:8080`). Zobaczysz interaktywną dokumentację swojego projektu, w tym:
    * Listę modeli, seedów, źródeł, testów.
    * Opisy tabel i kolumn (jeśli zostały dodane).
    * Kod źródłowy modeli.
    * Graf zależności (DAG - Directed Acyclic Graph) pokazujący powiązania między obiektami.

#### Podsumowanie i Następne Kroki

Gratulacje! Ukończyłeś podstawowe laboratorium `dbt` z DuckDB. Nauczyliście się:

* Inicjalizować projekt `dbt`.
* Konfigurować połączenie z bazą danych (DuckDB).
* Ładować dane statyczne za pomocą `dbt seed`.
* Definiować źródła danych za pomocą `sources`.
* Tworzyć modele transformujące dane (`.sql` pliki) używając funkcji `ref()` i `source()`.
* Czytać dane z zewnętrznych plików (JSON) w modelu dzięki możliwościom DuckDB.
* Zmieniać materializację modeli (np. na `table`).
* Uruchamiać pipeline transformacji za pomocą `dbt run`.
* Definiować i uruchamiać testy jakości danych za pomocą `dbt test`.
* Generować i przeglądać dokumentację projektu za pomocą `dbt docs generate` i `dbt docs serve`.

**Co dalej?**

* Eksperymentuj z różnymi **materializacjami** (`view`, `table`, `incremental`, `ephemeral`).
* Poznaj **testy niestandardowe (singular tests)** tworzone jako pliki SQL w katalogu `tests`.
* Zgłęb **Jinja templating** w `dbt` do tworzenia bardziej dynamicznych modeli (makra, pętle, warunki).
* Zintegruj **pakiety `dbt`** (jak `dbt-utils`) dodając je do pliku `packages.yml` i uruchamiając `dbt deps`.
* Dowiedz się więcej o **snapshotach** do śledzenia zmian w danych źródłowych.
* Zapoznaj się z zaawansowanymi konfiguracjami w `dbt_project.yml`.

## Lab05


