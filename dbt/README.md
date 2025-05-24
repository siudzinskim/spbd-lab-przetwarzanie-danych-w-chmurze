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
CREATE OR REPLACE TABLE transactions AS
SELECT * FROM read_json_auto('transactions.json');
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

16. Podłącz się ponownie do bazy wykonując `.open bookstore.ddb` i wylistuj dostępne tabele.
17. Zamknij połączenie z bazą.

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

Przed rozpoczęciem pracy utwórz foldery oraz skopiuj do nich wymagane pliki za pomocą następujących komend:
```shell
cd /config/workspace/spbd-lab-przetwarzanie-danych-w-chmurze/dbt
mkdir -p /config/workspace/spbd-lab-przetwarzanie-danych-w-chmurze/dbt/lab-dbt04/dbt_bookstore_lab/data
cp /config/workspace/spbd-lab-przetwarzanie-danych-w-chmurze/dbt/lab-dbt02/bookstore.ddb /config/workspace/spbd-lab-przetwarzanie-danych-w-chmurze/dbt/lab-dbt04/dbt_bookstore_lab/data
cp /config/workspace/spbd-lab-przetwarzanie-danych-w-chmurze/dbt/lab-dbt02/customers.csv /config/workspace/spbd-lab-przetwarzanie-danych-w-chmurze/dbt/lab-dbt04/dbt_bookstore_lab/data
cp /config/workspace/spbd-lab-przetwarzanie-danych-w-chmurze/dbt/lab-dbt02/transactions.json /config/workspace/spbd-lab-przetwarzanie-danych-w-chmurze/dbt/lab-dbt04/dbt_bookstore_lab/data
```
> UWAGA! Nie należy tworzyć folderu `dbt_project` ani pliku `bookstore_dwh.ddb`.

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

1. Otwórz lub utwórz plik `~/.dbt/profiles.yml`. W tym celu zalecane jest wykonanie linku symbolicznego do pliku, tak, aby można było uzyskać do niego dostęp z poziomu folderu workspace:
    ```
   ln -s ~/.dbt/profiles.yml /config/workspace/
   ```
2. Dodaj konfigurację dla DuckDB, wskazując ścieżkę do pliku `bookstore_dwh.ddb`. Pamiętaj, aby użyć **pełnej (absolutnej)
   ścieżki** do pliku `bookstore_dwh.ddb` lub ścieżki względnej *do miejsca, z którego uruchamiasz `dbt`*. Dla uproszczenia
   użyjmy ścieżki względnej zakładając, że `dbt` będzie uruchamiane z katalogu `dbt_bookstore_lab/dbt_project/`:

   ```yaml
   # ~/.dbt/profiles.yml
   dbt_project:
     outputs:
       dev:
         type: duckdb
         path: /config/workspace/spbd-lab-przetwarzanie-danych-w-chmurze/dbt/lab-dbt04/dbt_bookstore_lab/data/bookstore_dwh.ddb
         threads: 2
   
     target: dev

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

1. **Przenieś plik:** Przenieś plik `customers.csv` z katalogu `data/` do katalogu `dbt_project/seeds/`. 
2. **Uruchom `dbt seed`:** W katalogu `dbt_project/` wykonaj komendę:

   ```bash
   dbt seed
   ```
   `dbt` odczyta plik `customers.csv` i utworzy w bazie `bookstore.ddb` tabelę o nazwie `customers` (zgodnej z nazwą
   pliku) w schemacie zdefiniowanym w `profiles.yml`.

   Podczas ładowania pliku seed wystąpi błąd związany z niepoprawnie rozpoznanymi typami kolumn. Możemy temu zapobiec przez zdefiniowanie "sztywnego" schematu:
   
   - Utwórz plik konfiguracyjny: W katalogu dbt_project/seeds/ stwórz plik o nazwie np. customers.yml (nazwa pliku YAML w katalogu seeds nie ma większego znaczenia, dbt odczyta wszystkie pliki .yml).

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
             phone_number: varchar
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
    duckdb ....... # Uruchom z katalogu dbt_project/
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
    version: 2
    
    sources:
      - name: raw_data  # Dowolna nazwa grupy źródeł
        description: "Źródłowe dane z bazy bookstore.ddb"
        database: external_db # Opcjonalnie, jeśli baza danych jest inna niż domyślna z profilu
        schema: main   # Schemat, w którym znajduje się tabela (domyślny w DuckDB)
    
        tables:
          - name: books
            description: "Tabela zawierająca informacje o książkach."
            # Możesz tutaj dodać testy dla danych źródłowych!
            columns:
              - name: book_id
                tests:
                  - unique
                  - not_null
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
        "Book Name" as title,
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

4. **Model zdenormalizowany:** Stwórzmy model łączący dane z modeli stagingowych. Utwórz katalog `fact` w `models` i plik
   `dbt_project/models/fact/fct_book_transactions.sql`:

    ```sql
    -- models/fact/fct_book_transactions.sql
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

W tej części laboratorium uruchomimy instancję Apache Airflow, korzystając z najprostszej możliwej konfiguracji, czyli
korzystając z plikowej bazy danych SQLite oraz trybu standalone. Następnie utworzymy DAG umożliwiający uruchomienie 
procesu przetwarzania danych za pomocą `dbt`.

### Uruchomienie serwera Apache Airflow
> UWAGA! Zanim przejdziesz do realizacji ćwiczenia przejdź do konsoli AWS i ręcznie usuń wirtualną maszynę. Zaleca się wcześniejsze wykonanie kopii zapasowej w zasobniku S3.

---

Aby wykonać kopię zapasową można wykonać następujące polecenia:
```shell
tar -cvzf /tmp/spdb-bckp-$(date -Iseconds).tar.gz /config/workspace/spbd-lab-przetwarzanie-danych-w-chmurze
aws s3 cp /tmp/spdb-bckp-* s3://<nazwa-twojego-bucketu>/bckp/
```

---

1. Serwer Apache Airflow wymaga do pracy większej instancji wirtualnej maszyny oraz otworzyć kolejne porty komunikacyjne, 
    w związku z czym musimy w pierwszej kolejności zmodyfikować skrypty terraform. W tym celu:
   * Otwórz plik `ec2.tf` i zmodyfikuj zasób `aws_instance.lab_instance.instance_type` tak, aby przyjął wartość `t3.small` zamiast `t2.micro` lub `t3.micro`.
   * Zmodyfikuj plik `output.tf` otwierając kolejne porty. Zaktualizuj wartość `vscode-tunnel-cmd`, tak aby tunel udostępniał również port 8080:
    ```
    output "vscode-tunnel-cmd" {
      value = "ssh -N -f -L 8888:localhost:8888 -L 8080:localhost:8080 -i ~/Downloads/kp.pem ec2-user@${aws_instance.lab_instance.public_ip}"
    }"
    ```
   * Zaaplikuj zmiany w infrastrukturze. 
2. Korzystając z wartości `vscode-tunnel-cmd` zwróconej przez terraform aby uruchomić tunel.
3. Aby uruchomić serwer Airflow podłącz się do serwera vscode i otwórz terminal, a następnie przejdź do ścieżki 
`/config/workspace/spbd-lab-przetwarzanie-danych-w-chmurze/dbt/lab-dbt05/airflow/` (`UWAGA!` jeśli repozytorium z kodem 
zostało skopiowane do innej lokalizacji, zmodyfikuj odpowiednio ścieżkę) i wykonaj polecenie:
    ```shell
    ./init.sh
    ```
    Podczas jego wykonywania zostaną utworzone ścieżki, skopiowane pliki konfiguracyjne, zainicjalizowana baza danych 
    oraz wstępnie uruchomiony serwer w trybie standalone. Polecenie to należy wykonać tylko raz! Kolejnym razem aby 
    uruchomić serwer Airflow należy wykonać polecenie `airflow standalone` z linii poleceń (ścieżka w której zostanie 
    uruchomiona komenda nie ma znaczenia).
4. Otwórz nowe okno przeglądarki i przejdź do adresu: `http://localhost:8080`. Logujemy się na konto `admin`. Hasło
    zostanie wyświetlone podczas uruchamiania serwera, np.: 
    ```
    standalone | Airflow is ready
    standalone | Login with username: admin  password: bYruyCsgq8bHANqc
    standalone | Airflow Standalone is for development purposes only. Do not use this in production!
    ```
    można je również odnaleźć w pliku `airflow/standalone_admin_password.txt`.
5. Zostanie wyświetlony ekran główny Airflow, w którym dostępny będzie DAG o nazwie `server_health_check_empty`. DAG jest wyłączony, włącz go za pomocą widocznego przełącznika.
6. Zwróć uwagę, że podczas włączania został on automatycznie uruchomiony. Można go również uruchomić ręcznie klikając w odpowiedni przycisk. Uruchom DAG i kiknij w jego nazwę. Zapoznaj się z interfejsem.
7. Utwórz nowy plik o nazwie `dbt_run_dag.py` w folderze `airflow/dags` (ścieżka bezwzględna: `/config/workspace/airflow/dags`). Wklej następujący kod:
    ```python
    from __future__ import annotations
    
    import pendulum
    import os
    
    from airflow.models.dag import DAG
    from airflow.operators.bash import BashOperator
    
    # --- Default Configuration ---
    # These values are used if not provided in the DAG Run Configuration (`dag_run.conf`)
    # They are loaded into the DAG's 'params' for easier Jinja access
    DEFAULT_DBT_PROJECT_DIR = os.getenv('DBT_PROJECT_DIR', '/config/workspace/dbt_bookstore_lab/dbt_project') # !! CHANGE THIS DEFAULT !!
    DEFAULT_DBT_PROFILES_DIR = os.getenv('DBT_PROFILES_DIR') # Can be None if using default location
    DEFAULT_DBT_TARGET = os.getenv('DBT_TARGET')           # Can be None if using default from profiles.yml
    DEFAULT_DBT_MODELS = os.getenv('DBT_MODELS')           # Can be None to run all models
    DEFAULT_DBT_EXCLUDE = os.getenv('DBT_EXCLUDE')         # Can be None to exclude nothing
    
    # Base dbt command flags
    DBT_BASE_COMMAND = "dbt --no-use-colors --no-write-json"
    # --- /Default Configuration ---
    
    
    # --- Templated Command Logic using Jinja ---
    # Access dag_run.conf for runtime parameters, falling back to params (defaults)
    
    # Use .get('key', params.default_key) to safely access config with fallback
    templated_project_dir = "{{ dag_run.conf.get('dbt_project_dir', params.default_project_dir) }}"
    
    # Construct optional flags only if values are provided
    templated_profiles_dir_flag = "{% if dag_run.conf.get('dbt_profiles_dir', params.default_profiles_dir) %} --profiles-dir {{ dag_run.conf.get('dbt_profiles_dir', params.default_profiles_dir) }} {% endif %}"
    templated_target_flag = "{% if dag_run.conf.get('dbt_target', params.default_target) %} --target {{ dag_run.conf.get('dbt_target', params.default_target) }} {% endif %}"
    templated_select_flag = "{% if dag_run.conf.get('dbt_models', params.default_models) %} --select {{ dag_run.conf.get('dbt_models', params.default_models) }} {% endif %}"
    templated_exclude_flag = "{% if dag_run.conf.get('dbt_exclude', params.default_exclude) %} --exclude {{ dag_run.conf.get('dbt_exclude', params.default_exclude) }} {% endif %}"
    templated_full_refresh_flag = "{% if dag_run.conf.get('dbt_full_refresh', False) %} --full-refresh {% endif %}" # Example for a boolean flag
    
    # Build the command parts using the templates
    bash_command_prefix = f"cd {templated_project_dir} && {DBT_BASE_COMMAND}"
    # Flags common to most commands
    common_flags = f"--project-dir {templated_project_dir}{templated_profiles_dir_flag}{templated_target_flag}"
    # Flags specific to run/test (including model selection)
    run_test_flags = f"{common_flags}{templated_select_flag}{templated_exclude_flag}"
    # Flags for seed (potentially including full-refresh)
    seed_flags = f"{common_flags}{templated_full_refresh_flag}"
    # --- /Templated Command Logic ---
    
    
    with DAG(
        dag_id='dbt_dag_run',
        start_date=pendulum.datetime(2024, 1, 1, tz="UTC"), # Adjust start date as needed
        schedule=None,  # Set to None for manual trigger with config
        catchup=False,
        tags=['dbt', 'elt', 'transform', 'parametrized'],
        description='Runs dbt workflow using parameters passed via DAG Run Configuration.',
        # Pass default values into params dictionary for access in Jinja templates
        params={
            'default_project_dir': DEFAULT_DBT_PROJECT_DIR,
            'default_profiles_dir': DEFAULT_DBT_PROFILES_DIR,
            'default_target': DEFAULT_DBT_TARGET,
            'default_models': DEFAULT_DBT_MODELS,
            'default_exclude': DEFAULT_DBT_EXCLUDE,
        },
        default_args={
            'owner': 'airflow',
        }
    ) as dag:
    
        dbt_seed_task = BashOperator(
            task_id='dbt_seed',
            bash_command=f"{bash_command_prefix} seed {seed_flags}",
            doc_md="Runs `dbt seed`. Accepts `dbt_project_dir`, `dbt_profiles_dir`, `dbt_target`, `dbt_full_refresh` from config.",
        )
    
        dbt_run_task = BashOperator(
            task_id='dbt_run',
            bash_command=f"{bash_command_prefix} run {run_test_flags}",
            doc_md="Runs `dbt run`. Accepts `dbt_project_dir`, `dbt_profiles_dir`, `dbt_target`, `dbt_models`, `dbt_exclude` from config.",
        )
    
        dbt_test_task = BashOperator(
            task_id='dbt_test',
            bash_command=f"{bash_command_prefix} test {run_test_flags}",
            doc_md="Runs `dbt test`. Accepts `dbt_project_dir`, `dbt_profiles_dir`, `dbt_target`, `dbt_models`, `dbt_exclude` from config.",
        )
    
        dbt_docs_generate_task = BashOperator(
            task_id='dbt_docs_generate',
            bash_command=f"{bash_command_prefix} docs generate {common_flags}", # Docs usually don't use select/exclude
            doc_md="Runs `dbt docs generate`. Accepts `dbt_project_dir`, `dbt_profiles_dir`, `dbt_target` from config.",
        )
    
        # --- Define Task Dependencies ---
        dbt_seed_task >> dbt_run_task >> dbt_test_task >> dbt_docs_generate_task
    ```
    Przeanalizuj kod przed uruchomieniem. Następnie sprawdź, czy DAG pojawił się w interfejsie Airflow.
8. Jeśli DAG się nie pojawił, należy rozwiązać problemy. W tym celu spróbuj:
   * w przypadku pojawienia się w interfejsie informacji o błędzie przeanalizuj i rozwiąż przyczyny
   * jeśli w interfejsie nie pojawiła się informacja o błędzie sprawdź, czy DAG został odnaleziony - przejdź do terminalu serwera vscode i uruchom:
        ```shell
        airflow dags list
        ```
        Powinny pojawić się dwa DAGi:
        ```shell
        dag_id                                  | fileloc                                          | owners  | is_paused
        ========================================+==================================================+=========+==========
        dbt_core_project_processor_parametrized | /config/airflow/dags/dbt_dag_run.py              | airflow | True     
        server_health_check_empty               | /config/airflow/dags/server_health_check_bash.py | airflow | False    
        ```
 
   * jeśli `dbt_dag_run` się nie pojawił, a pojawił się komunikat `Failed to load all files. For details, run 'airflow dags list-import-errors'` uruchom:
        ```shell
        airflow dags list-import-errors
        ```
        a następnie spróbuj rozwiązać błędy.
   * jeśli DAG został wyświetlony, ale status `is_paused` zwraca wartość `null` i DAG nie jest widoczny, spróbuj wykonać:
        ```shell
        airflow dags unpause dbt_dag_run
        ```
   * można również spróbować ponownie uruchomić serwer Airflow
9. Spróbuj uruchomić DAG z domyślnymi parametrami. Dlaczego nie działa?
10. Aby naprawić problem z brakiem dostępności projektu dbt utwórz link symboliczny:
   ```shell
       ln -s /config/workspace/spbd-lab-przetwarzanie-danych-w-chmurze/dbt/lab-dbt04/dbt_bookstore_lab/ /config/workspace/dbt_bookstore_lab
   ```
11. Aby ponowić próbę wykonania operacji wybierz task, którego egzekucja zakończyła się błędem i kliknij przycisk `Clear task`.
12. Wprowadź zmianę w harmonogramie, tak, aby przetwarzanie uruchamiało się co godzinę.


## Lab 06

W tym laboratorium utworzymy kolejny DAG, który będzie generował transakcje dla danego dnia, w którym DAG został uruchomiony. 
W tym celu utworzymy kolejny DAG, który będzie uruchamiał skrypt generujący dodatkowe dane z dnia, w którym skrypt został uruchomiony.
Można założyć, że symulacja imituje działanie pobierania danych z API systemu zawierającego nowych użytkowników i ich transakcje.

W tym celu będziemy uruchamiać skrypt, podobnie jak w laboratorium 02, z tym, że wykorzystamy dodatkowe parametry wykonania skryptu generatora, jak w poniższym przykładzie:
```shell
python generator.py --generate all --customers-offset 25052000000 --transactions-offset 25052000000 --customers-output /config/workspace/dbt_bookstore_lab/customers-250520.csv --transactions-output /config/workspace/dbt_bookstore_lab/transactions-250520.json --start-date 2025-05-19 --end-date 2025-05-19
```

Powyższe zapytanie wygeneruje dodatkowe pliki zawierające zarówno dane o nowo zarejestrrowanych klientach, jak i ich transakcjach. Pliki zostaną zapisane do nowego pliku csv/json.

### Tworzenie DAG

Aby wykonać to zadanie utworzymy kolejny DAG. Stwórz nowy plik `daily_data_generator.py` w folderze `/config/workspace/airflow/dags` i wklej do niego poniższy kod:
```python
from __future__ import annotations

import pendulum
import os

from airflow.models.dag import DAG
from airflow.operators.bash import BashOperator
from airflow.utils.dates import days_ago

# --- Default Configuration ---
# Ścieżka do skryptu generatora
GENERATOR_SCRIPT_PATH = os.getenv('GENERATOR_SCRIPT_PATH', '/config/workspace/spbd-lab-przetwarzanie-danych-w-chmurze/dbt/lab-dbt02/generator.py')
# Ścieżka do folderu wyjściowego dla dbt_bookstore_lab
DBT_BOOKSTORE_LAB_DIR = os.getenv('DBT_BOOKSTORE_LAB_DIR', '/tmp')
# Domyślna ścieżka do projektu dbt (używana przez dbt_dag_run)
DEFAULT_DBT_PROJECT_DIR = os.getenv('DBT_PROJECT_DIR', '/config/workspace/dbt_bookstore_lab/dbt_project')


# --- Templated Command Logic using Jinja ---
# Data wykonania DAGa (execution_date) będzie używana do generowania danych dla konkretnego dnia
# Format daty dla nazw plików i parametrów skryptu
templated_date_nodash = "{{ ds_nodash }}" # YYYYMMDD
templated_date_dash = "{{ ds }}"       # YYYY-MM-DD

# Nazwy plików wyjściowych z datą
templated_customers_output_file = f"{DBT_BOOKSTORE_LAB_DIR}/customers-{templated_date_nodash}.csv"
templated_transactions_output_file = f"{DBT_BOOKSTORE_LAB_DIR}/transactions-{templated_date_nodash}.json"

# Offsety - można je uczynić bardziej dynamicznymi, np. na podstawie poprzednich uruchomień lub bazy danych
# Dla uproszczenia, użyjemy daty jako części offsetu, aby zapewnić unikalność (to proste podejście, w produkcji wymagałoby to lepszego zarządzania)
templated_offset = "{{ ti.execution_date.strftime('%Y%m%d%H%M%S') }}"


# Budowanie komendy generatora
generate_data_command = (
    f"python {GENERATOR_SCRIPT_PATH} "
    f"--generate all "
    f"--customers-offset {templated_offset} " # Używamy dynamicznego offsetu
    f"--transactions-offset {templated_offset} " # Używamy dynamicznego offsetu
    f"--customers-output {templated_customers_output_file} "
    f"--transactions-output {templated_transactions_output_file} "
    f"--start-date {templated_date_dash} "
    f"--end-date {templated_date_dash}"
)


with DAG(
    dag_id='daily_data_generator',
    start_date=days_ago(1), # Uruchom od wczoraj
    schedule='@daily',      # Uruchamiaj codziennie o północy UTC
    catchup=False,          # Nie uruchamiaj dla przeszłych, nieuruchomionych interwałów
    tags=['data-generation', 'dbt', 'daily'],
    description='Generates daily customer and transaction data, then runs the dbt workflow.',
    default_args={
        'owner': 'airflow',
    },
) as dag:

    generate_daily_data_task = BashOperator(
        task_id='generate_daily_data',
        bash_command=generate_data_command,
        doc_md=(
            "Generates new customer and transaction data for the DAG's execution date. "
            "Output files are named with the execution date (e.g., customers-YYYYMMDD.csv)."
        ),
    )


```

Zwróć uwagę, że po kilku minutach (~2 minuty) po zapisaniu pliku w interfejsie Airflow pojawi się nowy DAG w stanie `Paused'.
Włącz DAG, który uruchomi się automatycznie.

> UWAGA! Jeśli po włączeniu DAG nie widzisz zmiany statusu oznacza to, że prawdobodobnie funkcja `Auto-refresh` jest wyłączona - włącz ją.

### Weryfikacja wykonania

W celu weryfikacji tego, czy udało się wygenerować pliki przejdź do logów DAGa w Airflow i zweryfikuj, że zostały wygenerowane nowe dane.
W logach powinny się znajdować wpsy podobne do:

```
[2025-05-20, 21:55:32 UTC] {subprocess.py:86} INFO - Output:
[2025-05-20, 21:55:34 UTC] {subprocess.py:93} INFO - Loading books from books.csv...
[2025-05-20, 21:55:34 UTC] {subprocess.py:93} INFO - Warning: Book file not found at books.csv. Proceeding without specific book details in transactions.
[2025-05-20, 21:55:34 UTC] {subprocess.py:93} INFO - Generating 100 customers to /config/workspace/dbt_bookstore_lab/customers-20250519.csv...
[2025-05-20, 21:55:34 UTC] {subprocess.py:93} INFO - Customer data saved successfully to '/config/workspace/dbt_bookstore_lab/customers-20250519.csv'.
[2025-05-20, 21:55:34 UTC] {subprocess.py:93} INFO - Generating transactions from 2025-05-19 to 2025-05-19 into /config/workspace/dbt_bookstore_lab/transactions-20250519.json...
[2025-05-20, 21:55:34 UTC] {subprocess.py:93} INFO - Warning: No book data loaded. Transactions will not have valid 'book_id' values.
[2025-05-20, 21:55:34 UTC] {subprocess.py:93} INFO - Transaction data saved successfully to '/config/workspace/dbt_bookstore_lab/transactions-20250519.json'. Total transactions generated: 24
[2025-05-20, 21:55:34 UTC] {subprocess.py:93} INFO - 
[2025-05-20, 21:55:34 UTC] {subprocess.py:93} INFO - Data generation process finished.
[2025-05-20, 21:55:34 UTC] {subprocess.py:97} INFO - Command exited with return code 0
```

> PYTANIE: Co stanie się, jeśli wykonasz operację `Clear state`?

> PYTANIE: Dlaczego w logach data generacji transakcji uzupełniona jest datą z dnia poprzedniego?

Jak widzisz, pliki zostały wygenerowane, ale załóżmy, że chcielibyśmy upewnić się, czy pliki rzeczywiście pojawiły się w folderze docelowym - w tym celu dodajmy kolejny task w naszym DAG:

```python
    verify_files_exist_task = BashOperator(
        task_id='verify_generated_files_exist',
        bash_command=(
            f"echo 'Verifying existence of generated files...' && "
            f"ls -l {templated_customers_output_file} && "
            f"ls -l {templated_transactions_output_file} && "
            f"echo 'Generated files found.'"
        ),
        doc_md=(
            "Verifies that the customer and transaction files for the execution date have been generated "
            "in the target directory. The task will fail if `ls` returns an error (e.g., file not found)."
        ),
    )

    generate_daily_data_task >> verify_files_exist_task
```

### Przesyłanie danych do S3

W inżynierii danych bardzo często spotykanym rozwiązaniem jest wykorzystywanie koncepcji data lake oraz umieszczania danych w kontenerach takich, jak s3, często korzystając z partycjonowania hive.
Dodajmy więc kolejne taski (po jednym dla każdego z plików `customers` i `transactions`), które przeniosą wygenerowane pliki do wcześniej utworzonego bucketu S3, tak, aby znalazły się w ścieżce: 

```
s3://<nazwa_bucketu>/data-lake/raw-data/<rodzaj-pliku>/date=<data-generacji>/<nazwa-pliku>
```

gdzie `<rodzaj-pliku>` to odpowiednio `customers` lub `transactions`, `<data-generacji>` pobierana jest ze zmiennej `templated_date_dash`, a `<nazwa-bucketu>` jest pobierana ze zmiennej globalnej `S3_bucket_name` zdefiniowanej w interfejsie Airflow.

Do aktualnego DAGa dodaj następujące fragmenty:
- w sekcji importów:
    ```python
    from airflow.models import Variable # Dodaj ten import na początku pliku DAGa
    ```
- w sekcji konfiguracji, przed definicją DAG:
    ```python
        # --- S3 Upload Configuration ---
        # Pobieranie nazwy bucketa S3 z Airflow Variables
        # Pierwszy argument to nazwa zmiennej w Airflow UI,
        # drugi to opcjonalna wartość domyślna, jeśli zmienna nie istnieje.
        S3_BUCKET_NAME = Variable.get("S3_bucket_name") # Upewnij się, że nazwa zmiennej ("S3_bucket_name") jest taka sama jak w Airflow UI
    
        # Ścieżki docelowe w S3
        s3_customers_target_path = f"s3://{S3_BUCKET_NAME}/data-lake/raw-data/customers/date={templated_date_dash}/customers-{templated_date_nodash}.csv"
        s3_transactions_target_path = f"s3://{S3_BUCKET_NAME}/data-lake/raw-data/transactions/date={templated_date_dash}/transactions-{templated_date_nodash}.json"
    
        # Komendy AWS CLI do kopiowania plików
        upload_customers_to_s3_command = f"aws s3 cp {templated_customers_output_file} {s3_customers_target_path}"
        upload_transactions_to_s3_command = f"aws s3 cp {templated_transactions_output_file} {s3_transactions_target_path}"
    ```
- wewnątrz definicji DAG:
    ```python
        # --- Define S3 Upload Tasks ---
        upload_customers_to_s3_task = BashOperator(
            task_id='upload_customers_to_s3',
            bash_command=upload_customers_to_s3_command,
            doc_md=(
                f"Uploads the generated customers CSV file to S3: {s3_customers_target_path}. "
                "Requires AWS CLI to be configured and have necessary S3 write permissions."
            ),
        )
    
        upload_transactions_to_s3_task = BashOperator(
            task_id='upload_transactions_to_s3',
            bash_command=upload_transactions_to_s3_command,
            doc_md=(
                f"Uploads the generated transactions JSON file to S3: {s3_transactions_target_path}. "
                "Requires AWS CLI to be configured and have necessary S3 write permissions."
            ),
        )
    ```
- w sekcji zależności dodaj:
    ```python
        # --- Update Task Dependencies ---
        # Zakładając, że poprzednie taski to generate_daily_data_task i verify_files_exist_task
        # Nowe taski S3 powinny być uruchamiane po weryfikacji istnienia plików.
        verify_files_exist_task >> [upload_customers_to_s3_task, upload_transactions_to_s3_task]
    ```

### Ustawienie zmiennych

Powyższy DAG nie będzie mógł być prawidłowo sparsowany, ponieważ nie istnieje zmienna globalna `S3_bucket_name`, widoczny będzie błąd:

```
Broken DAG: [/config/airflow/dags/daily_data_generator.py]
Traceback (most recent call last):
  File "/config/airflow/dags/daily_data_generator.py", line 51, in <module>
    S3_BUCKET_NAME = Variable.get("S3_bucket_name") # Upewnij się, że nazwa zmiennej ("S3_bucket_name") jest taka sama jak w Airflow UI
                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/app/venv/lib/python3.12/site-packages/airflow/models/variable.py", line 143, in get
    raise KeyError(f"Variable {key} does not exist")
KeyError: 'Variable S3_bucket_name does not exist'
```

Aby usunąć ten błąd należy utworzyć zmienną `S3_bucket_name` w menu `Admin -> Variables`. W polu `Val` umieść nazwę publicznego bucketu, który utowrzyliśmy we wcześniejszych laboratoriach.

#### Konfiguracja dostępu do AWS

Po uruchomieniu zadania `upload_customers_to_s3` i `upload_transactions_to_s3` zakończą się błędem. 
Jest to spowodowane konfiguracją konta AWS, które wymaga każdorazowo aktualizacji `~/.aws/credentials` - przejdż do konsoli w VSCode serwerze i zaktualizj plik `credentials`.

#### Weryfikacja ładowania plików do S3

Otwórz konsolę AWS i przejdź do zakładki S3, nasteępnie do bucketu, którego nazwa została podana w zmiennej `S3_bucket_name` i zweryfikuj, czy pliki zostały załadowane.

### Cathup & Backfilling

#### Catchup
Airflow umożliwia również załadowanie danych historycznych. Nasz DAG nadaje się świetnie do załadowania historii za pomocą backfillingu.
Aby załadować dane z poprzednich 7 dni zaktualizujmy wartość `start_date=days_ago(7)` zamiast aktualnego `start_date=days_ago(7)`.

Zauważmy, że po zmianie tej wartości nic się nie wydarzyło. Spróbujmy zatem zaktualizować więc kolejną zmienną konfiguracyjną `catchup=True` zamiast `catchup=False`. 

Efekt? Znów nie zadziałało.

#### Usunięcie informacji o DAG

Aby zaprezentować jak działa opcja `catchup` usuniemy informacje o wszystkich dotychczasowych egzekucjach DAGa `daily_data_generator`. W tym celu użyjemy czerwonej ikony 'śmietnika' opisanej `Delete DAG`.

Zwróć uwagę, że po kliknięciu `Delete DAG`, tak naprawdę nie suwamy DAGa, ale informacje o jego wcześniejszych wykonaniach. 
Definicja DAG wciąż znajduje się w pliku `/config/airflow/dags/daily_data_generator.py` i DAG będzie pojawiał się w interfejsie Airflow dopóki jej stamtąd nie usuniemy.

Natomiast ważne jest to, że po kliknięciu `Delete DAG` wszedł on ponownie w status `Paused`. Włączmy go ponownie. Po uruchomieniu funkcja `cathup` uzupełni brakujące wykonania DAGa dla okresu ostatnich 7 dni, tak jak zdefiniowano w parametrze `start_date`.

#### Backfilling

Niezależnie od funkcji `cathup` możemy również skorzystać z opcji `backfilling`, która umożliwia nam załadowanie brakujących danych za dowolny okres, nawet taki, który wykracza poza granicę `start_date`. 
Jednak funkcja backfilling jest dostępna jedynie jako komenda CLI:

```shell
airflow dags backfill \
    --start-date YYYY-MM-DD \
    --end-date YYYY-MM-DD \
    daily_data_generator
```
 czyli w naszym przypadku wykonajmy ładowanie za ostatnie 3 dni poprzedzające okres, który już został załadowany (przykładowo jeśli dziś przypada 11 stycznia, korzystając z funkcji catchup załadowaliśmy dane za okres 4-9 stycznia, zatem 3 poprzedzające dni oznaczają 1-3 stycznia).

#### Generowanie transakcji dla istniejących (nie nowych) użytkowników

Dodajmy dodatkowe bloki, które z istniejących danych wygenerują plik csv zawierający listę wszystkich użytkowników, 
następnie wygenerują transakcje za dany okres dla istniejących wcześniej użytkowników. W tym celu musimy wykonać kilka kroków,
które dodamy z wykorzystaniem notacji `taskflow`. Na końcu pliku definiującego DAG dodaj:

```python
    from airflow.decorators import task
    import duckdb
    # --- Update Task Dependencies ---
    # Zakładając, że poprzednie taski to generate_daily_data_task i verify_files_exist_task
    # Nowe taski S3 powinny być uruchamiane po weryfikacji istnienia plików.
    verify_files_exist_task >> [upload_customers_to_s3_task, upload_transactions_to_s3_task]

    # Konfiguracja ścieżek S3 (zastąp swoimi danymi)
    s3_endpoint = f"s3://{S3_BUCKET_NAME}/"
    s3_region = "eu-central-1"  # Zmień na swój region AWS (opcjonalnie)

    # Ścieżka do partycjonowanych plików CSV w S3 (przykład)
    s3_path_pattern = f"{s3_endpoint}data-lake/raw-data/customers/date=*/*.csv"

    # Ścieżka do lokalnego pliku wyjściowego
    local_output_file = "/tmp/all_customers.csv"

    @task
    def read_s3_hive_and_export():
        # Konfiguracja dostępu do S3
        con = duckdb.connect(database=':memory:', read_only=False)
        con.sql(f"INSTALL httpfs;")
        con.sql(f"LOAD httpfs;")
        con.sql(f"""CREATE OR REPLACE SECRET secret (TYPE s3, PROVIDER credential_chain, CHAIN config, PROFILE 'default');""")

        # Odczyt partycjonowanych plików CSV z S3 z uwzględnieniem partycjonowania Hive
        query = f"""
        COPY (SELECT * FROM read_csv_auto('{s3_path_pattern}', hive_partitioning=TRUE))
        TO '{local_output_file}' (HEADER, DELIMITER ',');
        """
        con.sql(query)
        print(f"Dane klientów zostały wyeksportowane do: {local_output_file}")
        con.close()

    export_task = read_s3_hive_and_export()

    # Budowanie komendy generatora
    templated_offset_2 = "{{ ti.execution_date.strftime('%Y%m%d30%M%S') }}"
    templated_transactions_output_file_2 = f"{DBT_BOOKSTORE_LAB_DIR}/transactions-existing-{templated_date_nodash}.json"
    generate_data_command_existing_customers = (
        f"python {GENERATOR_SCRIPT_PATH} "
        f"--generate transactions "
        f"--customers-input {local_output_file} " # Używamy dynamicznego offsetu
        f"--transactions-offset {templated_offset_2} " # Używamy dynamicznego offsetu
        f"--transactions-output {templated_transactions_output_file_2} "
        f"--start-date {templated_date_dash} "
        f"--end-date {templated_date_dash}"
    )

    @task.bash
    def generate_transactions_for_existing_customers() -> str:
        return generate_data_command_existing_customers

    transactions_for_existing_customers = generate_transactions_for_existing_customers()

    s3_transactions_target_path_2 = f"s3://{S3_BUCKET_NAME}/data-lake/raw-data/transactions/date={templated_date_dash}/transactions-existing-{templated_date_nodash}.json"
    upload_transactions_to_s3_command = f"aws s3 cp {templated_transactions_output_file_2} {s3_transactions_target_path_2}"

    @task.bash
    def uploading_transactions_to_s3() -> str:
        return upload_transactions_to_s3_command

    upload_transactions_to_s3 = uploading_transactions_to_s3()

    generate_daily_data_task >> export_task >> transactions_for_existing_customers >> upload_transactions_to_s3
```

#### Analiza danych z wykorzystaniem AWS Athena

Na koniec zweryfikujemy możliwość analizy danych za pomocą usługi AWS Athena.
 
### Zadania dodatkowe:
1. Korzystając z dbt utwórz modele w donwstream, które nie zawierają klientów, którzy nie zawarli żadnej transakcji.
2. Wykorzystaj materializację `incremental`, która będzie ładowała do 'hurtowni danych' wyłącznie nowe rekordy.
3. Zaproponuj dodatkowe pola techniczne zawierające np. informacje o dacie ładowania, pliku źródłowym, ostatniej aktualizaji itp. i zaimplementuj je w modelu

## Usunięcie kosztownych zasobów

Większość zasobów, z których korzystamy podczas laboratorium generuje pomijalne lub zerowe koszty, jednak wirtualna maszyna 
generuje istotne dla dostępnego w ramach laboratorium limitu koszty. W celu usunięcia tylko wirtualnej maszyny możliwe jest 
usunięcie celowanego zasobu oraz zasobów od niego zależnych. W tym celu uruchom:

```shell
terraform destroy -target=aws_instance.lab_instance
```

airflow dags backfill \
    --start-date 2025-05-20 \
    --end-date 2025-05-22 \
    daily_data_generator