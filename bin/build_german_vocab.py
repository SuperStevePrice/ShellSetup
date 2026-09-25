#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
build_german_vocab.py — regenerates german_vocabulary_by_domain.xlsx from
source data (this file). Safe to run on any machine with Python 3 +
openpyxl; writes no fixed paths.

Usage:
    build_german_vocab.py                # writes ./german_vocabulary_by_domain.xlsx
    build_german_vocab.py /some/dir/out.xlsx
    VOCAB_OUT_DIR=~/Documents build_german_vocab.py
"""
import os
import sys
import openpyxl
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from openpyxl.utils import get_column_letter
from openpyxl.worksheet.hyperlink import Hyperlink

_link_counter = [0]

def internal_link(sheet_name, display=None):
    """A true same-workbook hyperlink: a 'location' reference with no
    relationship/target, matching how Excel itself writes a jump-to-sheet
    link (no '#', no external Target/TargetMode)."""
    _link_counter[0] += 1
    return Hyperlink(
        ref="",  # set by the cell.hyperlink setter to the cell's own coordinate
        location=f"'{sheet_name}'!A1",
        display=display or sheet_name,
        id=None,
    )

def write_footer_nav(ws, row, links):
    """links: list of (display_text, target_sheet_name), placed left to
    right starting at column 1 of the given row."""
    for c, (display, target) in enumerate(links, start=1):
        cell = ws.cell(row=row, column=c, value=display)
        cell.hyperlink = internal_link(target, display=display)
        cell.style = "Hyperlink"
        cell.font = Font(name=FONT_NAME, size=12, bold=True, underline="single", color="0563C1")
        cell.alignment = Alignment(horizontal="left", vertical="center")

REFERENCE_SHEETS = [
    ("\U0001F4D6 Grammar", "Grammar"),
    ("\U0001F4AD Subjunctive", "Subjunctive"),
    ("\U0001F4AC Colloquial and Slang", "Colloquial and Slang"),
    ("\U0001F550 Time Tenses", "Time Tenses"),
    ("\U0001F500 Irregular Verbs", "Irregular Verbs"),
]

def reference_footer_links(current_target=None):
    """Contents plus every reference sheet except the one we're already on."""
    links = [("\u2302 Contents", "Contents")]
    links += [(d, t) for d, t in REFERENCE_SHEETS if t != current_target]
    return links

# ---------------------------------------------------------------------------
# Data: (English, German, Plural, Past, Present, Future)
# ---------------------------------------------------------------------------

DOMAINS = {
    "Home": {
        "title": "The Home \u2013 Das Zuhause",
        "rows": [
            ("Bathroom", "das Badezimmer", "die Badezimmer",
             "Das Badezimmer war wichtig.", "Ich sehe das Badezimmer.", "Ich werde mit dem Badezimmer zufrieden sein.", "Die Bedeutung des Badezimmers ist gro\u00df."),
            ("Bed", "das Bett", "die Betten",
             "Das Bett war wichtig.", "Ich sehe das Bett.", "Ich werde mit dem Bett zufrieden sein.", "Die Bedeutung des Bettes ist gro\u00df."),
            ("Bedroom", "das Schlafzimmer", "die Schlafzimmer",
             "Das Schlafzimmer war wichtig.", "Ich sehe das Schlafzimmer.", "Ich werde mit dem Schlafzimmer zufrieden sein.", "Die Bedeutung des Schlafzimmers ist gro\u00df."),
            ("Carpet", "der Teppich", "die Teppiche",
             "Der Teppich war wichtig.", "Ich sehe den Teppich.", "Ich werde mit dem Teppich zufrieden sein.", "Die Bedeutung des Teppiches ist gro\u00df."),
            ("Ceiling", "die Decke", "die Decken",
             "Die Decke war wichtig.", "Ich sehe die Decke.", "Ich werde mit der Decke zufrieden sein.", "Die Bedeutung der Decke ist gro\u00df."),
            ("Chair", "der Stuhl", "die St\u00fchle",
             "Der Stuhl war wichtig.", "Ich sehe den Stuhl.", "Ich werde mit dem Stuhl zufrieden sein.", "Die Bedeutung des Stuhls ist gro\u00df."),
            ("Door", "die T\u00fcr", "die T\u00fcren",
             "Die T\u00fcr war wichtig.", "Ich sehe die T\u00fcr.", "Ich werde mit der T\u00fcr zufrieden sein.", "Die Bedeutung der T\u00fcr ist gro\u00df."),
            ("Garden", "der Garten", "die G\u00e4rten",
             "Der Garten war wichtig.", "Ich sehe den Garten.", "Ich werde mit dem Garten zufrieden sein.", "Die Bedeutung des Gartens ist gro\u00df."),
            ("Key", "der Schl\u00fcssel", "die Schl\u00fcssel",
             "Der Schl\u00fcssel war wichtig.", "Ich sehe den Schl\u00fcssel.", "Ich werde mit dem Schl\u00fcssel zufrieden sein.", "Die Bedeutung des Schl\u00fcssels ist gro\u00df."),
            ("Kitchen", "die K\u00fcche", "die K\u00fcchen",
             "Die K\u00fcche war wichtig.", "Ich sehe die K\u00fcche.", "Ich werde mit der K\u00fcche zufrieden sein.", "Die Bedeutung der K\u00fcche ist gro\u00df."),
            ("Lamp", "die Lampe", "die Lampen",
             "Die Lampe war wichtig.", "Ich sehe die Lampe.", "Ich werde mit der Lampe zufrieden sein.", "Die Bedeutung der Lampe ist gro\u00df."),
            ("Living room", "das Wohnzimmer", "die Wohnzimmer",
             "Das Wohnzimmer war wichtig.", "Ich sehe das Wohnzimmer.", "Ich werde mit dem Wohnzimmer zufrieden sein.", "Die Bedeutung des Wohnzimmers ist gro\u00df."),
            ("Mirror", "der Spiegel", "die Spiegel",
             "Der Spiegel war wichtig.", "Ich sehe den Spiegel.", "Ich werde mit dem Spiegel zufrieden sein.", "Die Bedeutung des Spiegels ist gro\u00df."),
            ("Roof", "das Dach", "die D\u00e4cher",
             "Das Dach war wichtig.", "Ich sehe das Dach.", "Ich werde mit dem Dach zufrieden sein.", "Die Bedeutung des Daches ist gro\u00df."),
            ("Shelf", "das Regal", "die Regale",
             "Das Regal war wichtig.", "Ich sehe das Regal.", "Ich werde mit dem Regal zufrieden sein.", "Die Bedeutung des Regals ist gro\u00df."),
            ("Table", "der Tisch", "die Tische",
             "Der Tisch war wichtig.", "Ich sehe den Tisch.", "Ich werde mit dem Tisch zufrieden sein.", "Die Bedeutung des Tisches ist gro\u00df."),
            ("Wall", "die Wand", "die W\u00e4nde",
             "Die Wand war wichtig.", "Ich sehe die Wand.", "Ich werde mit der Wand zufrieden sein.", "Die Bedeutung der Wand ist gro\u00df."),
            ("Window", "das Fenster", "die Fenster",
             "Das Fenster war wichtig.", "Ich sehe das Fenster.", "Ich werde mit dem Fenster zufrieden sein.", "Die Bedeutung des Fensters ist gro\u00df."),
        ],
    },
    "Nature": {
        "title": "Nature \u2013 Die Natur",
        "rows": [
            ("Animal", "das Tier", "die Tiere",
             "Das Tier war wichtig.", "Ich sehe das Tier.", "Ich werde mit dem Tier zufrieden sein.", "Die Bedeutung des Tieres ist gro\u00df."),
            ("Cloud", "die Wolke", "die Wolken",
             "Die Wolke war wichtig.", "Ich sehe die Wolke.", "Ich werde mit der Wolke zufrieden sein.", "Die Bedeutung der Wolke ist gro\u00df."),
            ("Flower", "die Blume", "die Blumen",
             "Die Blume war wichtig.", "Ich sehe die Blume.", "Ich werde mit der Blume zufrieden sein.", "Die Bedeutung der Blume ist gro\u00df."),
            ("Forest", "der Wald", "die W\u00e4lder",
             "Der Wald war wichtig.", "Ich sehe den Wald.", "Ich werde mit dem Wald zufrieden sein.", "Die Bedeutung des Waldes ist gro\u00df."),
            ("Lake", "der See", "die Seen",
             "Der See war wichtig.", "Ich sehe den See.", "Ich werde mit dem See zufrieden sein.", "Die Bedeutung des Sees ist gro\u00df."),
            ("Moon", "der Mond", "die Monde",
             "Der Mond war wichtig.", "Ich sehe den Mond.", "Ich werde mit dem Mond zufrieden sein.", "Die Bedeutung des Mondes ist gro\u00df."),
            ("Mountain", "der Berg", "die Berge",
             "Der Berg war wichtig.", "Ich sehe den Berg.", "Ich werde mit dem Berg zufrieden sein.", "Die Bedeutung des Berges ist gro\u00df."),
            ("Rain", "der Regen", "\u2014",
             "Der Regen war wichtig.", "Ich sehe den Regen.", "Ich werde mit dem Regen zufrieden sein.", "Die Bedeutung des Regens ist gro\u00df."),
            ("River", "der Fluss", "die Fl\u00fcsse",
             "Der Fluss war wichtig.", "Ich sehe den Fluss.", "Ich werde mit dem Fluss zufrieden sein.", "Die Bedeutung des Flusses ist gro\u00df."),
            ("Sea", "das Meer", "die Meere",
             "Das Meer war wichtig.", "Ich sehe das Meer.", "Ich werde mit dem Meer zufrieden sein.", "Die Bedeutung des Meeres ist gro\u00df."),
            ("Sky", "der Himmel", "die Himmel",
             "Der Himmel war wichtig.", "Ich sehe den Himmel.", "Ich werde mit dem Himmel zufrieden sein.", "Die Bedeutung des Himmels ist gro\u00df."),
            ("Snow", "der Schnee", "\u2014",
             "Der Schnee war wichtig.", "Ich sehe den Schnee.", "Ich werde mit dem Schnee zufrieden sein.", "Die Bedeutung des Schnees ist gro\u00df."),
            ("Star", "der Stern", "die Sterne",
             "Der Stern war wichtig.", "Ich sehe den Stern.", "Ich werde mit dem Stern zufrieden sein.", "Die Bedeutung des Sterns ist gro\u00df."),
            ("Stone", "der Stein", "die Steine",
             "Der Stein war wichtig.", "Ich sehe den Stein.", "Ich werde mit dem Stein zufrieden sein.", "Die Bedeutung des Steins ist gro\u00df."),
            ("Sun", "die Sonne", "die Sonnen",
             "Die Sonne war wichtig.", "Ich sehe die Sonne.", "Ich werde mit der Sonne zufrieden sein.", "Die Bedeutung der Sonne ist gro\u00df."),
            ("Tree", "der Baum", "die B\u00e4ume",
             "Der Baum war wichtig.", "Ich sehe den Baum.", "Ich werde mit dem Baum zufrieden sein.", "Die Bedeutung des Baumes ist gro\u00df."),
            ("Valley", "das Tal", "die T\u00e4ler",
             "Das Tal war wichtig.", "Ich sehe das Tal.", "Ich werde mit dem Tal zufrieden sein.", "Die Bedeutung des Tals ist gro\u00df."),
            ("Wind", "der Wind", "die Winde",
             "Der Wind war wichtig.", "Ich sehe den Wind.", "Ich werde mit dem Wind zufrieden sein.", "Die Bedeutung des Windes ist gro\u00df."),
        ],
    },
    "City": {
        "title": "The City \u2013 Die Stadt",
        "rows": [
            ("Bridge", "die Br\u00fccke", "die Br\u00fccken",
             "Die Br\u00fccke war wichtig.", "Ich sehe die Br\u00fccke.", "Ich werde mit der Br\u00fccke zufrieden sein.", "Die Bedeutung der Br\u00fccke ist gro\u00df."),
            ("Building", "das Geb\u00e4ude", "die Geb\u00e4ude",
             "Das Geb\u00e4ude war wichtig.", "Ich sehe das Geb\u00e4ude.", "Ich werde mit dem Geb\u00e4ude zufrieden sein.", "Die Bedeutung des Geb\u00e4udes ist gro\u00df."),
            ("Church", "die Kirche", "die Kirchen",
             "Die Kirche war wichtig.", "Ich sehe die Kirche.", "Ich werde mit der Kirche zufrieden sein.", "Die Bedeutung der Kirche ist gro\u00df."),
            ("Hospital", "das Krankenhaus", "die Krankenh\u00e4user",
             "Das Krankenhaus war wichtig.", "Ich sehe das Krankenhaus.", "Ich werde mit dem Krankenhaus zufrieden sein.", "Die Bedeutung des Krankenhauses ist gro\u00df."),
            ("Hotel", "das Hotel", "die Hotels",
             "Das Hotel war wichtig.", "Ich sehe das Hotel.", "Ich werde mit dem Hotel zufrieden sein.", "Die Bedeutung des Hotels ist gro\u00df."),
            ("Library", "die Bibliothek", "die Bibliotheken",
             "Die Bibliothek war wichtig.", "Ich sehe die Bibliothek.", "Ich werde mit der Bibliothek zufrieden sein.", "Die Bedeutung der Bibliothek ist gro\u00df."),
            ("Market", "der Markt", "die M\u00e4rkte",
             "Der Markt war wichtig.", "Ich sehe den Markt.", "Ich werde mit dem Markt zufrieden sein.", "Die Bedeutung des Marktes ist gro\u00df."),
            ("Museum", "das Museum", "die Museen",
             "Das Museum war wichtig.", "Ich sehe das Museum.", "Ich werde mit dem Museum zufrieden sein.", "Die Bedeutung des Museums ist gro\u00df."),
            ("Neighborhood", "die Nachbarschaft", "die Nachbarschaften",
             "Die Nachbarschaft war wichtig.", "Ich sehe die Nachbarschaft.", "Ich werde mit der Nachbarschaft zufrieden sein.", "Die Bedeutung der Nachbarschaft ist gro\u00df."),
            ("Park", "der Park", "die Parks",
             "Der Park war wichtig.", "Ich sehe den Park.", "Ich werde mit dem Park zufrieden sein.", "Die Bedeutung des Parks ist gro\u00df."),
            ("Restaurant", "das Restaurant", "die Restaurants",
             "Das Restaurant war wichtig.", "Ich sehe das Restaurant.", "Ich werde mit dem Restaurant zufrieden sein.", "Die Bedeutung des Restaurants ist gro\u00df."),
            ("School", "die Schule", "die Schulen",
             "Die Schule war wichtig.", "Ich sehe die Schule.", "Ich werde mit der Schule zufrieden sein.", "Die Bedeutung der Schule ist gro\u00df."),
            ("Shop", "der Laden", "die L\u00e4den",
             "Der Laden war wichtig.", "Ich sehe den Laden.", "Ich werde mit dem Laden zufrieden sein.", "Die Bedeutung des Ladens ist gro\u00df."),
            ("Square", "der Platz", "die Pl\u00e4tze",
             "Der Platz war wichtig.", "Ich sehe den Platz.", "Ich werde mit dem Platz zufrieden sein.", "Die Bedeutung des Platzes ist gro\u00df."),
            ("Street", "die Stra\u00dfe", "die Stra\u00dfen",
             "Die Stra\u00dfe war wichtig.", "Ich sehe die Stra\u00dfe.", "Ich werde mit der Stra\u00dfe zufrieden sein.", "Die Bedeutung der Stra\u00dfe ist gro\u00df."),
            ("Tower", "der Turm", "die T\u00fcrme",
             "Der Turm war wichtig.", "Ich sehe den Turm.", "Ich werde mit dem Turm zufrieden sein.", "Die Bedeutung des Turmes ist gro\u00df."),
            ("Traffic", "der Verkehr", "\u2014",
             "Der Verkehr war wichtig.", "Ich sehe den Verkehr.", "Ich werde mit dem Verkehr zufrieden sein.", "Die Bedeutung des Verkehrs ist gro\u00df."),
            ("Train station", "der Bahnhof", "die Bahnh\u00f6fe",
             "Der Bahnhof war wichtig.", "Ich sehe den Bahnhof.", "Ich werde mit dem Bahnhof zufrieden sein.", "Die Bedeutung des Bahnhofs ist gro\u00df."),
        ],
    },
    "Country Life": {
        "title": "Country Life \u2013 Das Landleben",
        "rows": [
            ("Barn", "die Scheune", "die Scheunen",
             "Die Scheune war wichtig.", "Ich sehe die Scheune.", "Ich werde mit der Scheune zufrieden sein.", "Die Bedeutung der Scheune ist gro\u00df."),
            ("Chicken", "das Huhn", "die H\u00fchner",
             "Das Huhn war wichtig.", "Ich sehe das Huhn.", "Ich werde mit dem Huhn zufrieden sein.", "Die Bedeutung des Huhns ist gro\u00df."),
            ("Cow", "die Kuh", "die K\u00fche",
             "Die Kuh war wichtig.", "Ich sehe die Kuh.", "Ich werde mit der Kuh zufrieden sein.", "Die Bedeutung der Kuh ist gro\u00df."),
            ("Farm", "der Bauernhof", "die Bauernh\u00f6fe",
             "Der Bauernhof war wichtig.", "Ich sehe den Bauernhof.", "Ich werde mit dem Bauernhof zufrieden sein.", "Die Bedeutung des Bauernhofs ist gro\u00df."),
            ("Farmer", "der Bauer", "die Bauern",
             "Der Bauer war wichtig.", "Ich sehe den Bauern.", "Ich werde mit dem Bauern zufrieden sein.", "Die Bedeutung des Bauern ist gro\u00df."),
            ("Fence", "der Zaun", "die Z\u00e4une",
             "Der Zaun war wichtig.", "Ich sehe den Zaun.", "Ich werde mit dem Zaun zufrieden sein.", "Die Bedeutung des Zauns ist gro\u00df."),
            ("Field", "das Feld", "die Felder",
             "Das Feld war wichtig.", "Ich sehe das Feld.", "Ich werde mit dem Feld zufrieden sein.", "Die Bedeutung des Feldes ist gro\u00df."),
            ("Grain", "das Korn", "die K\u00f6rner",
             "Das Korn war wichtig.", "Ich sehe das Korn.", "Ich werde mit dem Korn zufrieden sein.", "Die Bedeutung des Korns ist gro\u00df."),
            ("Harvest", "die Ernte", "die Ernten",
             "Die Ernte war wichtig.", "Ich sehe die Ernte.", "Ich werde mit der Ernte zufrieden sein.", "Die Bedeutung der Ernte ist gro\u00df."),
            ("Horse", "das Pferd", "die Pferde",
             "Das Pferd war wichtig.", "Ich sehe das Pferd.", "Ich werde mit dem Pferd zufrieden sein.", "Die Bedeutung des Pferdes ist gro\u00df."),
            ("Meadow", "die Wiese", "die Wiesen",
             "Die Wiese war wichtig.", "Ich sehe die Wiese.", "Ich werde mit der Wiese zufrieden sein.", "Die Bedeutung der Wiese ist gro\u00df."),
            ("Orchard", "der Obstgarten", "die Obstg\u00e4rten",
             "Der Obstgarten war wichtig.", "Ich sehe den Obstgarten.", "Ich werde mit dem Obstgarten zufrieden sein.", "Die Bedeutung des Obstgartens ist gro\u00df."),
            ("Pond", "der Teich", "die Teiche",
             "Der Teich war wichtig.", "Ich sehe den Teich.", "Ich werde mit dem Teich zufrieden sein.", "Die Bedeutung des Teiches ist gro\u00df."),
            ("Shepherd", "der Hirte", "die Hirten",
             "Der Hirte war wichtig.", "Ich sehe den Hirten.", "Ich werde mit dem Hirten zufrieden sein.", "Die Bedeutung des Hirten ist gro\u00df."),
            ("Stable", "der Stall", "die St\u00e4lle",
             "Der Stall war wichtig.", "Ich sehe den Stall.", "Ich werde mit dem Stall zufrieden sein.", "Die Bedeutung des Stalls ist gro\u00df."),
            ("Tractor", "der Traktor", "die Traktoren",
             "Der Traktor war wichtig.", "Ich sehe den Traktor.", "Ich werde mit dem Traktor zufrieden sein.", "Die Bedeutung des Traktors ist gro\u00df."),
            ("Village", "das Dorf", "die D\u00f6rfer",
             "Das Dorf war wichtig.", "Ich sehe das Dorf.", "Ich werde mit dem Dorf zufrieden sein.", "Die Bedeutung des Dorfes ist gro\u00df."),
            ("Well", "der Brunnen", "die Brunnen",
             "Der Brunnen war wichtig.", "Ich sehe den Brunnen.", "Ich werde mit dem Brunnen zufrieden sein.", "Die Bedeutung des Brunnens ist gro\u00df."),
        ],
    },
    "Government": {
        "title": "Government \u2013 Die Regierung",
        "rows": [
            ("Ambassador", "der Botschafter", "die Botschafter",
             "Der Botschafter war wichtig.", "Ich sehe den Botschafter.", "Ich werde mit dem Botschafter zufrieden sein.", "Die Bedeutung des Botschafters ist gro\u00df."),
            ("Citizen", "der B\u00fcrger", "die B\u00fcrger",
             "Der B\u00fcrger war wichtig.", "Ich sehe den B\u00fcrger.", "Ich werde mit dem B\u00fcrger zufrieden sein.", "Die Bedeutung des B\u00fcrgers ist gro\u00df."),
            ("Constitution", "die Verfassung", "die Verfassungen",
             "Die Verfassung war wichtig.", "Ich sehe die Verfassung.", "Ich werde mit der Verfassung zufrieden sein.", "Die Bedeutung der Verfassung ist gro\u00df."),
            ("Court", "das Gericht", "die Gerichte",
             "Das Gericht war wichtig.", "Ich sehe das Gericht.", "Ich werde mit dem Gericht zufrieden sein.", "Die Bedeutung des Gerichts ist gro\u00df."),
            ("Democracy", "die Demokratie", "die Demokratien",
             "Die Demokratie war wichtig.", "Ich sehe die Demokratie.", "Ich werde mit der Demokratie zufrieden sein.", "Die Bedeutung der Demokratie ist gro\u00df."),
            ("Election", "die Wahl", "die Wahlen",
             "Die Wahl war wichtig.", "Ich sehe die Wahl.", "Ich werde mit der Wahl zufrieden sein.", "Die Bedeutung der Wahl ist gro\u00df."),
            ("Judge", "der Richter", "die Richter",
             "Der Richter war wichtig.", "Ich sehe den Richter.", "Ich werde mit dem Richter zufrieden sein.", "Die Bedeutung des Richters ist gro\u00df."),
            ("Law", "das Gesetz", "die Gesetze",
             "Das Gesetz war wichtig.", "Ich sehe das Gesetz.", "Ich werde mit dem Gesetz zufrieden sein.", "Die Bedeutung des Gesetzes ist gro\u00df."),
            ("Minister", "der Minister", "die Minister",
             "Der Minister war wichtig.", "Ich sehe den Minister.", "Ich werde mit dem Minister zufrieden sein.", "Die Bedeutung des Ministers ist gro\u00df."),
            ("Ministry", "das Ministerium", "die Ministerien",
             "Das Ministerium war wichtig.", "Ich sehe das Ministerium.", "Ich werde mit dem Ministerium zufrieden sein.", "Die Bedeutung des Ministeriums ist gro\u00df."),
            ("Nation", "die Nation", "die Nationen",
             "Die Nation war wichtig.", "Ich sehe die Nation.", "Ich werde mit der Nation zufrieden sein.", "Die Bedeutung der Nation ist gro\u00df."),
            ("Parliament", "das Parlament", "die Parlamente",
             "Das Parlament war wichtig.", "Ich sehe das Parlament.", "Ich werde mit dem Parlament zufrieden sein.", "Die Bedeutung des Parlaments ist gro\u00df."),
            ("President", "der Pr\u00e4sident", "die Pr\u00e4sidenten",
             "Der Pr\u00e4sident war wichtig.", "Ich sehe den Pr\u00e4sidenten.", "Ich werde mit dem Pr\u00e4sidenten zufrieden sein.", "Die Bedeutung des Pr\u00e4sidenten ist gro\u00df."),
            ("Rights", "das Recht", "die Rechte",
             "Das Recht war wichtig.", "Ich sehe das Recht.", "Ich werde mit dem Recht zufrieden sein.", "Die Bedeutung des Rechts ist gro\u00df."),
            ("Senate", "der Senat", "die Senate",
             "Der Senat war wichtig.", "Ich sehe den Senat.", "Ich werde mit dem Senat zufrieden sein.", "Die Bedeutung des Senats ist gro\u00df."),
            ("State", "der Staat", "die Staaten",
             "Der Staat war wichtig.", "Ich sehe den Staat.", "Ich werde mit dem Staat zufrieden sein.", "Die Bedeutung des Staates ist gro\u00df."),
            ("Treaty", "der Vertrag", "die Vertr\u00e4ge",
             "Der Vertrag war wichtig.", "Ich sehe den Vertrag.", "Ich werde mit dem Vertrag zufrieden sein.", "Die Bedeutung des Vertrages ist gro\u00df."),
            ("Vote", "die Stimme", "die Stimmen",
             "Die Stimme war wichtig.", "Ich sehe die Stimme.", "Ich werde mit der Stimme zufrieden sein.", "Die Bedeutung der Stimme ist gro\u00df."),
        ],
    },
    "Theology": {
        "title": "Theology \u2013 Die Theologie",
        "rows": [
            ("Baptism", "die Taufe", "die Taufen",
             "Die Taufe war wichtig.", "Ich sehe die Taufe.", "Ich werde mit der Taufe zufrieden sein.", "Die Bedeutung der Taufe ist gro\u00df."),
            ("Church (body)", "die Kirche", "die Kirchen",
             "Die Kirche war wichtig.", "Ich sehe die Kirche.", "Ich werde mit der Kirche zufrieden sein.", "Die Bedeutung der Kirche ist gro\u00df."),
            ("Covenant", "der Bund", "die B\u00fcnde",
             "Der Bund war wichtig.", "Ich sehe den Bund.", "Ich werde mit dem Bund zufrieden sein.", "Die Bedeutung des Bundes ist gro\u00df."),
            ("Cross", "das Kreuz", "die Kreuze",
             "Das Kreuz war wichtig.", "Ich sehe das Kreuz.", "Ich werde dem Kreuz treu bleiben.", "Die Bedeutung des Kreuzes ist gro\u00df."),
            ("Faith", "der Glaube", "\u2014",
             "Der Glaube war wichtig.", "Ich sehe den Glauben.", "Ich werde mit dem Glauben zufrieden sein.", "Die Bedeutung des Glaubens ist gro\u00df."),
            ("God", "Gott", "\u2014",
             "Gott war treu.", "Ich liebe Gott von ganzem Herzen.", "Ich werde Gott vertrauen.", "Gottes Wille geschehe."),
            ("Grace", "die Gnade", "die Gnaden",
             "Die Gnade war wichtig.", "Ich sehe die Gnade.", "Ich werde mit der Gnade zufrieden sein.", "Die Bedeutung der Gnade ist gro\u00df."),
            ("Prayer", "das Gebet", "die Gebete",
             "Das Gebet war wichtig.", "Ich sehe das Gebet.", "Ich werde mit dem Gebet zufrieden sein.", "Die Bedeutung des Gebets ist gro\u00df."),
            ("Repentance", "die Bu\u00dfe", "\u2014",
             "Die Bu\u00dfe war wichtig.", "Ich sehe die Bu\u00dfe.", "Ich werde mit der Bu\u00dfe zufrieden sein.", "Die Bedeutung der Bu\u00dfe ist gro\u00df."),
            ("Sabbath", "der Sabbat", "\u2014",
             "Der Sabbat war wichtig.", "Ich sehe den Sabbat.", "Ich werde mit dem Sabbat zufrieden sein.", "Die Bedeutung des Sabbats ist gro\u00df."),
            ("Sacrament", "das Sakrament", "die Sakramente",
             "Das Sakrament war wichtig.", "Ich sehe das Sakrament.", "Ich werde mit dem Sakrament zufrieden sein.", "Die Bedeutung des Sakraments ist gro\u00df."),
            ("Salvation", "die Erl\u00f6sung", "\u2014",
             "Die Erl\u00f6sung war wichtig.", "Ich sehe die Erl\u00f6sung.", "Ich werde mit der Erl\u00f6sung zufrieden sein.", "Die Bedeutung der Erl\u00f6sung ist gro\u00df."),
            ("Scripture", "die Schrift", "die Schriften",
             "Die Schrift war wichtig.", "Ich sehe die Schrift.", "Ich werde mit der Schrift zufrieden sein.", "Die Bedeutung der Schrift ist gro\u00df."),
            ("Sermon", "die Predigt", "die Predigten",
             "Die Predigt war wichtig.", "Ich sehe die Predigt.", "Ich werde mit der Predigt zufrieden sein.", "Die Bedeutung der Predigt ist gro\u00df."),
            ("Sin", "die S\u00fcnde", "die S\u00fcnden",
             "Die S\u00fcnde war \u00fcberall.", "Ich sehe die S\u00fcnde.", "Ich werde von der S\u00fcnde frei sein.", "Die Bedeutung der S\u00fcnde ist gro\u00df."),
            ("Soul", "die Seele", "die Seelen",
             "Die Seele war wichtig.", "Ich sehe die Seele.", "Ich werde mit der Seele zufrieden sein.", "Die Bedeutung der Seele ist gro\u00df."),
            ("Spirit", "der Geist", "die Geister",
             "Der Geist war wichtig.", "Ich sehe den Geist.", "Ich werde mit dem Geist zufrieden sein.", "Die Bedeutung des Geistes ist gro\u00df."),
            ("Trinity", "die Dreifaltigkeit", "\u2014",
             "Die Dreifaltigkeit war ein Geheimnis.", "Ich sehe die Dreifaltigkeit.", "Ich werde mit der Dreifaltigkeit zufrieden sein.", "Die Bedeutung der Dreifaltigkeit ist gro\u00df."),
        ],
    },
    "Philosophy": {
        "title": "Philosophy \u2013 Die Philosophie",
        "rows": [
            ("Being", "das Sein", "\u2014",
             "Das Sein war wichtig.", "Ich sehe das Sein.", "Ich werde mit dem Sein zufrieden sein.", "Die Bedeutung des Seins ist gro\u00df."),
            ("Consciousness", "das Bewusstsein", "\u2014",
             "Das Bewusstsein war wichtig.", "Ich sehe das Bewusstsein.", "Ich werde mit dem Bewusstsein zufrieden sein.", "Die Bedeutung des Bewusstseins ist gro\u00df."),
            ("Doubt", "der Zweifel", "die Zweifel",
             "Der Zweifel war wichtig.", "Ich sehe den Zweifel.", "Ich werde mit dem Zweifel zufrieden sein.", "Die Bedeutung des Zweifels ist gro\u00df."),
            ("Ethics", "die Ethik", "\u2014",
             "Die Ethik war wichtig.", "Ich sehe die Ethik.", "Ich werde mit der Ethik zufrieden sein.", "Die Bedeutung der Ethik ist gro\u00df."),
            ("Existence", "die Existenz", "die Existenzen",
             "Die Existenz war wichtig.", "Ich sehe die Existenz.", "Ich werde mit der Existenz zufrieden sein.", "Die Bedeutung der Existenz ist gro\u00df."),
            ("Freedom", "die Freiheit", "die Freiheiten",
             "Die Freiheit war wichtig.", "Ich sehe die Freiheit.", "Ich werde mit der Freiheit zufrieden sein.", "Die Bedeutung der Freiheit ist gro\u00df."),
            ("Idea", "die Idee", "die Ideen",
             "Die Idee war wichtig.", "Ich sehe die Idee.", "Ich werde mit der Idee zufrieden sein.", "Die Bedeutung der Idee ist gro\u00df."),
            ("Justice", "die Gerechtigkeit", "\u2014",
             "Die Gerechtigkeit war wichtig.", "Ich sehe die Gerechtigkeit.", "Ich werde mit der Gerechtigkeit zufrieden sein.", "Die Bedeutung der Gerechtigkeit ist gro\u00df."),
            ("Knowledge", "das Wissen", "\u2014",
             "Das Wissen war wichtig.", "Ich sehe das Wissen.", "Ich werde mit dem Wissen zufrieden sein.", "Die Bedeutung des Wissens ist gro\u00df."),
            ("Logic", "die Logik", "\u2014",
             "Die Logik war wichtig.", "Ich sehe die Logik.", "Ich werde mit der Logik zufrieden sein.", "Die Bedeutung der Logik ist gro\u00df."),
            ("Metaphysics", "die Metaphysik", "\u2014",
             "Die Metaphysik war wichtig.", "Ich sehe die Metaphysik.", "Ich werde mit der Metaphysik zufrieden sein.", "Die Bedeutung der Metaphysik ist gro\u00df."),
            ("Mind", "der Verstand", "\u2014",
             "Der Verstand war wichtig.", "Ich sehe den Verstand.", "Ich werde mit dem Verstand zufrieden sein.", "Die Bedeutung des Verstandes ist gro\u00df."),
            ("Perception", "die Wahrnehmung", "die Wahrnehmungen",
             "Die Wahrnehmung war wichtig.", "Ich sehe die Wahrnehmung.", "Ich werde mit der Wahrnehmung zufrieden sein.", "Die Bedeutung der Wahrnehmung ist gro\u00df."),
            ("Reason", "die Vernunft", "\u2014",
             "Die Vernunft war wichtig.", "Ich sehe die Vernunft.", "Ich werde mit der Vernunft zufrieden sein.", "Die Bedeutung der Vernunft ist gro\u00df."),
            ("Skepticism", "die Skepsis", "\u2014",
             "Die Skepsis war wichtig.", "Ich sehe die Skepsis.", "Ich werde mit der Skepsis zufrieden sein.", "Die Bedeutung der Skepsis ist gro\u00df."),
            ("Truth", "die Wahrheit", "die Wahrheiten",
             "Die Wahrheit war wichtig.", "Ich sehe die Wahrheit.", "Ich werde mit der Wahrheit zufrieden sein.", "Die Bedeutung der Wahrheit ist gro\u00df."),
            ("Virtue", "die Tugend", "die Tugenden",
             "Die Tugend war wichtig.", "Ich sehe die Tugend.", "Ich werde mit der Tugend zufrieden sein.", "Die Bedeutung der Tugend ist gro\u00df."),
            ("Wisdom", "die Weisheit", "die Weisheiten",
             "Die Weisheit war wichtig.", "Ich sehe die Weisheit.", "Ich werde mit der Weisheit zufrieden sein.", "Die Bedeutung der Weisheit ist gro\u00df."),
        ],
    },
    "Military": {
        "title": "The Military \u2013 Das Milit\u00e4r",
        "rows": [
            ("Alliance", "das B\u00fcndnis", "die B\u00fcndnisse",
             "Das B\u00fcndnis war wichtig.", "Ich sehe das B\u00fcndnis.", "Ich werde mit dem B\u00fcndnis zufrieden sein.", "Die Bedeutung des B\u00fcndnisses ist gro\u00df."),
            ("Army", "die Armee", "die Armeen",
             "Die Armee war wichtig.", "Ich sehe die Armee.", "Ich werde mit der Armee zufrieden sein.", "Die Bedeutung der Armee ist gro\u00df."),
            ("Battle", "die Schlacht", "die Schlachten",
             "Die Schlacht war wichtig.", "Ich sehe die Schlacht.", "Ich werde mit der Schlacht zufrieden sein.", "Die Bedeutung der Schlacht ist gro\u00df."),
            ("Camp", "das Lager", "die Lager",
             "Das Lager war wichtig.", "Ich sehe das Lager.", "Ich werde mit dem Lager zufrieden sein.", "Die Bedeutung des Lagers ist gro\u00df."),
            ("Command", "der Befehl", "die Befehle",
             "Der Befehl war wichtig.", "Ich sehe den Befehl.", "Ich werde mit dem Befehl zufrieden sein.", "Die Bedeutung des Befehls ist gro\u00df."),
            ("Defeat", "die Niederlage", "die Niederlagen",
             "Die Niederlage war wichtig.", "Ich sehe die Niederlage.", "Ich werde mit der Niederlage zufrieden sein.", "Die Bedeutung der Niederlage ist gro\u00df."),
            ("Enemy", "der Feind", "die Feinde",
             "Der Feind war wichtig.", "Ich sehe den Feind.", "Ich werde mit dem Feind zufrieden sein.", "Die Bedeutung des Feindes ist gro\u00df."),
            ("Fortress", "die Festung", "die Festungen",
             "Die Festung war wichtig.", "Ich sehe die Festung.", "Ich werde mit der Festung zufrieden sein.", "Die Bedeutung der Festung ist gro\u00df."),
            ("General", "der General", "die Gener\u00e4le",
             "Der General war wichtig.", "Ich sehe den General.", "Ich werde mit dem General zufrieden sein.", "Die Bedeutung des Generals ist gro\u00df."),
            ("Officer", "der Offizier", "die Offiziere",
             "Der Offizier war wichtig.", "Ich sehe den Offizier.", "Ich werde mit dem Offizier zufrieden sein.", "Die Bedeutung des Offiziers ist gro\u00df."),
            ("Peace", "der Frieden", "\u2014",
             "Der Frieden war wichtig.", "Ich sehe den Frieden.", "Ich werde mit dem Frieden zufrieden sein.", "Die Bedeutung des Friedens ist gro\u00df."),
            ("Rifle", "das Gewehr", "die Gewehre",
             "Das Gewehr war wichtig.", "Ich sehe das Gewehr.", "Ich werde mit dem Gewehr zufrieden sein.", "Die Bedeutung des Gewehrs ist gro\u00df."),
            ("Soldier", "der Soldat", "die Soldaten",
             "Der Soldat war wichtig.", "Ich sehe den Soldaten.", "Ich werde mit dem Soldaten zufrieden sein.", "Die Bedeutung des Soldaten ist gro\u00df."),
            ("Tank", "der Panzer", "die Panzer",
             "Der Panzer war wichtig.", "Ich sehe den Panzer.", "Ich werde mit dem Panzer zufrieden sein.", "Die Bedeutung des Panzers ist gro\u00df."),
            ("Uniform", "die Uniform", "die Uniformen",
             "Die Uniform war wichtig.", "Ich sehe die Uniform.", "Ich werde mit der Uniform zufrieden sein.", "Die Bedeutung der Uniform ist gro\u00df."),
            ("Victory", "der Sieg", "die Siege",
             "Der Sieg war wichtig.", "Ich sehe den Sieg.", "Ich werde mit dem Sieg zufrieden sein.", "Die Bedeutung des Sieges ist gro\u00df."),
            ("War", "der Krieg", "die Kriege",
             "Der Krieg war wichtig.", "Ich sehe den Krieg.", "Ich werde mit dem Krieg zufrieden sein.", "Die Bedeutung des Krieges ist gro\u00df."),
            ("Weapon", "die Waffe", "die Waffen",
             "Die Waffe war wichtig.", "Ich sehe die Waffe.", "Ich werde mit der Waffe zufrieden sein.", "Die Bedeutung der Waffe ist gro\u00df."),
        ],
    },
    "Literature and Arts": {
        "title": "Literature and Arts \u2013 Literatur und Kunst",
        "rows": [
            ("Art", "die Kunst", "die K\u00fcnste",
             "Die Kunst war wichtig.", "Ich sehe die Kunst.", "Ich werde mit der Kunst zufrieden sein.", "Die Bedeutung der Kunst ist gro\u00df."),
            ("Author", "der Autor", "die Autoren",
             "Der Autor war wichtig.", "Ich sehe den Autor.", "Ich werde mit dem Autor zufrieden sein.", "Die Bedeutung des Autors ist gro\u00df."),
            ("Book", "das Buch", "die B\u00fccher",
             "Das Buch war wichtig.", "Ich sehe das Buch.", "Ich werde mit dem Buch zufrieden sein.", "Die Bedeutung des Buches ist gro\u00df."),
            ("Chapter", "das Kapitel", "die Kapitel",
             "Das Kapitel war wichtig.", "Ich sehe das Kapitel.", "Ich werde mit dem Kapitel zufrieden sein.", "Die Bedeutung des Kapitels ist gro\u00df."),
            ("Character", "die Figur", "die Figuren",
             "Die Figur war wichtig.", "Ich sehe die Figur.", "Ich werde mit der Figur zufrieden sein.", "Die Bedeutung der Figur ist gro\u00df."),
            ("Drama", "das Drama", "die Dramen",
             "Das Drama war wichtig.", "Ich sehe das Drama.", "Ich werde mit dem Drama zufrieden sein.", "Die Bedeutung des Dramas ist gro\u00df."),
            ("Language", "die Sprache", "die Sprachen",
             "Die Sprache war wichtig.", "Ich sehe die Sprache.", "Ich werde mit der Sprache zufrieden sein.", "Die Bedeutung der Sprache ist gro\u00df."),
            ("Metaphor", "die Metapher", "die Metaphern",
             "Die Metapher war wichtig.", "Ich sehe die Metapher.", "Ich werde mit der Metapher zufrieden sein.", "Die Bedeutung der Metapher ist gro\u00df."),
            ("Music", "die Musik", "\u2014",
             "Die Musik war wichtig.", "Ich sehe die Musik.", "Ich werde mit der Musik zufrieden sein.", "Die Bedeutung der Musik ist gro\u00df."),
            ("Novel", "der Roman", "die Romane",
             "Der Roman war wichtig.", "Ich sehe den Roman.", "Ich werde mit dem Roman zufrieden sein.", "Die Bedeutung des Romans ist gro\u00df."),
            ("Painting", "das Gem\u00e4lde", "die Gem\u00e4lde",
             "Das Gem\u00e4lde war wichtig.", "Ich sehe das Gem\u00e4lde.", "Ich werde mit dem Gem\u00e4lde zufrieden sein.", "Die Bedeutung des Gem\u00e4ldes ist gro\u00df."),
            ("Poem", "das Gedicht", "die Gedichte",
             "Das Gedicht war wichtig.", "Ich sehe das Gedicht.", "Ich werde mit dem Gedicht zufrieden sein.", "Die Bedeutung des Gedichts ist gro\u00df."),
            ("Poet", "der Dichter", "die Dichter",
             "Der Dichter war wichtig.", "Ich sehe den Dichter.", "Ich werde mit dem Dichter zufrieden sein.", "Die Bedeutung des Dichters ist gro\u00df."),
            ("Rhyme", "der Reim", "die Reime",
             "Der Reim war wichtig.", "Ich sehe den Reim.", "Ich werde mit dem Reim zufrieden sein.", "Die Bedeutung des Reimes ist gro\u00df."),
            ("Story", "die Geschichte", "die Geschichten",
             "Die Geschichte war wichtig.", "Ich sehe die Geschichte.", "Ich werde mit der Geschichte zufrieden sein.", "Die Bedeutung der Geschichte ist gro\u00df."),
            ("Theatre", "das Theater", "die Theater",
             "Das Theater war wichtig.", "Ich sehe das Theater.", "Ich werde mit dem Theater zufrieden sein.", "Die Bedeutung des Theaters ist gro\u00df."),
            ("Verse", "der Vers", "die Verse",
             "Der Vers war wichtig.", "Ich sehe den Vers.", "Ich werde mit dem Vers zufrieden sein.", "Die Bedeutung des Verses ist gro\u00df."),
            ("Word", "das Wort", "die W\u00f6rter",
             "Das Wort war wichtig.", "Ich sehe das Wort.", "Ich werde mit dem Wort zufrieden sein.", "Die Bedeutung des Wortes ist gro\u00df."),
        ],
    },
    "Family": {
        "title": "Family \u2013 Die Familie",
        "rows": [
            ("Aunt", "die Tante", "die Tanten",
             "Die Tante war wichtig.", "Ich sehe die Tante.", "Ich werde mit der Tante zufrieden sein.", "Die Bedeutung der Tante ist gro\u00df."),
            ("Brother", "der Bruder", "die Br\u00fcder",
             "Der Bruder war wichtig.", "Ich sehe den Bruder.", "Ich werde mit dem Bruder zufrieden sein.", "Die Bedeutung des Bruders ist gro\u00df."),
            ("Child", "das Kind", "die Kinder",
             "Das Kind war wichtig.", "Ich sehe das Kind.", "Ich werde mit dem Kind zufrieden sein.", "Die Bedeutung des Kindes ist gro\u00df."),
            ("Cousin", "der Cousin", "die Cousins",
             "Der Cousin war wichtig.", "Ich sehe den Cousin.", "Ich werde mit dem Cousin zufrieden sein.", "Die Bedeutung des Cousins ist gro\u00df."),
            ("Daughter", "die Tochter", "die T\u00f6chter",
             "Die Tochter war wichtig.", "Ich sehe die Tochter.", "Ich werde mit der Tochter zufrieden sein.", "Die Bedeutung der Tochter ist gro\u00df."),
            ("Family", "die Familie", "die Familien",
             "Die Familie war wichtig.", "Ich sehe die Familie.", "Ich werde mit der Familie zufrieden sein.", "Die Bedeutung der Familie ist gro\u00df."),
            ("Father", "der Vater", "die V\u00e4ter",
             "Der Vater war wichtig.", "Ich sehe den Vater.", "Ich werde mit dem Vater zufrieden sein.", "Die Bedeutung des Vaters ist gro\u00df."),
            ("Grandchild", "das Enkelkind", "die Enkelkinder",
             "Das Enkelkind war wichtig.", "Ich sehe das Enkelkind.", "Ich werde mit dem Enkelkind zufrieden sein.", "Die Bedeutung des Enkelkindes ist gro\u00df."),
            ("Grandfather", "der Gro\u00dfvater", "die Gro\u00dfv\u00e4ter",
             "Der Gro\u00dfvater war wichtig.", "Ich sehe den Gro\u00dfvater.", "Ich werde mit dem Gro\u00dfvater zufrieden sein.", "Die Bedeutung des Gro\u00dfvaters ist gro\u00df."),
            ("Grandmother", "die Gro\u00dfmutter", "die Gro\u00dfm\u00fctter",
             "Die Gro\u00dfmutter war wichtig.", "Ich sehe die Gro\u00dfmutter.", "Ich werde mit der Gro\u00dfmutter zufrieden sein.", "Die Bedeutung der Gro\u00dfmutter ist gro\u00df."),
            ("Husband", "der Ehemann", "die Ehem\u00e4nner",
             "Der Ehemann war wichtig.", "Ich sehe den Ehemann.", "Ich werde mit dem Ehemann zufrieden sein.", "Die Bedeutung des Ehemannes ist gro\u00df."),
            ("Mother", "die Mutter", "die M\u00fctter",
             "Die Mutter war wichtig.", "Ich sehe die Mutter.", "Ich werde mit der Mutter zufrieden sein.", "Die Bedeutung der Mutter ist gro\u00df."),
            ("Nephew", "der Neffe", "die Neffen",
             "Der Neffe war wichtig.", "Ich sehe den Neffen.", "Ich werde mit dem Neffen zufrieden sein.", "Die Bedeutung des Neffen ist gro\u00df."),
            ("Niece", "die Nichte", "die Nichten",
             "Die Nichte war wichtig.", "Ich sehe die Nichte.", "Ich werde mit der Nichte zufrieden sein.", "Die Bedeutung der Nichte ist gro\u00df."),
            ("Sister", "die Schwester", "die Schwestern",
             "Die Schwester war wichtig.", "Ich sehe die Schwester.", "Ich werde mit der Schwester zufrieden sein.", "Die Bedeutung der Schwester ist gro\u00df."),
            ("Son", "der Sohn", "die S\u00f6hne",
             "Der Sohn war wichtig.", "Ich sehe den Sohn.", "Ich werde mit dem Sohn zufrieden sein.", "Die Bedeutung des Sohnes ist gro\u00df."),
            ("Uncle", "der Onkel", "die Onkel",
             "Der Onkel war wichtig.", "Ich sehe den Onkel.", "Ich werde mit dem Onkel zufrieden sein.", "Die Bedeutung des Onkels ist gro\u00df."),
            ("Wife", "die Ehefrau", "die Ehefrauen",
             "Die Ehefrau war wichtig.", "Ich sehe die Ehefrau.", "Ich werde mit der Ehefrau zufrieden sein.", "Die Bedeutung der Ehefrau ist gro\u00df."),
        ],
    },
    "Sci-Fi": {
        "title": "Sci-Fi \u2013 Science-Fiction",
        "rows": [
            ("Alien", "der Alien", "die Aliens",
             "Der Alien war wichtig.", "Ich sehe den Alien.", "Ich werde mit dem Alien zufrieden sein.", "Die Bedeutung des Aliens ist gro\u00df."),
            ("Android", "der Android", "die Androiden",
             "Der Android war wichtig.", "Ich sehe den Androiden.", "Ich werde mit dem Androiden zufrieden sein.", "Die Bedeutung des Androiden ist gro\u00df."),
            ("Blaster", "der Blaster", "die Blaster",
             "Der Blaster war wichtig.", "Ich sehe den Blaster.", "Ich werde mit dem Blaster zufrieden sein.", "Die Bedeutung des Blasters ist gro\u00df."),
            ("Clone", "der Klon", "die Klone",
             "Der Klon war wichtig.", "Ich sehe den Klon.", "Ich werde mit dem Klon zufrieden sein.", "Die Bedeutung des Klons ist gro\u00df."),
            ("Colony", "die Kolonie", "die Kolonien",
             "Die Kolonie war wichtig.", "Ich sehe die Kolonie.", "Ich werde mit der Kolonie zufrieden sein.", "Die Bedeutung der Kolonie ist gro\u00df."),
            ("Cyborg", "der Cyborg", "die Cyborgs",
             "Der Cyborg war wichtig.", "Ich sehe den Cyborg.", "Ich werde mit dem Cyborg zufrieden sein.", "Die Bedeutung des Cyborgs ist gro\u00df."),
            ("Empire", "das Imperium", "die Imperien",
             "Das Imperium war wichtig.", "Ich sehe das Imperium.", "Ich werde mit dem Imperium zufrieden sein.", "Die Bedeutung des Imperiums ist gro\u00df."),
            ("Galaxy", "die Galaxie", "die Galaxien",
             "Die Galaxie war wichtig.", "Ich sehe die Galaxie.", "Ich werde mit der Galaxie zufrieden sein.", "Die Bedeutung der Galaxie ist gro\u00df."),
            ("Hologram", "das Hologramm", "die Hologramme",
             "Das Hologramm war wichtig.", "Ich sehe das Hologramm.", "Ich werde mit dem Hologramm zufrieden sein.", "Die Bedeutung des Hologramms ist gro\u00df."),
            ("Invasion", "die Invasion", "die Invasionen",
             "Die Invasion war wichtig.", "Ich sehe die Invasion.", "Ich werde mit der Invasion zufrieden sein.", "Die Bedeutung der Invasion ist gro\u00df."),
            ("Laser", "der Laser", "die Laser",
             "Der Laser war wichtig.", "Ich sehe den Laser.", "Ich werde mit dem Laser zufrieden sein.", "Die Bedeutung des Lasers ist gro\u00df."),
            ("Mothership", "das Mutterschiff", "die Mutterschiffe",
             "Das Mutterschiff war wichtig.", "Ich sehe das Mutterschiff.", "Ich werde mit dem Mutterschiff zufrieden sein.", "Die Bedeutung des Mutterschiffes ist gro\u00df."),
            ("Planet", "der Planet", "die Planeten",
             "Der Planet war wichtig.", "Ich sehe den Planeten.", "Ich werde mit dem Planeten zufrieden sein.", "Die Bedeutung des Planeten ist gro\u00df."),
            ("Rebellion", "die Rebellion", "die Rebellionen",
             "Die Rebellion war wichtig.", "Ich sehe die Rebellion.", "Ich werde mit der Rebellion zufrieden sein.", "Die Bedeutung der Rebellion ist gro\u00df."),
            ("Robot", "der Roboter", "die Roboter",
             "Der Roboter war wichtig.", "Ich sehe den Roboter.", "Ich werde mit dem Roboter zufrieden sein.", "Die Bedeutung des Roboters ist gro\u00df."),
            ("Spaceship", "das Raumschiff", "die Raumschiffe",
             "Das Raumschiff war wichtig.", "Ich sehe das Raumschiff.", "Ich werde mit dem Raumschiff zufrieden sein.", "Die Bedeutung des Raumschiffes ist gro\u00df."),
            ("Universe", "das Universum", "die Universen",
             "Das Universum war wichtig.", "Ich sehe das Universum.", "Ich werde mit dem Universum zufrieden sein.", "Die Bedeutung des Universums ist gro\u00df."),
            ("Warp Drive", "der Warpantrieb", "die Warpantriebe",
             "Der Warpantrieb war wichtig.", "Ich sehe den Warpantrieb.", "Ich werde mit dem Warpantrieb zufrieden sein.", "Die Bedeutung des Warpantriebs ist gro\u00df."),
        ],
    },
}

HEADERS = ["English", "German", "Plural", "Past \u00b7 Nominativ", "Present \u00b7 Akkusativ", "Future \u00b7 Dativ", "Genitiv"]
COL_WIDTHS = [13, 18, 20, 26, 20, 32, 28]

FONT_NAME = "Arial"
TITLE_FONT = Font(name=FONT_NAME, size=14, bold=True)
HEADER_FONT = Font(name=FONT_NAME, size=11, bold=True)
HEADER_FILL = PatternFill(start_color="D9D9D9", end_color="D9D9D9", fill_type="solid")
CELL_FONT = Font(name=FONT_NAME, size=11)
GERMAN_FONT = Font(name=FONT_NAME, size=11, bold=True)
THIN = Side(style="thin", color="BFBFBF")
BORDER = Border(left=THIN, right=THIN, top=THIN, bottom=THIN)
WRAP = Alignment(wrap_text=True, vertical="top")
CENTER = Alignment(horizontal="center", vertical="center")

wb = openpyxl.Workbook()
wb.remove(wb.active)

for sheet_name, content in DOMAINS.items():
    ws = wb.create_sheet(title=sheet_name[:31])

    # Title row spans the full data width \u2013 nav links now live at the bottom
    ws.merge_cells(start_row=1, start_column=1, end_row=1, end_column=len(HEADERS))
    title_cell = ws.cell(row=1, column=1, value=content["title"])
    title_cell.font = TITLE_FONT
    title_cell.alignment = Alignment(horizontal="left", vertical="center")
    ws.row_dimensions[1].height = 24
    ws.append([])  # blank spacer row

    # Header row
    header_row_idx = 3
    for c, h in enumerate(HEADERS, start=1):
        cell = ws.cell(row=header_row_idx, column=c, value=h)
        cell.font = HEADER_FONT
        cell.fill = HEADER_FILL
        cell.border = BORDER
        cell.alignment = CENTER

    # Data rows (alphabetized by the English column)
    r = header_row_idx + 1
    for row_data in sorted(content["rows"], key=lambda row: row[0].lower()):
        for c, val in enumerate(row_data, start=1):
            cell = ws.cell(row=r, column=c, value=val)
            cell.border = BORDER
            cell.alignment = WRAP
            cell.font = GERMAN_FONT if c in (2, 3) else CELL_FONT
        r += 1

    # Footer nav links, bottom-left, below a blank spacer row
    footer_row = r + 1
    write_footer_nav(ws, footer_row, reference_footer_links())

    # Column widths
    for c, w in enumerate(COL_WIDTHS, start=1):
        ws.column_dimensions[get_column_letter(c)].width = w

    ws.freeze_panes = f"A{header_row_idx + 1}"
    ws.sheet_view.showGridLines = False

# Table of contents sheet, placed first
toc = wb.create_sheet(title="Contents", index=0)
toc.merge_cells("A1:B1")
toc_title = toc.cell(row=1, column=1, value="German Vocabulary by Domain \u2013 Deutscher Wortschatz nach Themen")
toc_title.font = Font(name=FONT_NAME, size=14, bold=True)
toc.row_dimensions[1].height = 26

toc.cell(row=3, column=1, value="Domain").font = HEADER_FONT
toc.cell(row=3, column=1).fill = HEADER_FILL
toc.cell(row=3, column=1).border = BORDER
toc.cell(row=3, column=2, value="German Title").font = HEADER_FONT
toc.cell(row=3, column=2).fill = HEADER_FILL
toc.cell(row=3, column=2).border = BORDER

r = 4
for sheet_name, content in DOMAINS.items():
    target = sheet_name[:31]
    c1 = toc.cell(row=r, column=1, value=sheet_name)
    c1.font = CELL_FONT
    c1.border = BORDER
    c1.hyperlink = internal_link(target, display=sheet_name)
    c1.style = "Hyperlink"
    c2 = toc.cell(row=r, column=2, value=content["title"])
    c2.font = CELL_FONT
    c2.border = BORDER
    c2.hyperlink = internal_link(target, display=content["title"])
    c2.style = "Hyperlink"
    r += 1

toc.column_dimensions["A"].width = 24
toc.column_dimensions["B"].width = 44
toc.sheet_view.showGridLines = False

# Blank spacer row, then distinctly-styled links down to each reference sheet
TOC_REFERENCE_ROWS = [
    ("Grammar", "\U0001F4D6 Grammar \u2013 Die vier F\u00e4lle (cases at a glance)"),
    ("Subjunctive", "\U0001F4AD Subjunctive \u2013 Konjunktiv I & II (wishes, hypotheticals, reported speech)"),
    ("Colloquial and Slang", "\U0001F4AC Colloquial and Slang \u2013 contractions, particles, everyday expressions"),
    ("Time Tenses", "\U0001F550 Time Tenses \u2013 all six tenses, one verb fully conjugated"),
    ("Irregular Verbs", "\U0001F500 Irregular Verbs \u2013 principal parts for 30 common strong verbs"),
]
toc_ref_row = r + 1
for target, label in TOC_REFERENCE_ROWS:
    toc.merge_cells(start_row=toc_ref_row, start_column=1, end_row=toc_ref_row, end_column=2)
    cell = toc.cell(row=toc_ref_row, column=1, value=label)
    cell.hyperlink = internal_link(target, display=label)
    cell.style = "Hyperlink"
    cell.font = Font(name=FONT_NAME, size=12, bold=True, underline="single", color="0563C1")
    cell.fill = PatternFill(start_color="FCE9C6", end_color="FCE9C6", fill_type="solid")
    cell.border = BORDER
    cell.alignment = Alignment(horizontal="left", vertical="center")
    toc.row_dimensions[toc_ref_row].height = 22
    toc_ref_row += 1

# Grammar reference sheet: the four cases across question words, definite
# articles, and indefinite articles. Placed last (no explicit index), so it
# lands as the final tab. Every domain sheet's corner nav links here.
gram = wb.create_sheet(title="Grammar")
gram.merge_cells(start_row=1, start_column=1, end_row=1, end_column=5)
gram_title = gram.cell(row=1, column=1, value="Die vier F\u00e4lle \u2013 German Cases at a Glance")
gram_title.font = TITLE_FONT
gram_title.alignment = Alignment(horizontal="left", vertical="center")
gram.row_dimensions[1].height = 24

def ref_section(ws, row, text, span):
    ws.merge_cells(start_row=row, start_column=1, end_row=row, end_column=span)
    cell = ws.cell(row=row, column=1, value=text)
    cell.font = Font(name=FONT_NAME, size=12, bold=True)
    cell.alignment = Alignment(horizontal="left", vertical="center")
    ws.row_dimensions[row].height = 20

def ref_header_row(ws, row, labels):
    for c, h in enumerate(labels, start=1):
        cell = ws.cell(row=row, column=c, value=h)
        cell.font = HEADER_FONT
        cell.fill = HEADER_FILL
        cell.border = BORDER
        cell.alignment = CENTER

def ref_data_row(ws, row, values, bold_first=True):
    for c, v in enumerate(values, start=1):
        cell = ws.cell(row=row, column=c, value=v)
        cell.border = BORDER
        cell.alignment = WRAP if c > 1 else Alignment(vertical="top")
        cell.font = GERMAN_FONT if (c == 1 and bold_first) else CELL_FONT

def gram_section(row, text, span):
    ref_section(gram, row, text, span)

def gram_header_row(row, labels):
    ref_header_row(gram, row, labels)

def gram_data_row(row, values, bold_first=True):
    ref_data_row(gram, row, values, bold_first)

# Section 1: question words + one example per case
gram_section(3, "Wer? Was? Wem? Wessen? \u2013 one question word and example per case", 3)
gram_header_row(4, ["Case", "Question word(s)", "Example"])
gram_data_row(5, ["Nominativ", "wer? / was?", "Der Mann schl\u00e4ft."])
gram_data_row(6, ["Akkusativ", "wen? / was?", "Ich sehe den Mann."])
gram_data_row(7, ["Dativ", "wem?", "Ich gebe dem Mann ein Buch."])
gram_data_row(8, ["Genitiv", "wessen?", "Das Buch des Mannes."])

# Section 2: definite articles (der / die / das)
gram_section(10, "Definite Articles \u2013 der \u00b7 die \u00b7 das", 5)
gram_header_row(11, ["", "Nominativ", "Akkusativ", "Dativ", "Genitiv"])
gram_data_row(12, ["Masculine (der)", "der", "den", "dem", "des"])
gram_data_row(13, ["Feminine (die)", "die", "die", "der", "der"])
gram_data_row(14, ["Neuter (das)", "das", "das", "dem", "des"])
gram_data_row(15, ["Plural (die)", "die", "die", "den", "der"])

# Section 3: indefinite articles (ein / eine / ein) -- no plural form in German
gram_section(17, "Indefinite Articles \u2013 ein \u00b7 eine \u00b7 ein", 5)
gram_header_row(18, ["", "Nominativ", "Akkusativ", "Dativ", "Genitiv"])
gram_data_row(19, ["Masculine (ein)", "ein", "einen", "einem", "eines"])
gram_data_row(20, ["Feminine (eine)", "eine", "eine", "einer", "einer"])
gram_data_row(21, ["Neuter (ein)", "ein", "ein", "einem", "eines"])

note = gram.cell(row=23, column=1,
                  value="Tip: the article usually carries the case \u2013 watch how der becomes den, dem, des.")
note.font = Font(name=FONT_NAME, size=10, italic=True, color="595959")
gram.merge_cells(start_row=23, start_column=1, end_row=23, end_column=5)

write_footer_nav(gram, 25, reference_footer_links("Grammar"))

for c, w in enumerate([18, 18, 32, 14, 32], start=1):
    gram.column_dimensions[get_column_letter(c)].width = w
gram.sheet_view.showGridLines = False

# Subjunctive reference sheet: Konjunktiv II (wishes, hypotheticals, polite
# requests -- the everyday one) and Konjunktiv I (reported speech).
subj = wb.create_sheet(title="Subjunctive")
subj.merge_cells(start_row=1, start_column=1, end_row=1, end_column=4)
subj_title = subj.cell(row=1, column=1, value="Konjunktiv \u2013 The Subjunctive at a Glance")
subj_title.font = TITLE_FONT
subj_title.alignment = Alignment(horizontal="left", vertical="center")
subj.row_dimensions[1].height = 24

ref_section(subj, 3, "Konjunktiv II \u2013 wishes, hypotheticals, polite requests (the everyday one)", 4)
ref_header_row(subj, 4, ["Verb", "ich", "du", "er/sie/es"])
ref_data_row(subj, 5, ["sein (to be)", "w\u00e4re", "w\u00e4rst", "w\u00e4re"])
ref_data_row(subj, 6, ["haben (to have)", "h\u00e4tte", "h\u00e4ttest", "h\u00e4tte"])
ref_data_row(subj, 7, ["werden (will)", "w\u00fcrde", "w\u00fcrdest", "w\u00fcrde"])
ref_data_row(subj, 8, ["k\u00f6nnen (can)", "k\u00f6nnte", "k\u00f6nntest", "k\u00f6nnte"])
ref_data_row(subj, 9, ["m\u00f6gen (to like)", "m\u00f6chte", "m\u00f6chtest", "m\u00f6chte"])

ref_section(subj, 11, "Konjunktiv II in use", 3)
ref_header_row(subj, 12, ["Use", "Example", "English"])
ref_data_row(subj, 13, ["Wish", "Ich w\u00e4re gern reich.", "I wish I were rich."])
ref_data_row(subj, 14, ["Polite request", "K\u00f6nnten Sie mir helfen?", "Could you help me?"])
ref_data_row(subj, 15, ["Hypothetical", "Wenn ich Zeit h\u00e4tte, w\u00fcrde ich kommen.", "If I had time, I would come."])
ref_data_row(subj, 16, ["\u201eWould\u201c (w\u00fcrde + infinitive)", "Ich w\u00fcrde das nicht sagen.", "I wouldn't say that."])

ref_section(subj, 18, "Konjunktiv I \u2013 reported speech (indirekte Rede)", 3)
ref_header_row(subj, 19, ["Verb", "er/sie (Konj. I)", "In reported speech"])
ref_data_row(subj, 20, ["sein", "sei", "Er sagte, er sei m\u00fcde."])
ref_data_row(subj, 21, ["haben", "habe", "Sie sagte, sie habe keine Zeit."])
ref_data_row(subj, 22, ["werden", "werde", "Er sagte, er werde bald kommen."])
ref_data_row(subj, 23, ["k\u00f6nnen", "k\u00f6nne", "Sie sagte, sie k\u00f6nne nicht kommen."])
ref_data_row(subj, 24, ["gehen", "gehe", "Er sagte, er gehe nach Hause."])

subj_note = subj.cell(row=26, column=1,
                       value="Tip: Konjunktiv II is for the unreal (wishes, hypotheses); Konjunktiv I mainly reports someone else's words.")
subj_note.font = Font(name=FONT_NAME, size=10, italic=True, color="595959")
subj.merge_cells(start_row=26, start_column=1, end_row=26, end_column=4)

write_footer_nav(subj, 28, reference_footer_links("Subjunctive"))

for c, w in enumerate([22, 34, 34, 14], start=1):
    subj.column_dimensions[get_column_letter(c)].width = w
subj.sheet_view.showGridLines = False

# Colloquial and Slang reference sheet: contractions, modal particles, and
# common casual expressions -- the everyday spoken register the textbook
# sentences elsewhere in this workbook mostly don't show.
coll = wb.create_sheet(title="Colloquial and Slang")
coll.merge_cells(start_row=1, start_column=1, end_row=1, end_column=3)
coll_title = coll.cell(row=1, column=1, value="Colloquial German \u2013 Everyday Speech at a Glance")
coll_title.font = TITLE_FONT
coll_title.alignment = Alignment(horizontal="left", vertical="center")
coll.row_dimensions[1].height = 24

ref_section(coll, 3, "Everyday Contractions \u2013 preposition + article", 3)
ref_header_row(coll, 4, ["Full form", "Contraction", "Example"])
ref_data_row(coll, 5, ["in dem", "im", "Ich bin im Garten."])
ref_data_row(coll, 6, ["in das", "ins", "Ich gehe ins Haus."])
ref_data_row(coll, 7, ["an dem", "am", "Er wartet am Bahnhof."])
ref_data_row(coll, 8, ["an das", "ans", "Sie geht ans Fenster."])
ref_data_row(coll, 9, ["zu dem", "zum", "Wir fahren zum Markt."])
ref_data_row(coll, 10, ["zu der", "zur", "Sie geht zur Kirche."])
ref_data_row(coll, 11, ["von dem", "vom", "Ich komme vom Markt."])
ref_data_row(coll, 12, ["bei dem", "beim", "Ich bin beim Arzt."])

ref_section(coll, 14, "Modal Particles \u2013 flavor words with no direct translation", 3)
ref_header_row(coll, 15, ["Particle", "Rough sense", "Example"])
ref_data_row(coll, 16, ["mal", "softens a request", "Komm mal her!"])
ref_data_row(coll, 17, ["doch", "emphasis / reassurance", "Das ist doch klar!"])
ref_data_row(coll, 18, ["halt", "just (resigned)", "Das ist halt so."])
ref_data_row(coll, 19, ["eben", "precisely / just", "Genau, das meine ich eben."])
ref_data_row(coll, 20, ["ja", "shared assumption", "Das ist ja toll!"])
ref_data_row(coll, 21, ["na", "casual opener, \u201ewell\u201c", "Na, wie geht's?"])

ref_section(coll, 23, "Common Casual Expressions", 2)
ref_header_row(coll, 24, ["Expression", "Meaning"])
ref_data_row(coll, 25, ["Alles klar", "All good / understood"])
ref_data_row(coll, 26, ["Kein Ding", "No big deal"])
ref_data_row(coll, 27, ["Ich hab keinen Bock", "I don't feel like it"])
ref_data_row(coll, 28, ["Quatsch!", "Nonsense!"])
ref_data_row(coll, 29, ["Mach's gut", "Take care (casual goodbye)"])
ref_data_row(coll, 30, ["Was geht?", "What's up?"])
ref_data_row(coll, 31, ["Auf jeden Fall", "Definitely / for sure"])
ref_data_row(coll, 32, ["Krass!", "Wow! / intense!"])

coll_note = coll.cell(row=34, column=1,
                       value="Tip: these are for listening and casual speaking \u2013 stick to full forms in formal writing.")
coll_note.font = Font(name=FONT_NAME, size=10, italic=True, color="595959")
coll.merge_cells(start_row=34, start_column=1, end_row=34, end_column=3)

write_footer_nav(coll, 36, reference_footer_links("Colloquial and Slang"))

for c, w in enumerate([24, 26, 32], start=1):
    coll.column_dimensions[get_column_letter(c)].width = w
coll.sheet_view.showGridLines = False

# Time Tenses reference sheet: the six tenses overview, one verb (machen)
# fully conjugated in the two synthetic tenses, a look at how the four
# compound tenses only conjugate their auxiliary, and the haben/sein choice.
tense = wb.create_sheet(title="Time Tenses")
tense.merge_cells(start_row=1, start_column=1, end_row=1, end_column=4)
tense_title = tense.cell(row=1, column=1, value="Die sechs Zeiten \u2013 The Six Tenses at a Glance")
tense_title.font = TITLE_FONT
tense_title.alignment = Alignment(horizontal="left", vertical="center")
tense.row_dimensions[1].height = 24

ref_section(tense, 3, "Overview \u2013 one action, six tenses (machen = to do/make)", 4)
ref_header_row(tense, 4, ["Tense", "Formation", "Example", "English"])
ref_data_row(tense, 5, ["Pr\u00e4sens (Present)", "stem + present endings", "Ich mache.", "I do / I am doing."])
ref_data_row(tense, 6, ["Pr\u00e4teritum (Simple Past)", "stem + -te (weak verbs)", "Ich machte.", "I did."])
ref_data_row(tense, 7, ["Perfekt (Present Perfect)", "haben/sein + past participle", "Ich habe gemacht.", "I have done / I did."])
ref_data_row(tense, 8, ["Plusquamperfekt (Past Perfect)", "hatte/war + past participle", "Ich hatte gemacht.", "I had done."])
ref_data_row(tense, 9, ["Futur I (Future)", "werden + infinitive", "Ich werde machen.", "I will do."])
ref_data_row(tense, 10, ["Futur II (Future Perfect)", "werden + past participle + haben/sein", "Ich werde gemacht haben.", "I will have done."])

ref_section(tense, 12, "machen \u2013 Pr\u00e4sens", 2)
ref_header_row(tense, 13, ["Person", "Form"])
ref_data_row(tense, 14, ["ich", "mache"])
ref_data_row(tense, 15, ["du", "machst"])
ref_data_row(tense, 16, ["er/sie/es", "macht"])
ref_data_row(tense, 17, ["wir", "machen"])
ref_data_row(tense, 18, ["ihr", "macht"])
ref_data_row(tense, 19, ["sie/Sie", "machen"])

ref_section(tense, 21, "machen \u2013 Pr\u00e4teritum", 2)
ref_header_row(tense, 22, ["Person", "Form"])
ref_data_row(tense, 23, ["ich", "machte"])
ref_data_row(tense, 24, ["du", "machtest"])
ref_data_row(tense, 25, ["er/sie/es", "machte"])
ref_data_row(tense, 26, ["wir", "machten"])
ref_data_row(tense, 27, ["ihr", "machtet"])
ref_data_row(tense, 28, ["sie/Sie", "machten"])

ref_section(tense, 30, "Compound tenses \u2013 only the auxiliary conjugates", 3)
ref_header_row(tense, 31, ["Tense", "ich", "er/sie/es"])
ref_data_row(tense, 32, ["Perfekt", "habe gemacht", "hat gemacht"])
ref_data_row(tense, 33, ["Plusquamperfekt", "hatte gemacht", "hatte gemacht"])
ref_data_row(tense, 34, ["Futur I", "werde machen", "wird machen"])
ref_data_row(tense, 35, ["Futur II", "werde gemacht haben", "wird gemacht haben"])

ref_section(tense, 37, "haben or sein? \u2013 choosing the Perfekt/Plusquamperfekt auxiliary", 3)
ref_header_row(tense, 38, ["Rule", "Example", "English"])
ref_data_row(tense, 39, ["Most verbs \u2192 haben", "Ich habe gearbeitet.", "I have worked."])
ref_data_row(tense, 40, ["Motion to a place \u2192 sein", "Ich bin gegangen.", "I have gone / walked."])
ref_data_row(tense, 41, ["Change of state \u2192 sein", "Ich bin aufgewacht.", "I woke up."])
ref_data_row(tense, 42, ["sein / bleiben / werden \u2192 sein", "Ich bin gewesen.", "I have been."])

tense_note = tense.cell(row=44, column=1,
                         value="Tip: in everyday speech, Perfekt \u2013 not Pr\u00e4teritum \u2013 is how Germans usually talk about the past.")
tense_note.font = Font(name=FONT_NAME, size=10, italic=True, color="595959")
tense.merge_cells(start_row=44, start_column=1, end_row=44, end_column=4)

write_footer_nav(tense, 46, reference_footer_links("Time Tenses"))

for c, w in enumerate([30, 34, 26, 20], start=1):
    tense.column_dimensions[get_column_letter(c)].width = w
tense.sheet_view.showGridLines = False

# Irregular Verbs reference sheet: principal parts for the strong/irregular
# verbs that don't follow the weak -te/-t pattern, alphabetized for lookup.
irreg = wb.create_sheet(title="Irregular Verbs")
irreg.merge_cells(start_row=1, start_column=1, end_row=1, end_column=5)
irreg_title = irreg.cell(row=1, column=1, value="Unregelm\u00e4\u00dfige Verben \u2013 Irregular Verbs at a Glance")
irreg_title.font = TITLE_FONT
irreg_title.alignment = Alignment(horizontal="left", vertical="center")
irreg.row_dimensions[1].height = 24

ref_section(irreg, 3, "Principal parts \u2013 infinitive, 3rd person present, Pr\u00e4teritum, Perfekt", 5)
ref_header_row(irreg, 4, ["Infinitive", "3rd person present", "Pr\u00e4teritum", "Perfekt", "English"])
IRREGULAR_VERBS = [
    ["beginnen", "beginnt", "begann", "hat begonnen", "to begin"],
    ["bleiben", "bleibt", "blieb", "ist geblieben", "to stay"],
    ["bringen", "bringt", "brachte", "hat gebracht", "to bring"],
    ["denken", "denkt", "dachte", "hat gedacht", "to think"],
    ["d\u00fcrfen", "darf", "durfte", "hat gedurft", "may / to be allowed"],
    ["essen", "isst", "a\u00df", "hat gegessen", "to eat"],
    ["fahren", "f\u00e4hrt", "fuhr", "ist gefahren", "to drive / go"],
    ["finden", "findet", "fand", "hat gefunden", "to find"],
    ["geben", "gibt", "gab", "hat gegeben", "to give"],
    ["gehen", "geht", "ging", "ist gegangen", "to go"],
    ["haben", "hat", "hatte", "hat gehabt", "to have"],
    ["helfen", "hilft", "half", "hat geholfen", "to help"],
    ["kommen", "kommt", "kam", "ist gekommen", "to come"],
    ["k\u00f6nnen", "kann", "konnte", "hat gekonnt", "can / to be able"],
    ["laufen", "l\u00e4uft", "lief", "ist gelaufen", "to run"],
    ["lesen", "liest", "las", "hat gelesen", "to read"],
    ["m\u00f6gen", "mag", "mochte", "hat gemocht", "to like"],
    ["m\u00fcssen", "muss", "musste", "hat gemusst", "must"],
    ["nehmen", "nimmt", "nahm", "hat genommen", "to take"],
    ["schlafen", "schl\u00e4ft", "schlief", "hat geschlafen", "to sleep"],
    ["schreiben", "schreibt", "schrieb", "hat geschrieben", "to write"],
    ["sehen", "sieht", "sah", "hat gesehen", "to see"],
    ["sein", "ist", "war", "ist gewesen", "to be"],
    ["sprechen", "spricht", "sprach", "hat gesprochen", "to speak"],
    ["tragen", "tr\u00e4gt", "trug", "hat getragen", "to carry / wear"],
    ["trinken", "trinkt", "trank", "hat getrunken", "to drink"],
    ["tun", "tut", "tat", "hat getan", "to do"],
    ["werden", "wird", "wurde", "ist geworden", "to become"],
    ["wissen", "wei\u00df", "wusste", "hat gewusst", "to know"],
    ["wollen", "will", "wollte", "hat gewollt", "to want"],
]
for i, verb_row in enumerate(IRREGULAR_VERBS):
    ref_data_row(irreg, 5 + i, verb_row)

irreg_note_row = 5 + len(IRREGULAR_VERBS) + 1
irreg_note = irreg.cell(row=irreg_note_row, column=1,
                         value="Tip: weak (regular) verbs form Pr\u00e4teritum with -te and Perfekt with ge-...-t (e.g. machen \u2192 machte \u2192 gemacht). These don't.")
irreg_note.font = Font(name=FONT_NAME, size=10, italic=True, color="595959")
irreg.merge_cells(start_row=irreg_note_row, start_column=1, end_row=irreg_note_row, end_column=5)

write_footer_nav(irreg, irreg_note_row + 2, reference_footer_links("Irregular Verbs"))

for c, w in enumerate([14, 16, 12, 20, 24], start=1):
    irreg.column_dimensions[get_column_letter(c)].width = w
irreg.sheet_view.showGridLines = False

out_path = sys.argv[1] if len(sys.argv) > 1 else os.path.join(
    os.environ.get("VOCAB_OUT_DIR", os.path.expanduser("~/Documents")),
    "german_vocabulary_by_domain.xlsx",
)
out_path = os.path.abspath(os.path.expanduser(out_path))
os.makedirs(os.path.dirname(out_path), exist_ok=True)
wb.save(out_path)

home = os.path.expanduser("~")
display_path = "~" + out_path[len(home):] if out_path.startswith(home) else out_path
print(f"Saved: {display_path}")
print("Sheets:", wb.sheetnames)
