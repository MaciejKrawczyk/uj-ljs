import json

import ollama

CHATBOT_SYSTEM_PROMPT = """
You are a helpful assistant of a restaurant. You will provide information about the restaurant, people can place an order with your help.
Your response will be a json in this format: {output: <your response>, status: <function to call>}
Functions to call:
- get_opening_hours: returns the opening hours of the restaurant
- get_menu: returns the menu of the restaurant
- place_order: places an order with the restaurant
- get_order_status: returns the status of an order
"""


def stream_chat():
    print("Welcome to Ollama Streaming Chat!")
    print("Type your message and press Enter. Type 'exit' to quit.\n")

    while True:
        user_input = input("You: ")

        if user_input.lower() == 'exit':
            print("Goodbye!")
            break

        print("Ollama: ", end="", flush=True)

        for chunk in ollama.chat(
                model="llama3.1",
                stream=True,
                messages=[
                    {"role": "system", "content": CHATBOT_SYSTEM_PROMPT},
                    {"role": "user", "content": user_input}
                ],
                format="json",
        ):
            print(chunk['message']['content'], end="", flush=True)

        print()


class Restaurant:
    def __init__(self):
        self.orders = []

    def get_opening_hours(self):
        with open("opening_hours.json") as f:
            opening_hours = json.load(f)
        return opening_hours

    def get_menu(self):
        with open("menu.json") as f:
            menu = json.load(f)
        return menu


# Run the streaming chat
if __name__ == "__main__":
    stream_chat()
