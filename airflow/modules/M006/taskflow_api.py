import pendulum
from airflow.decorators import dag, task
from airflow.utils.trigger_rule import TriggerRule


@dag(
    dag_id='taskflow_benefits_demo',
    start_date=pendulum.yesterday(),
    schedule=None,
    catchup=False,
    tags=['module 006', 'taskflow']
)
def taskflow_demo():
    @task
    def extract_data_from_api():
        # Simulate extracting data from an API
        data = {
            "orders": [
                {"order_id": 1, "amount": 100},
                {"order_id": 2, "amount": 200},
                {"order_id": 3, "amount": 300}
            ],
            "customers": [
                {"customer_id": 1, "name": "Alice"},
                {"customer_id": 2, "name": "Bob"}
            ]
        }
        return data

    @task(multiple_outputs=True)
    def process_orders(data):
        # Process orders data (e.g., calculate total amount)
        total_amount = sum(order["amount"] for order in data["orders"])
        return {"total_amount": total_amount, "order_count": len(data["orders"])}

    @task
    def process_customers(data):
        # Process customer data (e.g., count customers)
        return len(data["customers"])

    @task
    def analyze_data(total_amount, order_count, customer_count):
        # Perform some analysis (e.g., calculate average order value)
        avg_order_value = total_amount / order_count if order_count else 0
        print(f"Total amount: {total_amount}")
        print(f"Order count: {order_count}")
        print(f"Customer count: {customer_count}")
        print(f"Average order value: {avg_order_value}")

    @task(trigger_rule=TriggerRule.ALL_DONE)
    def send_notification(total_amount):
        # Simulate sending a notification (e.g., via email or Slack)
        print(f"Sending notification: Total order amount is {total_amount}")

    # Define task dependencies
    data = extract_data_from_api()
    order_summary = process_orders(data)
    customer_count = process_customers(data)

    analyze_data(order_summary["total_amount"], order_summary["order_count"], customer_count)
    send_notification(order_summary["total_amount"])


taskflow_demo_dag = taskflow_demo()
