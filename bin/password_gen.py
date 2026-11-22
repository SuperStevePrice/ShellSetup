#!/usr/bin/env python3
"""
Multilingual Password Generator
Generates passwords using words from German, French, Spanish, English, Swedish, and Yiddish,
separated by special/non-printable-looking characters, ending with a datetime stamp.
"""

import random
import string
from datetime import datetime

# ── Word lists by language ────────────────────────────────────────────────────

WORDS = {
    "German":   [
        "Wald", "Stern", "Brücke", "Feuer", "Wasser", "Himmel", "Stein",
        "Blatt", "Schatten", "Kraft", "Traum", "Nebel", "Donner", "Blitz",
        "Fluss", "Berg", "Wolke", "Licht", "Dunkel", "Wind",
    ],
    "French":   [
        "Lumiere", "Foret", "Pierre", "Nuage", "Riviere", "Etoile", "Flamme",
        "Ombre", "Montagne", "Vent", "Pluie", "Foudre", "Reve", "Brume",
        "Soleil", "Lune", "Terre", "Mer", "Ciel", "Feu",
    ],
    "Spanish":  [
        "Bosque", "Piedra", "Nube", "Rio", "Estrella", "Llama", "Sombra",
        "Montana", "Viento", "Lluvia", "Rayo", "Sueno", "Niebla", "Sol",
        "Luna", "Tierra", "Mar", "Cielo", "Fuego", "Luz",
    ],
    "English":  [
        "Forest", "Stone", "Cloud", "River", "Star", "Flame", "Shadow",
        "Mountain", "Wind", "Rain", "Thunder", "Dream", "Mist", "Sun",
        "Moon", "Earth", "Sea", "Sky", "Fire", "Light",
    ],
    "Swedish":  [
        "Skog", "Sten", "Moln", "Flod", "Stjarna", "Flamma", "Skugga",
        "Berg", "Vind", "Regn", "Aska", "Drom", "Dimma", "Sol",
        "Mane", "Jord", "Hav", "Himmel", "Eld", "Ljus",
    ],
    "Yiddish":  [
        "Vald", "Shtern", "Fayer", "Vaser", "Himl", "Shteyn", "Blat",
        "Shotn", "Kraft", "Troym", "Nepl", "Doner", "Blits", "Taykh",
        "Berg", "Volkn", "Likht", "Finsternish", "Vint", "Zun",
    ],
}

LANGUAGES = list(WORDS.keys())

# ── Separators: characters broadly accepted by online password validators ─────
# Drawn from OWASP's recommended "safe" special character set:
#   ! # $ % & * + - . = ? @ ^ _ ~ ( ) [ ] { }
# Excluded: " ' ` / \ | : ; , < > space — these are rejected by many sites.
SEPARATORS = [
    "!", "#", "$", "%", "&", "*", "+", "-", ".", "=",
    "?", "@", "^", "_", "~", "(", ")", "[", "]", "{", "}",
]


def random_separator():
    return random.choice(SEPARATORS)


def random_word():
    lang = random.choice(LANGUAGES)
    word = random.choice(WORDS[lang])
    return word


def datetime_stamp():
    """Return compact datetime string: YYYYMMDD-HHMMSS"""
    return datetime.now().strftime("%Y%m%d-%H%M%S")


def generate_password(min_len: int = 8, max_len: int = 56) -> str:
    stamp = datetime_stamp()
    # Reserve room for stamp + at least one separator before it
    budget = random.randint(min_len, max_len) - len(stamp) - 1

    parts = []
    current_len = 0

    while True:
        sep = random_separator()
        word = random_word()
        chunk = sep + word
        if current_len + len(chunk) > budget:
            break
        parts.append(chunk)
        current_len += len(chunk)

    # If nothing fit at all, force one short word (truncated to budget)
    if not parts:
        word = random_word()[:max(1, budget - 1)]
        parts.append(random_separator() + word)

    # Append datetime stamp with a separator
    parts.append(random_separator() + stamp)

    password = "".join(parts).lstrip(random_separator())  # clean leading sep
    # Strip any accidental leading separator for readability
    for sep in SEPARATORS:
        if password.startswith(sep):
            password = password[len(sep):]
            break

    return password


def main():
    print("=" * 62)
    print("  Multilingual Password Generator")
    print("  Languages: German · French · Spanish · English · Swedish · Yiddish")
    print("=" * 62)
    print()

    for i in range(10):
        pw = generate_password()
        print(f"  [{i+1:02d}]  {pw}")
        print(f"        length = {len(pw)}")
        print()

    print("=" * 62)
    print("  Copy any password above. Each run produces unique results.")
    print("=" * 62)


if __name__ == "__main__":
    main()
