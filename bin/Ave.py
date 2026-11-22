#!/usr/bin/env python3
"""
Ave.py — Read the Hail Mary using macOS voices in English, German, and Italian.

Usage:
    Ave.py                              # list languages and speakers, no audio
    Ave.py --voice VOICE --language LANGUAGE [--rate RATE]
    Ave.py --all [--language LANGUAGE] [--voice VOICE] [--rate RATE]
    Ave.py --help
"""

import argparse
import subprocess
import sys

# ── Texts ──────────────────────────────────────────────────────────────────────

TEXTS = {
    "english": (
        "Hail Mary, full of grace, the Lord is with thee.\n"
        "Blessed art thou among women,\n"
        "and blessed is the fruit of thy womb, Jesus.\n"
        "Holy Mary, Mother of God, pray for us sinners,\n"
        "now and at the hour of our death. Amen."
    ),
    "german": (
        "Gegrüßet seist du, Maria, voll der Gnade, der Herr ist mit dir.\n"
        "Du bist gebenedeit unter den Frauen,\n"
        "und gebenedeit ist die Frucht deines Leibes, Jesus.\n"
        "Heilige Maria, Mutter Gottes, bitte für uns Sünder\n"
        "jetzt und in der Stunde unseres Todes. Amen."
    ),
    "italian": (
        "Ave Maria, piena di grazia, il Signore è con te.\n"
        "Tu sei benedetta fra le donne,\n"
        "e benedetto è il frutto del tuo seno, Gesù.\n"
        "Santa Maria, Madre di Dio, prega per noi peccatori,\n"
        "adesso e nell'ora della nostra morte. Amen."
    ),
    "latin": (
        "Ave Maria, gratia plena, Dominus tecum.\n"
        "Benedicta tu in mulieribus,\n"
        "et benedictus fructus ventris tui, Iesus.\n"
        "Sancta Maria, Mater Dei, ora pro nobis peccatoribus,\n"
        "nunc et in hora mortis nostrae. Amen."
    ),
}

# ── Voice roster ───────────────────────────────────────────────────────────────

VOICES = {
    "english": {
        "Eddy":    "Eddy (English (US))",
        "Flo":     "Flo (English (US))",
        "Grandma": "Grandma (English (US))",
        "Grandpa": "Grandpa (English (US))",
        "Reed":    "Reed (English (US))",
        "Rocko":   "Rocko (English (US))",
        "Sandy":   "Sandy (English (US))",
        "Shelley": "Shelley (English (US))",
    },
    "german": {
        "Eddy":    "Eddy (German (Germany))",
        "Flo":     "Flo (German (Germany))",
        "Grandma": "Grandma (German (Germany))",
        "Grandpa": "Grandpa (German (Germany))",
        "Reed":    "Reed (German (Germany))",
        "Rocko":   "Rocko (German (Germany))",
        "Sandy":   "Sandy (German (Germany))",
        "Shelley": "Shelley (German (Germany))",
    },
    "italian": {
        "Eddy":    "Eddy (Italian (Italy))",
        "Flo":     "Flo (Italian (Italy))",
        "Grandma": "Grandma (Italian (Italy))",
        "Grandpa": "Grandpa (Italian (Italy))",
        "Reed":    "Reed (Italian (Italy))",
        "Rocko":   "Rocko (Italian (Italy))",
        "Sandy":   "Sandy (Italian (Italy))",
        "Shelley": "Shelley (Italian (Italy))",
    },
    "latin": {
        # No macOS Latin voice — Italian voices render Church Latin most faithfully
        "Eddy":    "Eddy (Italian (Italy))",
        "Flo":     "Flo (Italian (Italy))",
        "Grandma": "Grandma (Italian (Italy))",
        "Grandpa": "Grandpa (Italian (Italy))",
        "Reed":    "Reed (Italian (Italy))",
        "Rocko":   "Rocko (Italian (Italy))",
        "Sandy":   "Sandy (Italian (Italy))",
        "Shelley": "Shelley (Italian (Italy))",
    },
}

VOICE_NAMES    = list(next(iter(VOICES.values())).keys())  # same for all languages
LANGUAGE_NAMES = list(TEXTS.keys())
DEFAULT_RATE   = 100

# ── Language aliases ───────────────────────────────────────────────────────────
# Maps any accepted spelling/language name → canonical key
# Latin redirects to italian with an explanation printed at speak time.

LANGUAGE_ALIASES: dict[str, str] = {
    # English
    "english":  "english",
    "englisch": "english",   # German spelling
    "inglese":  "english",   # Italian spelling
    # German
    "german":   "german",
    "deutsch":  "german",
    "tedesco":  "german",    # Italian spelling
    # Italian / Latin
    "italian":  "italian",
    "italiano": "italian",
    "latin":    "latin",     # handled specially — redirects to italian
    "lateinisch": "latin",   # German spelling
    "latino":   "latin",     # Italian/Spanish spelling
    "latina":   "latin",     # Classical Latin — lingua Latina
    "lingua latina": "latin", # Full classical name — requires quotes on CLI
    "linqua latina": "latin", # Common misspelling — accepted graciously
}

LATIN_NOTE = (
    "  ℹ️   Latin requested: no dedicated Latin voice is available on macOS.\n"
    "      Using Italian voices, which render Church Latin most faithfully.\n"
)

# ── Listing ────────────────────────────────────────────────────────────────────

def list_info() -> None:
    """Print available languages and speakers; no audio."""
    print("\nAve Maria — available languages and speakers\n")
    print(f"  Languages : {', '.join(LANGUAGE_NAMES)}")
    print(f"  Voices    : {', '.join(VOICE_NAMES)}")
    print()
    print("  Run  Ave.py --help  for full usage and examples.")
    print()

# ── Core function ──────────────────────────────────────────────────────────────

def speak(voice_name: str, language: str, rate: int) -> None:
    # Latin has its own text now; note that Italian voices are used
    if language == "latin":
        print(LATIN_NOTE)

    voice_str = VOICES[language][voice_name]
    text      = TEXTS[language]

    # Header
    print(f"\n{'─' * 60}")
    print(f"  🎙  {voice_name}  ·  {language.capitalize()}  ·  rate {rate}")
    print(f"{'─' * 60}")

    # Print the full prayer text
    for line in text.splitlines():
        print(f"  {line}")
    print()

    # Speak — pass the plain text (newlines replaced with spaces for say)
    subprocess.run(
        ["say", "-v", voice_str, "-r", str(rate), text.replace("\n", " ")],
        check=True,
    )

# ── CLI ────────────────────────────────────────────────────────────────────────

def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="Ave.py",
        description=(
            "\"Hail, thou that art highly favoured, the Lord is with thee.\"\n"
            "                                          — Luke 1:28\n\n"
            "Ave Maria — hear the Hail Mary spoken by macOS voices\n"
            "in English, German, and Italian (Latin text).\n\n"
            "Run Ave.py with no arguments to list languages and speakers.\n\n"
            "The Italian voices render Church Latin more faithfully\n"
            "than German or English voices."
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=(
            "Examples:\n"
            "  Ave.py                              # list languages and speakers\n"
            "  Ave.py --voice Grandma --language italian\n"
            "  Ave.py --voice Rocko   --language german\n"
            "  Ave.py --language english --rate 80\n"
            "  Ave.py --all                        # all 32 voice/language combos\n"
            "  Ave.py --all --language italian     # all 8 Italian voices\n"
            "  Ave.py --all --language latin       # all 8 Latin voices\n"
            "  Ave.py --all --voice Grandma        # Grandma in all 4 languages\n\n"
            f"Voices    : {', '.join(VOICE_NAMES)}\n"
            f"Languages : english/englisch/inglese, german/deutsch/tedesco,\n"
            f"            italian/italiano, latin/latina/lateinisch/latino,\n"
            f"            \"lingua latina\" (quotes required)\n"
        ),
    )
    parser.add_argument(
        "--voice", "-v",
        choices=VOICE_NAMES,
        default=None,
        type=lambda s: s.capitalize(),
        help=f"Voice to use. Choices: {', '.join(VOICE_NAMES)}",
    )
    parser.add_argument(
        "--language", "-l",
        default=None,
        type=lambda s: LANGUAGE_ALIASES.get(s.lower(), None),
        help=(
            "Language to use. Accepts English/Englisch/Inglese, "
            "German/Deutsch/Tedesco, Italian/Italiano, "
            "Latin/Latina/Lateinisch/Latino/\"Lingua Latina\" (uses Italian voices)."
        ),
    )
    parser.add_argument(
        "--rate", "-r",
        type=int,
        default=DEFAULT_RATE,
        metavar="WPM",
        help=f"Speech rate in words per minute (default: {DEFAULT_RATE}). "
             "Try 80 for a meditative pace, 60 for near-chant.",
    )
    parser.add_argument(
        "--all", "-a",
        action="store_true",
        help="Speak with every voice. Combine with --language or --voice to filter.",
    )
    return parser


def main() -> None:
    parser = build_parser()
    args   = parser.parse_args()

    # No arguments at all → show full --help and exit
    if len(sys.argv) == 1:
        parser.print_help()
        print()
        return

    # Manual language validation — catches unrecognised values cleanly
    if args.language is None and "--language" in sys.argv or "-l" in sys.argv:
        # language was supplied but not recognised
        raw = sys.argv[sys.argv.index("--language") + 1] if "--language" in sys.argv else sys.argv[sys.argv.index("-l") + 1]
        print(f"\n  ❌  Unrecognised language: '{raw}'")
        print(f"      Valid choices: {', '.join(LANGUAGE_ALIASES.keys())}")
        print(f"      Note: 'lingua latina' and 'linqua latina' require quotes.\n")
        sys.exit(1)

    if args.all:
        voices    = [args.voice]    if args.voice    else VOICE_NAMES
        languages = [args.language] if args.language else LANGUAGE_NAMES
        languages = list(dict.fromkeys(languages))  # deduplicate

        total = len(voices) * len(languages)
        print(f"\nAve Maria — {total} voice{'s' if total != 1 else ''} will speak the prayer.")

        for lang in languages:
            for voice in voices:
                speak(voice, lang, args.rate)

    else:
        # Defaults when called with partial args
        voice    = args.voice    or "Grandma"
        language = args.language or "italian"
        speak(voice, language, args.rate)

    print(f"\n{'─' * 60}")
    print("  Amen.")
    print(f"{'─' * 60}\n")


if __name__ == "__main__":
    main()
