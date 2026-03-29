# Manual Generatora Danych (generator.py)

Ten dokument zawiera szczegółowe instrukcje dotyczące obsługi skryptu `generator.py`, który służy do generowania syntetycznych danych o klientach oraz transakcjach dla fikcyjnej księgarni.

## 1. Wymagania
Skrypt wymaga Pythona w wersji 3.x oraz biblioteki `Faker`.
Aby zainstalować zależności, wykonaj:
```bash
pip install faker
```

## 2. Podstawowe działanie
Skrypt może pracować w trzech trybach:
- `all` (domyślny): Generuje nowych klientów, a następnie transakcje dla nich.
- `customers`: Generuje tylko plik z danymi klientów.
- `transactions`: Generuje tylko transakcje na podstawie istniejącego pliku klientów.

## 3. Przykłady wykorzystania

### A. Generowanie kompletnego zestawu danych (domyślne)
Generuje 100 klientów i transakcje dla nich w domyślnym zakresie dat (2016-2024).
```bash
python generator.py
```

### B. Generowanie tylko klientów
Generuje 500 klientów do pliku `klienci.csv`.
```bash
python generator.py --generate customers --num-customers 500 --customers-output klienci.csv
```

### C. Generowanie transakcji dla istniejących klientów
Jeśli masz już plik `my_customer_list.csv` i chcesz dla nich dogenerować transakcje:
```bash
python generator.py --generate transactions --customers-input my_customer_list.csv --transactions-output moje_transakcje.json
```

### D. Personalizacja zakresu dat i ID
Generowanie transakcji tylko dla roku 2023, zaczynając numerację transakcji od 10000:
```bash
python generator.py --start-date 2023-01-01 --end-date 2023-12-31 --transactions-offset 10000
```

### E. Scenariusze zaawansowane

#### 1. Symulacja dużej bazy (stress test)
Generowanie 10 000 klientów do testów wydajnościowych:
```bash
python generator.py --generate customers --num-customers 10000 --customers-output big_customers.csv
```

#### 2. Generowanie danych partiami (Batches)
Jeśli chcesz wygenerować drugą partię klientów, zaczynając od ID 1001, aby nie dublować kluczy:
```bash
python generator.py --generate customers --num-customers 500 --customers-offset 1001 --customers-output customers_batch_2.csv
```

#### 3. Generowanie transakcji dla specyficznego okresu (np. "Black Friday")
```bash
python generator.py --generate transactions --start-date 2024-11-20 --end-date 2024-11-30 --transactions-output transactions_november.json
```

#### 4. Szybki test (Small Sample)
Generowanie tylko 5 klientów i ich transakcji do szybkiego podglądu struktury:
```bash
python generator.py --num-customers 5 --customers-output test.csv --transactions-output test.json
```

## 4. Customizacja Inputu

### Dane Książek (`--books-input`)
Generator transakcji losuje `book_id` z pliku CSV. Domyślnie szuka `books.csv`.
Wymagany nagłówek w pliku książek to `index`.
**Przykład własnego pliku książek (`moje_ksiazki.csv`):**
```csv
index,tytul,autor
B01,Wiedźmin,Andrzej Sapkowski
B02,Solaris,Stanisław Lem
```
Użycie:
```bash
python generator.py --books-input moje_ksiazki.csv
```

### Dane Klientów (`--customers-input`)
Przy trybie `--generate transactions` skrypt wczytuje klientów.
Wymagane nagłówki: `customer_id` oraz `registration_date` (format YYYY-MM-DD).

## 5. Customizacja Outputu

### Klient (CSV)
Plik wynikowy zawiera kolumny:
- `customer_id`, `first_name`, `last_name`, `email`, `phone_number`, `address`, `city`, `country`, `postal_code`, `age`, `gender`, `registration_date`, `related_accounts`.

### Transakcje (NDJSON)
Transakcje są zapisywane w formacie **Newline Delimited JSON**. Każda linia to osobny obiekt JSON.
**Struktura obiektu:**
```json
{
  "transaction_id": 1,
  "customer_id": "1",
  "transaction_date": "2023-05-10",
  "items": [
    {"book_id": "123", "unit_price": 29.99, "quantity": 1},
    {"book_id": "456", "unit_price": 15.50, "quantity": 2}
  ],
  "cash_register": 5,
  "cashier": "5-2"
}
```

## 6. Pełna lista argumentów CLI

| Argument | Opis | Domyślnie |
| :--- | :--- | :--- |
| `--generate` | Co generować: `customers`, `transactions`, `all` | `all` |
| `--num-customers` | Liczba klientów do wygenerowania | `100` |
| `--customers-offset` | Początkowe ID klienta | `1` |
| `--start-date` | Data początkowa transakcji (RRRR-MM-DD) | `2016-01-01` |
| `--end-date` | Data końcowa transakcji (RRRR-MM-DD) | `2024-12-31` |
| `--customers-input` | Ścieżka do wejściowego pliku klientów | `customers.csv` |
| `--customers-output` | Gdzie zapisać wygenerowanych klientów | `customers.csv` |
| `--transactions-output` | Gdzie zapisać transakcje | `transactions.json` |
| `--transactions-offset` | Początkowe ID transakcji | `1` |
| `--books-input` | Ścieżka do pliku z bazą książek | `books.csv` |

## 7. Wskazówki zaawansowane

1. **Różnorodność Locales**: Skrypt korzysta z listy lokalizacji (m.in. `pl_PL`, `en_GB`, `de_DE`), co zapewnia realistyczne imiona, adresy i telefony z różnych krajów.
2. **Realizm transakcji**: 
   - Transakcje nie mogą wystąpić przed datą rejestracji klienta.
   - Prawdopodobieństwo zakupu jest losowane w interwałach miesięcznych (ok. 30% szansy na transakcję w miesiącu).
   - Liczba przedmiotów w koszyku: 1-5.
3. **Obsługa błędów**: Jeśli plik książek nie zostanie znaleziony, skrypt wstawi `UNKNOWN` jako `book_id` w transakcjach.
