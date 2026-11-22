#!/usr/bin/env python3
"""
pray.py — Pray in many languages, in many voices, on macOS and Linux.

Usage:
    pray.py                                      # show help
    pray.py --list                               # list prayers, languages, voices
    pray.py --prayer PRAYER --language LANGUAGE [--voice VOICE] [--rate RATE]
    pray.py --all [--prayer PRAYER] [--language LANGUAGE] [--voice VOICE]
    pray.py --help

On macOS: uses system 'say' command with specified voices (Eddy, Flo, Grandma, etc.)
On Linux: uses espeak-ng (install with: sudo apt install espeak-ng)
"""

import argparse
import platform
import subprocess
import sys
from pathlib import Path
from typing import Optional

# ── Prayer registry ────────────────────────────────────────────────────────────
# prayers/ must be in the same directory as pray.py

sys.path.insert(0, str(Path(__file__).parent))
from prayers import PRAYERS, PRAYER_ALIASES
from prayers.base import Prayer

DEFAULT_RATE   = 100
DEFAULT_PRAYER = "ave"

# ── Helpers ────────────────────────────────────────────────────────────────────

def resolve_prayer(raw: str) -> Optional[Prayer]:
    key = PRAYER_ALIASES.get(raw.lower().strip(), None)
    return PRAYERS.get(key) if key else None


def list_all() -> None:
    print("\nPray — available prayers, languages, and voices\n")
    for key, prayer in PRAYERS.items():
        langs  = ", ".join(prayer.language_names())
        voices = ", ".join(prayer.voice_names())
        print(f"  Prayer    : {prayer.title}  (--prayer {key})")
        print(f"  Languages : {langs}")
        print(f"  Voices    : {voices}")
        print()
    print("  Run  pray.py --help  for full usage and examples.")
    print()


def speak(prayer: Prayer, voice_name: str, language: str, rate: int) -> None:
    if language == "latin" and prayer.latin_note:
        print(prayer.latin_note)

    voice_str = prayer.voices[language][voice_name]
    text      = prayer.texts[language]
    title     = prayer.native_titles.get(language, prayer.title)

    print(f"\n{'─' * 60}")
    print(f"  🙏  {prayer.title}  ·  {title}")
    print(f"  🎙  {voice_name}  ·  {language.capitalize()}  ·  rate {rate}")
    print(f"{'─' * 60}")

    for line in text.splitlines():
        print(f"  {line}")
    print()

    # Detect OS and use appropriate TTS
    system = platform.system()
    
    if system == "Darwin":
        # macOS: use 'say' command
        subprocess.run(
            ["say", "-v", voice_str, "-r", str(rate), text.replace("\n", " ")],
            check=True,
        )
    elif system == "Linux":
        # Linux: use espeak-ng
        # Map language names to espeak-ng language codes
        lang_map = {
            "english": "en",
            "deutsch": "de",
            "german": "de",
            "italian": "it",
            "latin": "la",
            "french": "fr",
            "spanish": "es",
            "portuguese": "pt",
            "polish": "pl",
        }
        lang_lower = language.lower()
        lang_code = lang_map.get(lang_lower, lang_lower[:2].lower())
        
        subprocess.run(
            ["espeak-ng", "-v", lang_code, "-s", str(rate), text.replace("\n", " ")],
            check=True,
        )
    else:
        print(f"  ❌  Unsupported operating system: {system}")
        sys.exit(1)

# ── CLI ────────────────────────────────────────────────────────────────────────

def build_parser() -> argparse.ArgumentParser:
    prayer_keys  = list(PRAYERS.keys())
    prayer_aliases = list(PRAYER_ALIASES.keys())

    parser = argparse.ArgumentParser(
        prog="pray.py",
        description=(
            '"The wind bloweth where it listeth, and thou hearest the sound\n'
            ' thereof, but canst not tell whence it cometh, and whither it\n'
            ' goeth: so is every one that is born of the Spirit."\n'
            "                                          — John 3:8\n\n"
            "Pray — hear sacred prayers spoken by macOS voices\n"
            "in many languages.\n\n"
            "Run pray.py with no arguments to show this help."
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=(
            "Examples:\n"
            "  pray.py --list\n"
            "  pray.py --prayer ave --language italian\n"
            "  pray.py --prayer lords --language german --voice Grandma\n"
            "  pray.py --prayer ave --language latin --rate 80\n"
            "  pray.py --all                          # all voices, all languages, all prayers\n"
            "  pray.py --all --prayer ave             # all Ave Maria combos\n"
            "  pray.py --all --language french        # all prayers in French\n"
            "  pray.py --all --voice Grandma          # Grandma prays everything\n\n"
            f"Prayers   : {', '.join(prayer_keys)}\n"
            f"            Aliases: ave maria, hail mary, lords prayer, our father,\n"
            f"            paternoster, vaterunser, padre nostro, notre père\n\n"
            f"Languages : english/deutsch/italiano/latin/french/spanish/portuguese/polish\n"
            f"            (and native spellings — see --list)\n\n"
            f"Voices    : Eddy, Flo, Grandma, Grandpa, Reed, Rocko, Sandy, Shelley\n"
            f"            (Zosia for Polish)\n"
        ),
    )
    parser.add_argument(
        "--prayer", "-p",
        default=None,
        type=lambda s: PRAYER_ALIASES.get(s.lower().strip(), None),
        help=f"Prayer to recite. Choices: {', '.join(prayer_keys)}. "
             "Also accepts natural names: 'ave maria', 'our father', 'paternoster', etc.",
    )
    parser.add_argument(
        "--voice", "-v",
        default=None,
        type=lambda s: s.capitalize(),
        help="Voice to use (default: Grandma). See --list for available voices.",
    )
    parser.add_argument(
        "--language", "-l",
        default=None,
        type=lambda s: s.lower().strip(),
        help="Language to use (default: italian for ave, english for lords). "
             "Accepts native spellings: deutsch, italiano, français, español, etc.",
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
        help="Iterate all combinations. Filter with --prayer, --language, or --voice.",
    )
    parser.add_argument(
        "--list", "-L",
        action="store_true",
        help="List all available prayers, languages, and voices.",
    )
    return parser


def validate_language(prayer: Prayer, raw: str) -> Optional[str]:
    resolved = prayer.resolve_language(raw)
    if resolved is None:
        print(f"\n  ❌  Unrecognised language: '{raw}'")
        print(f"      Valid choices: {', '.join(prayer.language_aliases.keys())}")
        print()
        sys.exit(1)
    return resolved


def validate_voice(prayer: Prayer, language: str, raw: str) -> str:
    resolved = prayer.resolve_voice(raw)
    available = list(prayer.voices[language].keys())
    if resolved not in available:
        print(f"\n  ❌  Voice '{raw}' not available for {language}.")
        print(f"      Available: {', '.join(available)}")
        print()
        sys.exit(1)
    return resolved


def main() -> None:
    parser = build_parser()
    args   = parser.parse_args()

    # No arguments → help
    if len(sys.argv) == 1:
        parser.print_help()
        print()
        return

    # --list
    if args.list:
        list_all()
        return

    if args.all:
        prayers   = [PRAYERS[args.prayer]] if args.prayer else list(PRAYERS.values())
        for prayer in prayers:
            # resolve language filter
            if args.language:
                lang_filter = [validate_language(prayer, args.language)]
            else:
                lang_filter = prayer.language_names()

            voice_filter = [validate_voice(prayer, lang_filter[0], args.voice)] \
                           if args.voice else prayer.voice_names()

            total = len(lang_filter) * len(voice_filter)
            print(f"\n{prayer.title} — {total} combination{'s' if total != 1 else ''}")

            for lang in lang_filter:
                # resolve voice list per language (Polish has one voice)
                available_voices = list(prayer.voices[lang].keys())
                voices = [v for v in voice_filter if v in available_voices] \
                         or [available_voices[0]]
                for voice in voices:
                    speak(prayer, voice, lang, args.rate)

    else:
        # Single recitation
        prayer_key = args.prayer or DEFAULT_PRAYER
        prayer     = PRAYERS.get(prayer_key)
        if prayer is None:
            print(f"\n  ❌  Unknown prayer: '{prayer_key}'")
            print(f"      Valid choices: {', '.join(PRAYERS.keys())}")
            sys.exit(1)

        # Default language per prayer
        default_lang = "italian" if prayer.name == "ave" else "english"
        raw_lang     = args.language or default_lang
        language     = validate_language(prayer, raw_lang)

        raw_voice = args.voice or "Grandma"
        voice     = validate_voice(prayer, language, raw_voice)

        speak(prayer, voice, language, args.rate)

    print(f"\n{'─' * 60}")
    print("  Amen.")
    print(f"{'─' * 60}\n")


if __name__ == "__main__":
    main()
