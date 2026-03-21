# Instrukcja do laboratorium Airflow

## 1. Instalacja Apache Airflow

Do instalacji Apache Airflow wykorzystamy paczki pythonowe.

```bash
sudo apt update
sudo apt install python3-pip
pip install apache-airflow
```

Po instalacji paczki, może być konieczne ponowne zalogowanie się, aby polecenie `airflow` było dostępne w terminalu.

## 2. Uruchomienie serwera Airflow

Aby uruchomić serwer Airflow, należy wykonać komendę:

```bash
airflow standalone
```

Dobrą praktyką jest uruchomienie serwera w tle, aby działał nawet po zamknięciu terminala. Można to zrobić za pomocą `nohup`:

```bash
nohup airflow standalone &
```

Po pierwszym uruchomieniu, hasło do logowania zostanie wygenerowane i zapisane w pliku `~/airflow/standalone_admin_password.txt`.

## 3. Konfiguracja

### Wyłączenie przykładowych DAGów

Domyślnie Airflow ładuje przykładowe DAGi. Aby temu zapobiec, można przed pierwszym uruchomieniem serwera ustawić zmienną środowiskową:

```bash
export AIRFLOW__CORE__LOAD_EXAMPLES=False
```

Alternatywnie, można zmienić wartość `load_examples` na `False` w pliku konfiguracyjnym `~/airflow/airflow.cfg`:

```ini
[core]
load_examples = False
```

Po zmianie w pliku konfiguracyjnym, może być konieczne zresetowanie bazy danych Airflow i odświeżenie strony w przeglądarce (Ctrl+Shift+R):

```bash
airflow db reset -y
```

### Ładowanie własnych DAGów

Aby załadować własne DAGi, należy skopiować je do folderu `~/airflow/dags/`.

## 4. Pobranie i załadowanie DAGów z repozytorium

Należy sklonować repozytorium z DAGami, a następnie skopiować je do odpowiedniego folderu Airflow.

```bash
git clone https://github.com/siudzinskim/spbd-lab-przetwarzanie-danych-w-chmurze
cp -r spbd-lab-przetwarzanie-danych-w-chmurze/airflow/modules/* ~/airflow/dags/
```
> **Uwaga:** W miejsce `<link_do_repozytorium>` i `<nazwa_folderu_z_dagami>` należy wstawić odpowiednie wartości.