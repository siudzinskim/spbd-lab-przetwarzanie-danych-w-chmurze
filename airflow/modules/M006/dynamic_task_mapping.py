import time

import pendulum
from airflow.decorators import task, dag

@dag(start_date=pendulum.yesterday(),
     schedule="@once",
     dag_id="dynamic_task_mapping",
     catchup=False,
     tags=['module 006', 'dynamic_task_mapping']
     )
def my_dag():
    @task
    def get_fruits() -> list[str]:
        fruits = [
            {'apple': 1}, {'banana': 2}, {'cherry': 3}, {'date': 4}, {'elderberry': 5},
            {'fig': 6}, {'grapefruit': 7}, {'honeydew': 8}, {'indian_plum': 9}, {'jackfruit': 10},
            {'kiwi': 11}, {'lemon': 12}, {'mango': 13}, {'nectarine': 14}, {'orange': 15},
            {'papaya': 16}, {'quince': 17}, {'raspberry': 18}, {'strawberry': 19}, {'tangerine': 20},
            {'ugli_fruit': 21}, {'vanilla_bean': 22}, {'watermelon': 23}, {'xigua': 24}, {'yellow_passionfruit': 25},
            {'zucchini': 26}, {'apricot': 27}, {'blackberry': 28}, {'cranberry': 29}, {'dragon_fruit': 30},
            {'feijoa': 31}, {'gooseberry': 32}, {'huckleberry': 33}, {'ita_palm': 34}, {'jujube': 35},
            {'kumquat': 36}, {'lime': 37}, {'mulberry': 38}, {'olive': 39}, {'persimmon': 40},
            {'pineapple': 41}, {'rambutan': 42}, {'soursop': 43}, {'tomato': 44}, {'unicorn_fruit': 45},
            {'viburnum': 46}, {'white_sapote': 47}, {'xoconostle': 48}, {'yuzu': 49}
        ]
        return fruits

    @task
    def pick_your_fruit(fruit: dict[int, str]):
        time.sleep(list(fruit.values())[0])  # Simulate computation time
        print(f"My favorite fruit is {list(fruit.keys())[0]}")

    pick_your_fruit.expand(fruit=get_fruits())


pick_fruits = my_dag()
