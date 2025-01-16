import json
from datetime import datetime
from typing import Any, Text, Dict, List

from rasa_sdk import Action, Tracker
from rasa_sdk.executor import CollectingDispatcher

from actions import get_meal_emoji


class ActionProvideOpeningHoursOnDay(Action):

    def name(self) -> Text:
        return "action_provide_opening_hours_on_day"

    def run(self, dispatcher: CollectingDispatcher,
            tracker: Tracker,
            domain: Dict[Text, Any]) -> List[Dict[Text, Any]]:

        try:
            with open("data/opening_hours.json", 'r') as opening_hours_file:
                opening_hours_data = json.load(opening_hours_file)
        except FileNotFoundError:
            dispatcher.utter_message(text="🚫 I'm sorry, I couldn't find our opening hours information.")
            return []
        except json.JSONDecodeError:
            dispatcher.utter_message(text="⚠️ There seems to be an issue with our opening hours data format.")
            return []

        data = opening_hours_data.get("items", {})

        # Extract the day entity
        day = next(tracker.get_latest_entity_values("day"), None)

        if day:
            day_key = day.capitalize()
            if day_key in data:
                day_hours = data[day_key]
                open_time = day_hours.get('open')
                close_time = day_hours.get('close')

                if open_time and close_time:
                    try:
                        # Convert integer times to 'HH:MM' format
                        open_time_str = f"{int(open_time):02d}:00"
                        close_time_str = f"{int(close_time):02d}:00"
                        response = f"🕒 We are open on **{day_key}** from **{open_time_str}** to **{close_time_str}**."
                    except (ValueError, TypeError):
                        # If conversion fails, return raw times
                        response = f"🕒 We are open on **{day_key}** from **{open_time}** to **{close_time}**."
                else:
                    response = f"🚪 We are **closed** on **{day_key}**."
            else:
                response = f"❓ I'm sorry, I don't have information for **{day_key}**. Please specify a valid day of the week."
        else:
            response = "📅 Please specify the day you're interested in. For example, 'Monday'."

        dispatcher.utter_message(text=response)

        return []


class ActionShowOpenHours(Action):

    def name(self) -> Text:
        return "show_open_hours"

    def run(self, dispatcher: CollectingDispatcher,
            tracker: Tracker,
            domain: Dict[Text, Any]) -> List[Dict[Text, Any]]:
        try:
            with open("data/opening_hours.json", 'r') as opening_hours_file:
                opening_hours_data = json.load(opening_hours_file)
        except FileNotFoundError:
            dispatcher.utter_message(text="🚫 Sorry, the opening hours information is currently unavailable.")
            return []
        except json.JSONDecodeError:
            dispatcher.utter_message(text="⚠️ Sorry, there was an error reading the opening hours data.")
            return []

        data = opening_hours_data.get("items", {})

        if not data:
            dispatcher.utter_message(text="📭 The opening hours information is empty at the moment.")
            return []

        response = "**🕒 Here are our Current Operating Hours:**\n\n"
        for day, hour in data.items():
            response += f"• **{day.capitalize()}**: {hour['open']} - {hour['close']}\n"

        dispatcher.utter_message(text=response)

        return []


class ActionShowOpeningHoursOnParticularDay(Action):
    def name(self) -> Text:
        return "show_opening_hours_on_particular_day"

    def run(self, dispatcher: CollectingDispatcher,
            tracker: Tracker,
            domain: Dict[Text, Any]) -> List[Dict[Text, Any]]:

        try:
            with open("data/opening_hours.json", 'r') as opening_hours_file:
                opening_hours_data = json.load(opening_hours_file)
        except FileNotFoundError:
            dispatcher.utter_message(text="🚫 Sorry, I couldn't access our opening hours information.")
            return []
        except json.JSONDecodeError:
            dispatcher.utter_message(text="⚠️ There's an issue with our opening hours data format.")
            return []

        data = opening_hours_data.get("items", {})

        day = next(tracker.get_latest_entity_values("day"), None)
        time_str = next(tracker.get_latest_entity_values("time"), None)  # Expecting 'HH:MM' format

        if day:
            day_lower = day.lower()
            if day_lower in data:
                if not time_str:
                    dispatcher.utter_message(text="🕒 Please provide the time you're interested in (e.g., '15:00').")
                    return []
                else:
                    try:
                        # Validate time format
                        requested_time = datetime.strptime(time_str, '%H:%M').time()
                        open_time = datetime.strptime(data[day_lower]['open'], '%H:%M').time()
                        close_time = datetime.strptime(data[day_lower]['close'], '%H:%M').time()
                    except ValueError:
                        dispatcher.utter_message(text="⚠️ Please provide the time in 24-hour format (e.g., '15:00').")
                        return []

                    if open_time <= requested_time <= close_time:
                        dispatcher.utter_message(text="✅ We are **open** at this time! 🎉")
                    else:
                        dispatcher.utter_message(text="❌ We are **closed** at this time. 🕒")
            else:
                dispatcher.utter_message(text="❓ I didn't recognize that day. Please specify a valid day of the week.")
        else:
            dispatcher.utter_message(text="📅 Please specify the day you're interested in. For example, 'Monday'.")

        return []


class ActionListMenu(Action):
    def name(self) -> Text:
        return "action_list_menu"

    def run(self, dispatcher: CollectingDispatcher,
            tracker: Tracker,
            domain: Dict[Text, Any]) -> List[Dict[Text, Any]]:

        try:
            with open("data/menu.json", 'r') as menu_file:
                menu_data = json.load(menu_file)
        except FileNotFoundError:
            dispatcher.utter_message(text="🚫 Sorry, the menu is currently unavailable.")
            return []
        except json.JSONDecodeError:
            dispatcher.utter_message(text="⚠️ Sorry, there was an error reading the menu.")
            return []

        items = menu_data

        if not items:
            dispatcher.utter_message(text="📭 The menu is empty at the moment.")
            return []

        # Start constructing the response with a header and emojis
        response = "**🍽️ Here's Our Delicious Menu:**\n\n"

        # Using a Bullet List with Emojis
        for meal in items:
            name = meal.get('name', 'N/A')
            price = meal.get('price', 'N/A')
            prep_time = meal.get('preparation_time', 'N/A')

            # Add specific emojis based on meal type
            meal_emoji = get_meal_emoji(name)

            response += f"• **{meal_emoji} {name}**\n  - 💲 **Price**: ${price}\n  - ⏰ **Preparation Time**: {prep_time} hrs\n\n"

        dispatcher.utter_message(text=response)

        return []


class ActionOrderFood(Action):
    def name(self) -> Text:
        return "action_order_food"

    async def run(self, dispatcher: CollectingDispatcher,
                  tracker: Tracker,
                  domain: Dict[Text, Any]) -> List[Dict[Text, Any]]:

        try:
            with open("data/menu.json", 'r') as menu_file:
                menu_file_data = json.load(menu_file)
        except FileNotFoundError:
            dispatcher.utter_message(text="🚫 Sorry, we couldn't access the menu to process your order.")
            return []
        except json.JSONDecodeError:
            dispatcher.utter_message(text="⚠️ There was an error reading the menu. Please try again later.")
            return []

        ordered_meal = next(tracker.get_latest_entity_values("food"), None)
        amount = next(tracker.get_latest_entity_values("amount"), None)
        additional_request = next(tracker.get_latest_entity_values("additional_request"), None)
        data = menu_file_data

        if not ordered_meal:
            dispatcher.utter_message(text="❓ What would you like to order? Please specify a meal from the menu.")
            return []

        for meal in data:
            if meal.get('name').lower() == ordered_meal.lower():
                meal_name = meal.get('name')
                preparation_time = meal.get('preparation_time', 1)  # Default to 1 hour if not specified
                amount_str = f"{amount} " if amount else ""
                additional_str = f" with {additional_request}" if additional_request else ""

                response = (
                    f"🎉 I’ve got your order! You ordered **{amount_str}{meal_name}{additional_str}**.\n"
                    f"⏳ We'll need approximately **{preparation_time} hour(s)** to prepare your meal.\n"
                    "📢 I'll notify you when your order is ready! 🍽️"
                )
                dispatcher.utter_message(text=response)

                return []

        # If the meal is not found in the menu
        dispatcher.utter_message(text="😕 We couldn't find that meal on our menu. Please check the menu and try again.")
        return []
