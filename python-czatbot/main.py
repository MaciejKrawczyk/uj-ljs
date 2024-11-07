import json
import ollama


def get_opening_hours():
    with open("opening_hours.json", "r") as f:
        oh = json.load(f)
        return json.dumps(oh)


def get_menu():
    with open("menu.json", "r") as f:
        menu = json.load(f)
        return json.dumps(menu)


def place_order():
    pass


def get_order_status():
    pass


def do_nothing():
    pass


CHATBOT_SYSTEM_PROMPT = """
You are a helpful assistant of a restaurant. You will provide information about the restaurant, people can place an order with your help.
Your response will be a json in this format: {function: <function to call>}
Functions to call:
- get_opening_hours: returns the opening hours of the restaurant
- get_menu: returns the menu of the restaurant
- place_order: places an order with the restaurant
- get_order_status: returns the status of an order
- do_nothing: does nothing, call when other functions are not applicable
"""


def chatbot():
    print("Welcome to Ollama Streaming Chat!")
    print("Type your message and press Enter. Type 'exit' to quit.\n")

    while True:
        user_input = input("You: ")

        if user_input.lower() == 'exit':
            print("Goodbye!")
            break

        print("Ollama: ")

        response = ollama.chat(
            model="llama3.1",
            stream=False,
            messages=[
                {"role": "system", "content": CHATBOT_SYSTEM_PROMPT},
                {"role": "user", "content": user_input}
            ],
            format="json",
        )
        bot_output = json.loads(response['message']['content'])

        function = bot_output['function']

        if function is 'get_opening_hours' or 'get_menu':
            chatbot_prompt2 = """
            You are a helpful assistant of a restaurant. You will provide information about the restaurant, people can place an order with your help.
            Using this information, kindly response to the user: """ + globals()[function]()
            response = ollama.chat(
                model="llama3.1",
                stream=False,
                messages=[
                    {"role": "system", "content": chatbot_prompt2},
                    {"role": "user", "content": user_input}
                ],
            )

            print(response['message']['content'])
        elif function is 'place_order':
            menu_dict = json.loads(get_menu())
            for dish in menu_dict:
                print(f"{dish['name']}, {dish['price']}")

            order = []

            chatbot_prompt = globals()['get_menu']() + """
                This is a list of available dishes that the user can order. Based on a user input:
                1. Check if the dish provided by the user exist in a menu,
                2. If yes, output {dish_id: <dishID>}
                3. If no, tell the user that the dish does not exist in the menu
                4. If user decides to finish an order, output {finish_order: <True/False>}
            """



    print()


if __name__ == "__main__":
    chatbot()
