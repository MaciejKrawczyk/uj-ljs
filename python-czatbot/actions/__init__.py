from datetime import datetime


def get_meal_emoji(meal_name):
    meal_emojis = {
        "Pizza": "🍕",
        "Salad": "🥗",
        "Spaghetti": "🍝",
        "Burger": "🍔",
        "Sushi": "🍣",
        "Steak": "🥩",
        "Dessert": "🍰",
        "Soup": "🍜",
    }

    for key, emoji in meal_emojis.items():
        if key.lower() in meal_name.lower():
            return emoji
    return "🍽️"

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