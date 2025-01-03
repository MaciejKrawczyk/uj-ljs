import json
from datetime import datetime
from random import randint

import ollama

from consts import CHATBOT_SYSTEM_PROMPT
from functions import do_nothing, get_order_status, place_order, print_menu, get_opening_hours, get_menu_str, \
    get_opening_hours_str

orders = []


class Config:
    def __init__(self, model="llama3.1"):
        self.model = model


class Chat:
    def __init__(self, system_prompt: str, config: Config):
        self.system_prompt = system_prompt
        self.config = config

    def get_json_response(self, conversation_history: list[dict]):
        response = ollama.chat(
            model=self.config.model,
            stream=False,
            messages=[
                         {"role": "system", "content": self.system_prompt},
                     ] + conversation_history,
            format="json"
        )
        # print(f"***TEST: {response['message']}***")
        json_output = json.loads(response['message']['content'])
        return json_output

    def get_response(self, conversation_history: list[dict]) -> dict:
        # print(f"TEST***{conversation_history}")
        response = ollama.chat(
            model=self.config.model,
            stream=False,
            messages=[
                         {"role": "system", "content": self.system_prompt},
                     ] + conversation_history,
        )
        output = response['message']['content']
        # print(f"***TEST: {response['message']}***")
        return {
            "output": output,
            "conversation_history": conversation_history + [{"role": "assistant", "content": output}]
        }


def get_today():
    return datetime.now().strftime("%A")  # Returns the day of the week (e.g., Monday)


def get_time():
    return datetime.now().strftime("%H:%M")  # Returns time in hours and minutes (e.g., 14:30)


class OpeningHourChat:
    def __init__(self):
        self.system_prompt = (
            f"Jesteś pomocnym asystentem restauracji. Udzielasz informacji o godzinach otwarcia restauracji."
            f"Godziny otwarcia restauracji w formacie json: {get_opening_hours_str()}"
            f"Dzisiaj jest: {get_today()}. godzina: {get_time()}")
        # print(f"prompt: {self.system_prompt}")
        self.chat = Chat(self.system_prompt, Config())

    def answer(self, conversation_history: list[dict]):
        return self.chat.get_response(conversation_history)


class CollectingChat:
    def __init__(self):
        self.system_prompt = "Jesteś pomocnym asystentem restauracji. Użytkownik jest w trakcie składania zamówienia. Na podstawie wiadomości od użytkownika, zwróć json {output: <boolean>}, czy już zamówienie zostało już skończone czy nie."
        self.chat = Chat(self.system_prompt, Config())

    def is_order_finished(self, conversation_history: list[dict]):
        return self.chat.get_json_response(conversation_history)


class PlaceOrderChat:
    def __init__(self):
        self.system_prompt = f"Jesteś pomocnym asystentem restauracji. Pomagasz w zebraniu zamówienia z menu. Menu w formacie json: {get_menu_str()}. Jeśli jakaś rzecz nie znajduje się w menu, poinformuj o tym użytkownika i powiedz żeby spróbował coś innego. Jeśli użytkownik skończy składać zamówienie, poinformuj go o wszystkich zamówionych rzeczach"
        self.chat = Chat(self.system_prompt, Config())

    def answer(self, conversation_history: list[dict]):
        return self.chat.get_response(conversation_history)


class GetMenuChat:
    def __init__(self):
        self.system_prompt = f"Jesteś pomocnym asystentem restauracji. Udzielasz informacji o menu. Menu w formacie json: {get_menu_str()}"
        self.chat = Chat(self.system_prompt, Config())

    def answer(self, conversation_history: list[dict]):
        return self.chat.get_response(conversation_history)


class GetOrderStatusChat:
    def __init__(self):
        self.system_prompt = f""
        self.chat = Chat(self.system_prompt, Config())

    def answer(self, conversation_history: list[dict]):
        return self.chat.get_response(conversation_history)


class NormalConversationChat:
    def __init__(self, system_prompt: str):
        self.system_prompt = f""


class RestaurantChat:
    def __init__(self):
        pass


class OrderedDish:
    def __init__(self, dish_id: int, special_instruction: str):
        self.dish_id = dish_id
        self.special_instruction = special_instruction

    def get_dish(self):
        return {"id": self.dish_id, "special_instruction": self.special_instruction}

    def get_dish_str(self):
        return json.dumps(self.get_dish())


class RestaurantOrder:
    def __init__(self, ordered_dishes: list[OrderedDish]):
        self.ordered_dishes = ordered_dishes
        self.order_id = randint(1, 1000)


class Order:
    def __init__(self, dish_ids: list[int], menu: list[dict]):
        self.order_id = randint(1, 1000)
        self.dish_ids = dish_ids
        self.menu = menu


def get_scenario(user_prompt: str):
    response = ollama.chat(
        model="llama3.1",
        stream=False,
        messages=[
            {"role": "system", "content": CHATBOT_SYSTEM_PROMPT},
            {"role": "user", "content": user_prompt}
        ],
        format="json",
    )
    bot_output = json.loads(response['message']['content'])
    function = bot_output['function']
    return function


def opening_hours_scenario(conversation_history: list[dict]):
    chat = OpeningHourChat()
    # print("*opening hours scenario*")
    data = chat.answer(conversation_history)
    print(data['output'])
    return data['conversation_history']


def menu_scenario(conversation_history: list[dict]):
    chat = GetMenuChat()
    data = chat.answer(conversation_history)
    print(data['output'])
    # print('*menu scenario*')
    return data['conversation_history']


def order_scenario(conversation_history: list[dict]):
    chat = PlaceOrderChat()
    data = chat.answer(conversation_history)
    is_finished = False
    collecting_chat = CollectingChat()
    ordering_chat_conversation_history = conversation_history
    while not is_finished:
        response_collecting = collecting_chat.is_order_finished(ordering_chat_conversation_history)
        print(f"response collecting: {response_collecting}")
        is_finished = response_collecting['output']
        # print(f"is finished: {is_finished}")
        if is_finished:
            break
        response = chat.answer(ordering_chat_conversation_history)
        # print(f"response: {response}")
        ordering_chat_conversation_history = response['conversation_history']
        print(response['output'])
        user_input = input("Ty: ")
        ordering_chat_conversation_history.append({"role": "user", "content": user_input})
    print('finishing...')

    final_response = chat.answer(conversation_history + [{"role": "system", "content": "Podsumowanie zamówienia: "}])
    print(final_response['output'])
    return data['conversation_history']


def order_status_scenario(conversation_history: list[dict]):
    chat = GetOrderStatusChat()
    data = chat.answer(conversation_history)
    print(data['output'])
    return data['conversation_history']


def chatbot():
    print("Witaj w restauracji Daniowo 🍽, jestem asystentem Pomidorówka 🧑‍🤝‍🧑. W czym mogę pomoć?")
    last_scenario = None
    conversation_history = []
    while True:
        user_input = input("Ty: ")

        if user_input.lower() == 'exit':
            print("Goodbye!")
            break

        print("Pomidorówka: ")
        function = get_scenario(user_input)

        if function == 'get_opening_hours':
            if last_scenario != 'get_opening_hours':
                conversation_history = []
            conversation_history.append({"role": "user", "content": user_input})
            last_scenario = function
            print(f"*****TEST: {conversation_history}")
            conversation_history = opening_hours_scenario(conversation_history)

        elif function == 'get_menu':
            if last_scenario != 'get_menu':
                conversation_history = []
            conversation_history.append({"role": "user", "content": user_input})
            last_scenario = function
            conversation_history = menu_scenario(conversation_history)

        elif function == 'place_order':
            if last_scenario != 'place_order':
                conversation_history = []
            conversation_history.append({"role": "user", "content": user_input})
            last_scenario = function
            conversation_history = order_scenario(conversation_history)


        elif function == 'get_order_status':
            if last_scenario != 'get_menu':
                conversation_history = []
            conversation_history.append({"role": "user", "content": user_input})
            last_scenario = function
            conversation_history = order_status_scenario(conversation_history)

        elif function == 'do_nothing':
            pass
            # do_nothing(user_input)

    print()


if __name__ == "__main__":
    chatbot()
