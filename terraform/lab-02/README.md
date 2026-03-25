Aby uruchomić ten moduł konieczne będzie targetowane uruchamianie krok po kroku.

najpierw upewniamy się że moduł lab-01 jest na pewno zaaplikowany i aktualny
następnie uruchamiamy `terraform apply -target=local_file.kubeconfig` żeby mieć pewność że nawiązujemy połączenie z klastrem
w kolejnym kroku uruchamiamy `terraform apply -target=kubectl_manifest.dashboard_ingress` aby uruchomić interfejs k8s dashboard
a na koniec `terraform apply -target=helm_release.airflow`