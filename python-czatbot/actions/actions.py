import json
from datetime import datetime
from typing import Any, Text, Dict, List

from rasa_sdk import Action, Tracker
from rasa_sdk.executor import CollectingDispatcher


def check_time(time_to_check, AMPM, opening_hours, closing_hours):
    if AMPM is not None:
        if ':' in time_to_check:
            time_format = '%I:%M %p'
        else:
            time_format = '%I %p'
        try:
            time_to_check = datetime.strptime(time_to_check + ' ' + AMPM, time_format).strftime('%H:%M')
        except ValueError:
            return False

    opening_hours = datetime.strptime(str(opening_hours), '%H').time()
    closing_hours = datetime.strptime(str(closing_hours), '%H').time()

    try:
        time_to_check = datetime.strptime(time_to_check, '%H:%M').time()
    except ValueError:
        return False

    if opening_hours <= time_to_check <= closing_hours:
        return True
    else:
        return False


class ActionHelloWorld(Action):

    def name(self) -> Text:
        return "action_hello_world"

    def run(self, dispatcher: CollectingDispatcher,
            tracker: Tracker,
            domain: Dict[Text, Any]) -> List[Dict[Text, Any]]:
        dispatcher.utter_message(text="Hello World!")

        return []


class ActionProvideOpeningHoursOnDay(Action):

    def name(self) -> Text:
        return "action_provide_opening_hours_on_day"

    def run(self, dispatcher: CollectingDispatcher,
            tracker: Tracker,
            domain: Dict[Text, Any]) -> List[Dict[Text, Any]]:

        # Load opening hours data
        try:
            with open("data/opening_hours.json", 'r') as opening_hours_file:
                opening_hours_data = json.load(opening_hours_file)
        except FileNotFoundError:
            dispatcher.utter_message(text="I'm sorry, I couldn't find our opening hours information.")
            return []
        except json.JSONDecodeError:
            dispatcher.utter_message(text="There seems to be an issue with our opening hours data format.")
            return []

        data = opening_hours_data.get("items", {})

        # Extract the day entity
        day = next(tracker.get_latest_entity_values("day"), None)

        if day:
            day_lower = day.lower()
            if day_lower in data:
                day_hours = data[day_lower]
                open_time = day_hours.get('open')
                close_time = day_hours.get('close')

                if open_time and close_time:
                    # Convert 24-hour format to 12-hour format with AM/PM
                    try:
                        open_time_formatted = datetime.strptime(open_time, '%H:%M').strftime('%I:%M %p')
                        close_time_formatted = datetime.strptime(close_time, '%H:%M').strftime('%I:%M %p')
                        response = f"We are open on {day.capitalize()} from {open_time_formatted} to {close_time_formatted}."
                    except ValueError:
                        # If time format is incorrect, return raw times
                        response = f"We are open on {day.capitalize()} from {open_time} to {close_time}."
                else:
                    response = f"We are closed on {day.capitalize()}."
            else:
                response = f"I'm sorry, I don't have information for {day.capitalize()}. Please specify a valid day of the week."
        else:
            response = "Please specify the day you're interested in. For example, 'Monday'."

        dispatcher.utter_message(text=response)

        return []


class ActionShowOpenHours(Action):

    def name(self) -> Text:
        return "show_open_hours"

    def run(self, dispatcher: CollectingDispatcher,
            tracker: Tracker,
            domain: Dict[Text, Any]) -> List[Dict[Text, Any]]:
        with open("data\\opening_hours.json", 'r') as opening_hours_file:
            opening_hours_data = json.load(opening_hours_file)

        data = opening_hours_data.get("items")

        response = "Here are our current operating hours:\n\n"
        for day, hour in data.items():
            response += f"{day} from {hour['open']} till {hour['close']}\n"

        dispatcher.utter_message(text=response)

        return []


class ActionShowOpeningHoursOnParticularDay(Action):
    def name(self) -> Text:
        return "show_opening_hours_on_particular_day"

    def run(self, dispatcher: CollectingDispatcher,
            tracker: Tracker,
            domain: Dict[Text, Any]) -> List[Dict[Text, Any]]:

        with open("data\\opening_hours.json", 'r') as opening_hours_file:
            opening_hours_data = json.load(opening_hours_file)

        data = opening_hours_data.get("items")

        day = next(tracker.get_latest_entity_values("day"), None)
        hour = next(tracker.get_latest_entity_values("hour"), None)
        time_ampm = next(tracker.get_latest_entity_values("time"), None)

        if day is not None and day in data:
            if hour is None and time_ampm is None:
                dispatcher.utter_message(text="Please provide the time you're interested in (e.g., 3 PM).")
                return []
            elif hour is None or time_ampm is None:
                dispatcher.utter_message(text="Please provide both the hour and AM/PM (e.g., 3 PM).")
                return []

            is_open = check_time(hour, time_ampm, data[day]['open'], data[day]['close'])
            if is_open:
                dispatcher.utter_message(text="We are open at this time.")
            else:
                dispatcher.utter_message(text="We are closed at this time.")
        else:
            dispatcher.utter_message(text="I didn't understand your day. Please specify a valid day of the week.")

        return []

class ActionListMenu(Action):
    def name(self) -> Text:
        return "action_list_menu"

    def run(self, dispatcher: CollectingDispatcher,
            tracker: Tracker,
            domain: Dict[Text, Any]) -> List[Dict[Text, Any]]:

        try:
            with open("data\\menu.json", 'r') as menu_file:
                menu_data = json.load(menu_file)
        except FileNotFoundError:
            dispatcher.utter_message(text="🚫 Sorry, the menu is currently unavailable.")
            return []
        except json.JSONDecodeError:
            dispatcher.utter_message(text="⚠️ Sorry, there was an error reading the menu.")
            return []

        if not menu_data:
            dispatcher.utter_message(text="📭 The menu is empty at the moment.")
            return []

        # Start constructing the response with a header and emojis
        response = "**🍽️ Here is our Menu:**\n\n"

        # Using a Bullet List with Emojis
        for meal in menu_data:
            name = meal.get('name', 'N/A')
            price = meal.get('price', 'N/A')
            prep_time = meal.get('preparation_time', 'N/A')

            # Add specific emojis based on meal type
            meal_emoji = self.get_meal_emoji(name)

            response += f"🍽️ **{meal_emoji} {name}**\n  - 💲 Price: ${price}\n  - ⏰ Preparation Time: {prep_time} hrs\n\n"

        dispatcher.utter_message(text=response)

        return []

    def get_meal_emoji(self, meal_name: Text) -> Text:
        """
        Returns an appropriate emoji based on the meal name.
        You can expand this function to include more meal types and emojis.
        """
        meal_emojis = {
            "Pizza": "🍕",
            "Salad": "🥗",
            "Spaghetti": "🍝",
            "Burger": "🍔",
            "Sushi": "🍣",
            "Steak": "🥩",
            "Dessert": "🍰",
            "Soup": "🍜",
            # Add more mappings as needed
        }

        for key, emoji in meal_emojis.items():
            if key.lower() in meal_name.lower():
                return emoji
        return "🍽️"  # Default emoji


class ActionOrderFood(Action):
    def name(self) -> Text:
        return "action_order_food"

    async def run(self, dispatcher: CollectingDispatcher,
                  tracker: Tracker,
                  domain: Dict[Text, Any]) -> List[Dict[Text, Any]]:

        with open("data\\menu.json", 'r') as menu_file:
            menu_file_data = json.load(menu_file)

        ordered_meal = next(tracker.get_latest_entity_values("food"), None)
        amount = next(tracker.get_latest_entity_values("amount"), None)
        additional_request = next(tracker.get_latest_entity_values("additional_request"), None)
        data = menu_file_data.get('items', [])

        for meal in data:
            if meal.get('name').lower() == ordered_meal.lower():
                response = "I confirm your order for " + (str(amount) + " " if amount is not None else "") + meal.get(
                    'name').lower() + (" " + str(additional_request) if additional_request is not None else "")
                preparation_time = meal.get('preparation_time')
                response += ". We need approximately " + str(
                    preparation_time) + " hours to prepare a meal for you. I'll notify you when the order will be ready!"
                dispatcher.utter_message(text=response)

                return []

        dispatcher.utter_message(text="We will try to prepare this meal for you in 1 hour. I'll notify you when the "
                                      "order will be ready!")

        return []
