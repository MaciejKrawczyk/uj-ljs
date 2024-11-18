import json
from random import randint

import ollama

from functions import do_nothing, get_order_status, place_order, print_menu, get_opening_hours

orders = []


class Config:
    def __init__(self, output_format="json", model="llama3.1"):
        self.format = output_format
        self.model = model


class Chat:
    def __init__(self, system_prompt: str, config: Config):
        self.system_prompt = system_prompt
        self.config = config

    def get_json_response(self, user_prompt: str):
        response = ollama.chat(
            model=self.config.model,
            stream=False,
            messages=[
                {"role": "system", "content": self.system_prompt},
                {"role": "user", "content": user_prompt}
            ],
            format=self.config.format,
        )
        json_output = json.loads(response['message']['content'])
        return json_output

    def get_response(self, user_prompt: str):
        response = ollama.chat(
            model=self.config.model,
            stream=False,
            messages=[
                {"role": "system", "content": self.system_prompt},
                {"role": "user", "content": user_prompt}
            ],
        )
        output = json.loads(response['message']['content'])
        return output


class OpeningHourChat:
    def __init__(self, system_prompt: str):
        self.system_prompt = system_prompt


class PlaceOrderChat:
    def __init__(self, system_prompt: str):
        self.system_prompt = system_prompt


class GetMenuChat:
    def __init__(self, system_prompt: str):
        self.system_prompt = system_prompt


class GetOrderStatusChat:
    def __init__(self, system_prompt: str):
        self.system_prompt = system_prompt


class NormalConversationChat:
    def __init__(self, system_prompt: str):
        self.system_prompt = system_prompt


def get_chatbot(user_prompt: str):
    pass


def determine_function_to_call(user_input: str):
    pass


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


CHATBOT_SYSTEM_PROMPT = """
Jesteś pomocnym asystentem restauracji. Udzielasz informacji o restauracji, pomagasz w składaniu zamówień oraz odpowiadasz na powiązane pytania.

Twoje odpowiedzi muszą mieć następujący format JSON: 
{ "function": "<funkcja do wywołania>" }

### Funkcje do wywołania:
- **get_opening_hours**: Zwraca godziny otwarcia restauracji.
- **get_menu**: Zwraca menu restauracji.
- **place_order**: Rozpoczyna proces składania zamówienia w restauracji.
- **get_order_status**: Zwraca status zamówienia. Może być konieczne poproszenie użytkownika o numer zamówienia lub inne szczegóły identyfikacyjne.
- **do_nothing**: Używaj tej funkcji, gdy żadne z powyższych nie pasuje. W takim przypadku stwórz pomocną odpowiedź dla użytkownika w języku naturalnym PO POLSKU!.

### Wytyczne:
1. **Pytania uzupełniające**: 
   - Jeśli zapytanie użytkownika jest niejasne lub niekompletne, zadawaj pytania uzupełniające, aby zebrać potrzebne informacje przed wywołaniem funkcji.
   - Przykład: Jeśli użytkownik pyta „O której otwieracie?”, ale nie wskazuje dnia, zapytaj: „O który dzień tygodnia chodzi?”

2. **Status zamówienia**: 
   - Jeśli użytkownik pyta o status zamówienia, upewnij się, że posiadasz numer zamówienia lub inne wystarczające dane identyfikacyjne przed wykonaniem funkcji.

3. **Obsługa zapytań nietypowych**:
   - Używaj `do_nothing`, gdy pytanie użytkownika nie dotyczy bezpośrednio wymienionych funkcji. W takich przypadkach podaj uprzejmą i zrozumiałą odpowiedź w języku naturalnym.

4. **Obsługa błędów**:
   - Jeśli wykonanie funkcji nie jest możliwe (np. brak danych lub nieobsługiwane zapytanie), odpowiedz w sposób naturalny, wskazując użytkownikowi dalsze kroki.

5. **Ton i język**:
   - Zawsze utrzymuj uprzejmy, pomocny i profesjonalny ton.

Upewnij się, że odpowiedź w formacie JSON bezpośrednio odzwierciedla funkcję do wywołania i uzupełnia wszelkie potrzebne komunikaty wyjaśniające w trakcie interakcji.
"""


def chatbot():
    print("Witaj w restauracji Daniowo 🍽, jestem asystentem Pomidorówka 🧑‍🤝‍🧑. W czym mogę pomoć?")
    while True:
        user_input = input("Ty: ")

        if user_input.lower() == 'exit':
            print("Goodbye!")
            break

        print("Pomidorówka: ")

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

        if function == 'get_opening_hours':
            get_opening_hours()

        elif function == 'get_menu':
            print_menu()

        elif function == 'place_order':
            place_order()

        elif function == 'get_order_status':
            get_order_status()

        elif function == 'do_nothing':
            do_nothing(user_input)

    print()


if __name__ == "__main__":
    chatbot()
