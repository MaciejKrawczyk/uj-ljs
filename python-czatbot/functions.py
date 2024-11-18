

def get_opening_hours():
    with open("opening_hours.json", "r") as f:
        opening_hours = json.load(f)

    print("Godziny otwarcia:\n")
    for day, hours in opening_hours.items():
        if hours["open"] == 0 and hours["close"] == 0:
            print(f"{day}: Zamknięte")
        else:
            print(f"{day}: {hours['open']:02d}:00 - {hours['close']:02d}:00")


def get_menu_str():
    with open("menu.json", "r") as f:
        menu = json.load(f)
        return json.dumps(menu)


def get_opening_hours_str():
    with open("opening_hours.json", "r") as f:
        opening_hours = json.load(f)
        return json.dumps(opening_hours)


def get_menu_dict():
    with open("menu.json", "r") as f:
        menu = json.load(f)
        return menu


def print_menu():
    menu = get_menu_dict()
    for dish in menu:
        print(f"🍔 {dish['id']}." + dish["name"])


def place_order():
    print("Rozpoczęto proces składania zamówienia 🍰, wpisz 'exit', aby zakończyć")
    ordered_dishes = []
    print_menu()
    menu = get_menu_dict()
    dishes_ids = [dish["id"] for dish in menu]

    while True:
        print("Wybierz danie z menu po numerze id:")
        user_input = input("You: ")

        if user_input.lower() == "exit":
            if not ordered_dishes:
                print("Nie złożono zamówienia.")
                return

            print("Podsumowanie zamówienia:")
            total_price = 0
            total_prep_time = 0

            for dish_id in ordered_dishes:
                dish = next((dish for dish in menu if dish['id'] == dish_id), None)
                if dish:
                    print(
                        f"🍔 {dish_id}. {dish['name']} - cena: {dish['price']} zł, czas przygotowania: {dish['preparation_time']} minut")
                    total_price += dish['price']
                    total_prep_time += dish['preparation_time']

            print(f"Całkowity czas przygotowania: {total_prep_time} minut")
            print(f"Łączna wartość zamówienia: {total_price:.2f} zł")

            confirmation = input("Czy zamówienie jest poprawne? (tak/nie): ").strip().lower()
            if confirmation != "tak":
                print("Anulowano zamówienie.")
                return

            delivery_method = input(
                "Czy zamówienie ma być na dowóz kurierem (wpisz 'kurier') czy odbiór w restauracji (wpisz 'restauracja')? ").strip().lower()
            if delivery_method not in ['kurier', 'restauracja']:
                print("Niepoprawny wybór. Zamówienie zapisane jako odbiór w restauracji.")
                delivery_method = "restauracja"

            address = None
            if delivery_method == "kurier":
                address = input("Podaj adres dostawy: ").strip()
                if not address:
                    print("Nie podano adresu. Zamówienie zostało anulowane.")
                    return

            order = Order(ordered_dishes, menu)
            orders.append(order)
            print(f"Twój numer zamówienia to: {order.order_id}")
            print(f"Zamówienie będzie gotowe za {total_prep_time} minut.")
            if delivery_method == "kurier":
                print(f"Zamówienie zostanie dostarczone kurierem na adres: {address}")
            else:
                print("Zamówienie będzie gotowe do odbioru w restauracji.")
            break

        try:
            dish_id = int(user_input)
            if dish_id not in dishes_ids:
                print("Nie posiadamy takiego dania 😢, spróbuj jeszcze raz")
                continue
            ordered_dishes.append(dish_id)
            print("Dodano danie do zamówienia.")
        except ValueError:
            print("Niepoprawny numer id. Spróbuj jeszcze raz.")


def get_order_status():
    if len(orders) == 0:
        print("Nie ma zamówień 😢")
    elif len(orders) == 1:
        order = orders[0]
        print("Masz jedno zamówienie 😊")
        print(f"Numer zamówienia to: {order.order_id}")
        print("Zamówienie zawiera:")
        total_prep_time = 0
        total_price = 0.0
        for dish_id in order.dish_ids:
            dish = next((dish for dish in order.menu if dish['id'] == dish_id), None)
            if dish:
                print(
                    f"🍔 {dish_id}. {dish['name']} - czas przygotowania: {dish['preparation_time']} minut, cena: {dish['price']} zł")
                total_prep_time += dish['preparation_time']
                total_price += dish['price']
        print(f"Szacowany czas przygotowania zamówienia: {total_prep_time} minut")
        print(f"Całkowita wartość zamówienia: {total_price:.2f} zł")
    elif len(orders) > 1:
        print("Masz kilka zamówień 😊")
        for i, order in enumerate(orders):
            print(f"Numer zamówienia {i + 1} to: {order.order_id}")
            print("Zamówienie zawiera:")
            total_prep_time = 0
            total_price = 0.0
            for dish_id in order.dish_ids:
                dish = next((dish for dish in order.menu if dish['id'] == dish_id), None)
                if dish:
                    print(
                        f"🍔 {dish_id}. {dish['name']} - czas przygotowania: {dish['preparation_time']} minut, cena: {dish['price']} zł")
                    total_prep_time += dish['preparation_time']
                    total_price += dish['price']
            print(f"Szacowany czas przygotowania zamówienia: {total_prep_time} minut")
            print(f"Całkowita wartość zamówienia: {total_price:.2f} zł")
            print("-" * 30)


def do_nothing(user_input):
    chatbot_prompt2 = (
        f"Jesteś pomocnym asystentem restauracji. Twoją rolą jest udzielanie informacji o restauracji oraz pomoc w składaniu zamówień. "
        f"Możesz odpowiadać wyłącznie w języku polskim. Oto informacje, do których masz dostęp: \n"
        f"- Godziny otwarcia restauracji: {get_opening_hours_str()} \n"
        f"- Menu restauracji: {get_menu_str()} \n\n"
        f"Nie posiadasz żadnych innych informacji na temat restauracji ani jej usług."
    )

    response = ollama.chat(
        model="llama3.1",
        stream=False,
        messages=[
            {"role": "system", "content": chatbot_prompt2},
            {"role": "user", "content": user_input}
        ],
    )
    print(response['message']['content'])

