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
            ("Living room", "das Wohnzimmer", "die Wohnzimmer",
             "Das Wohnzimmer war wichtig.", "Ich sehe das Wohnzimmer.", "Ich werde mit dem Wohnzimmer zufrieden sein.", "Die Bedeutung des Wohnzimmers ist gro\u00df."),
            ("Roof", "das Dach", "die D\u00e4cher",
             "Das Dach war wichtig.", "Ich sehe das Dach.", "Ich werde mit dem Dach zufrieden sein.", "Die Bedeutung des Daches ist gro\u00df."),
            ("Table", "der Tisch", "die Tische",
             "Der Tisch war wichtig.", "Ich sehe den Tisch.", "Ich werde mit dem Tisch zufrieden sein.", "Die Bedeutung des Tisches ist gro\u00df."),
            ("Window", "das Fenster", "die Fenster",
             "Das Fenster war wichtig.", "Ich sehe das Fenster.", "Ich werde mit dem Fenster zufrieden sein.", "Die Bedeutung des Fensters ist gro\u00df."),
        ],
    },
    "Nature": {
        "title": "Nature \u2013 Die Natur",
        "rows": [
            ("Animal", "das Tier", "die Tiere",
             "Das Tier war wichtig.", "Ich sehe das Tier.", "Ich werde mit dem Tier zufrieden sein.", "Die Bedeutung des Tieres ist gro\u00df."),
            ("Flower", "die Blume", "die Blumen",
             "Die Blume war wichtig.", "Ich sehe die Blume.", "Ich werde mit der Blume zufrieden sein.", "Die Bedeutung der Blume ist gro\u00df."),
            ("Forest", "der Wald", "die W\u00e4lder",
             "Der Wald war wichtig.", "Ich sehe den Wald.", "Ich werde mit dem Wald zufrieden sein.", "Die Bedeutung des Waldes ist gro\u00df."),
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
            ("Star", "der Stern", "die Sterne",
             "Der Stern war wichtig.", "Ich sehe den Stern.", "Ich werde mit dem Stern zufrieden sein.", "Die Bedeutung des Sterns ist gro\u00df."),
            ("Sun", "die Sonne", "die Sonnen",
             "Die Sonne war wichtig.", "Ich sehe die Sonne.", "Ich werde mit der Sonne zufrieden sein.", "Die Bedeutung der Sonne ist gro\u00df."),
            ("Tree", "der Baum", "die B\u00e4ume",
             "Der Baum war wichtig.", "Ich sehe den Baum.", "Ich werde mit dem Baum zufrieden sein.", "Die Bedeutung des Baumes ist gro\u00df."),
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
            ("Library", "die Bibliothek", "die Bibliotheken",
             "Die Bibliothek war wichtig.", "Ich sehe die Bibliothek.", "Ich werde mit der Bibliothek zufrieden sein.", "Die Bedeutung der Bibliothek ist gro\u00df."),
            ("Market", "der Markt", "die M\u00e4rkte",
             "Der Markt war wichtig.", "Ich sehe den Markt.", "Ich werde mit dem Markt zufrieden sein.", "Die Bedeutung des Marktes ist gro\u00df."),
            ("Museum", "das Museum", "die Museen",
             "Das Museum war wichtig.", "Ich sehe das Museum.", "Ich werde mit dem Museum zufrieden sein.", "Die Bedeutung des Museums ist gro\u00df."),
            ("Neighborhood", "die Nachbarschaft", "die Nachbarschaften",
             "Die Nachbarschaft war wichtig.", "Ich sehe die Nachbarschaft.", "Ich werde mit der Nachbarschaft zufrieden sein.", "Die Bedeutung der Nachbarschaft ist gro\u00df."),
            ("Shop", "der Laden", "die L\u00e4den",
             "Der Laden war wichtig.", "Ich sehe den Laden.", "Ich werde mit dem Laden zufrieden sein.", "Die Bedeutung des Ladens ist gro\u00df."),
            ("Square", "der Platz", "die Pl\u00e4tze",
             "Der Platz war wichtig.", "Ich sehe den Platz.", "Ich werde mit dem Platz zufrieden sein.", "Die Bedeutung des Platzes ist gro\u00df."),
            ("Street", "die Stra\u00dfe", "die Stra\u00dfen",
             "Die Stra\u00dfe war wichtig.", "Ich sehe die Stra\u00dfe.", "Ich werde mit der Stra\u00dfe zufrieden sein.", "Die Bedeutung der Stra\u00dfe ist gro\u00df."),
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
            ("Harvest", "die Ernte", "die Ernten",
             "Die Ernte war wichtig.", "Ich sehe die Ernte.", "Ich werde mit der Ernte zufrieden sein.", "Die Bedeutung der Ernte ist gro\u00df."),
            ("Horse", "das Pferd", "die Pferde",
             "Das Pferd war wichtig.", "Ich sehe das Pferd.", "Ich werde mit dem Pferd zufrieden sein.", "Die Bedeutung des Pferdes ist gro\u00df."),
            ("Meadow", "die Wiese", "die Wiesen",
             "Die Wiese war wichtig.", "Ich sehe die Wiese.", "Ich werde mit der Wiese zufrieden sein.", "Die Bedeutung der Wiese ist gro\u00df."),
            ("Village", "das Dorf", "die D\u00f6rfer",
             "Das Dorf war wichtig.", "Ich sehe das Dorf.", "Ich werde mit dem Dorf zufrieden sein.", "Die Bedeutung des Dorfes ist gro\u00df."),
            ("Well", "der Brunnen", "die Brunnen",
             "Der Brunnen war wichtig.", "Ich sehe den Brunnen.", "Ich werde mit dem Brunnen zufrieden sein.", "Die Bedeutung des Brunnens ist gro\u00df."),
        ],
    },
    "Government": {
        "title": "Government \u2013 Die Regierung",
        "rows": [
            ("Citizen", "der B\u00fcrger", "die B\u00fcrger",
             "Der B\u00fcrger war wichtig.", "Ich sehe den B\u00fcrger.", "Ich werde mit dem B\u00fcrger zufrieden sein.", "Die Bedeutung des B\u00fcrgers ist gro\u00df."),
            ("Constitution", "die Verfassung", "die Verfassungen",
             "Die Verfassung war wichtig.", "Ich sehe die Verfassung.", "Ich werde mit der Verfassung zufrieden sein.", "Die Bedeutung der Verfassung ist gro\u00df."),
            ("Court", "das Gericht", "die Gerichte",
             "Das Gericht war wichtig.", "Ich sehe das Gericht.", "Ich werde mit dem Gericht zufrieden sein.", "Die Bedeutung des Gerichts ist gro\u00df."),
            ("Election", "die Wahl", "die Wahlen",
             "Die Wahl war wichtig.", "Ich sehe die Wahl.", "Ich werde mit der Wahl zufrieden sein.", "Die Bedeutung der Wahl ist gro\u00df."),
            ("Law", "das Gesetz", "die Gesetze",
             "Das Gesetz war wichtig.", "Ich sehe das Gesetz.", "Ich werde mit dem Gesetz zufrieden sein.", "Die Bedeutung des Gesetzes ist gro\u00df."),
            ("Minister", "der Minister", "die Minister",
             "Der Minister war wichtig.", "Ich sehe den Minister.", "Ich werde mit dem Minister zufrieden sein.", "Die Bedeutung des Ministers ist gro\u00df."),
            ("Nation", "die Nation", "die Nationen",
             "Die Nation war wichtig.", "Ich sehe die Nation.", "Ich werde mit der Nation zufrieden sein.", "Die Bedeutung der Nation ist gro\u00df."),
            ("Parliament", "das Parlament", "die Parlamente",
             "Das Parlament war wichtig.", "Ich sehe das Parlament.", "Ich werde mit dem Parlament zufrieden sein.", "Die Bedeutung des Parlaments ist gro\u00df."),
            ("President", "der Pr\u00e4sident", "die Pr\u00e4sidenten",
             "Der Pr\u00e4sident war wichtig.", "Ich sehe den Pr\u00e4sidenten.", "Ich werde mit dem Pr\u00e4sidenten zufrieden sein.", "Die Bedeutung des Pr\u00e4sidenten ist gro\u00df."),
            ("Rights", "das Recht", "die Rechte",
             "Das Recht war wichtig.", "Ich sehe das Recht.", "Ich werde mit dem Recht zufrieden sein.", "Die Bedeutung des Rechts ist gro\u00df."),
            ("State", "der Staat", "die Staaten",
             "Der Staat war wichtig.", "Ich sehe den Staat.", "Ich werde mit dem Staat zufrieden sein.", "Die Bedeutung des Staates ist gro\u00df."),
            ("Vote", "die Stimme", "die Stimmen",
             "Die Stimme war wichtig.", "Ich sehe die Stimme.", "Ich werde mit der Stimme zufrieden sein.", "Die Bedeutung der Stimme ist gro\u00df."),
        ],
    },
    "Theology": {
        "title": "Theology \u2013 Die Theologie",
        "rows": [
            ("Church (body)", "die Kirche", "die Kirchen",
             "Die Kirche war wichtig.", "Ich sehe die Kirche.", "Ich werde mit der Kirche zufrieden sein.", "Die Bedeutung der Kirche ist gro\u00df."),
            ("Faith", "der Glaube", "\u2014",
             "Der Glaube war wichtig.", "Ich sehe den Glauben.", "Ich werde mit dem Glauben zufrieden sein.", "Die Bedeutung des Glaubens ist gro\u00df."),
            ("God", "Gott", "\u2014",
             "Gott war treu.", "Ich liebe Gott von ganzem Herzen.", "Ich werde Gott vertrauen.", "Gottes Wille geschehe."),
            ("Grace", "die Gnade", "die Gnaden",
             "Die Gnade war wichtig.", "Ich sehe die Gnade.", "Ich werde mit der Gnade zufrieden sein.", "Die Bedeutung der Gnade ist gro\u00df."),
            ("Prayer", "das Gebet", "die Gebete",
             "Das Gebet war wichtig.", "Ich sehe das Gebet.", "Ich werde mit dem Gebet zufrieden sein.", "Die Bedeutung des Gebets ist gro\u00df."),
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
        ],
    },
    "Philosophy": {
        "title": "Philosophy \u2013 Die Philosophie",
        "rows": [
            ("Being", "das Sein", "\u2014",
             "Das Sein war wichtig.", "Ich sehe das Sein.", "Ich werde mit dem Sein zufrieden sein.", "Die Bedeutung des Seins ist gro\u00df."),
            ("Doubt", "der Zweifel", "die Zweifel",
             "Der Zweifel war wichtig.", "Ich sehe den Zweifel.", "Ich werde mit dem Zweifel zufrieden sein.", "Die Bedeutung des Zweifels ist gro\u00df."),
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
            ("Mind", "der Verstand", "\u2014",
             "Der Verstand war wichtig.", "Ich sehe den Verstand.", "Ich werde mit dem Verstand zufrieden sein.", "Die Bedeutung des Verstandes ist gro\u00df."),
            ("Reason", "die Vernunft", "\u2014",
             "Die Vernunft war wichtig.", "Ich sehe die Vernunft.", "Ich werde mit der Vernunft zufrieden sein.", "Die Bedeutung der Vernunft ist gro\u00df."),
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
            ("Army", "die Armee", "die Armeen",
             "Die Armee war wichtig.", "Ich sehe die Armee.", "Ich werde mit der Armee zufrieden sein.", "Die Bedeutung der Armee ist gro\u00df."),
            ("Battle", "die Schlacht", "die Schlachten",
             "Die Schlacht war wichtig.", "Ich sehe die Schlacht.", "Ich werde mit der Schlacht zufrieden sein.", "Die Bedeutung der Schlacht ist gro\u00df."),
            ("Defeat", "die Niederlage", "die Niederlagen",
             "Die Niederlage war wichtig.", "Ich sehe die Niederlage.", "Ich werde mit der Niederlage zufrieden sein.", "Die Bedeutung der Niederlage ist gro\u00df."),
            ("Fortress", "die Festung", "die Festungen",
             "Die Festung war wichtig.", "Ich sehe die Festung.", "Ich werde mit der Festung zufrieden sein.", "Die Bedeutung der Festung ist gro\u00df."),
            ("General", "der General", "die Gener\u00e4le",
             "Der General war wichtig.", "Ich sehe den General.", "Ich werde mit dem General zufrieden sein.", "Die Bedeutung des Generals ist gro\u00df."),
            ("Officer", "der Offizier", "die Offiziere",
             "Der Offizier war wichtig.", "Ich sehe den Offizier.", "Ich werde mit dem Offizier zufrieden sein.", "Die Bedeutung des Offiziers ist gro\u00df."),
            ("Peace", "der Frieden", "\u2014",
             "Der Frieden war wichtig.", "Ich sehe den Frieden.", "Ich werde mit dem Frieden zufrieden sein.", "Die Bedeutung des Friedens ist gro\u00df."),
            ("Soldier", "der Soldat", "die Soldaten",
             "Der Soldat war wichtig.", "Ich sehe den Soldaten.", "Ich werde mit dem Soldaten zufrieden sein.", "Die Bedeutung des Soldaten ist gro\u00df."),
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
            ("Language", "die Sprache", "die Sprachen",
             "Die Sprache war wichtig.", "Ich sehe die Sprache.", "Ich werde mit der Sprache zufrieden sein.", "Die Bedeutung der Sprache ist gro\u00df."),
            ("Music", "die Musik", "\u2014",
             "Die Musik war wichtig.", "Ich sehe die Musik.", "Ich werde mit der Musik zufrieden sein.", "Die Bedeutung der Musik ist gro\u00df."),
            ("Painting", "das Gem\u00e4lde", "die Gem\u00e4lde",
             "Das Gem\u00e4lde war wichtig.", "Ich sehe das Gem\u00e4lde.", "Ich werde mit dem Gem\u00e4lde zufrieden sein.", "Die Bedeutung des Gem\u00e4ldes ist gro\u00df."),
            ("Poem", "das Gedicht", "die Gedichte",
             "Das Gedicht war wichtig.", "Ich sehe das Gedicht.", "Ich werde mit dem Gedicht zufrieden sein.", "Die Bedeutung des Gedichts ist gro\u00df."),
            ("Poet", "der Dichter", "die Dichter",
             "Der Dichter war wichtig.", "Ich sehe den Dichter.", "Ich werde mit dem Dichter zufrieden sein.", "Die Bedeutung des Dichters ist gro\u00df."),
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
            ("Brother", "der Bruder", "die Br\u00fcder",
             "Der Bruder war wichtig.", "Ich sehe den Bruder.", "Ich werde mit dem Bruder zufrieden sein.", "Die Bedeutung des Bruders ist gro\u00df."),
            ("Child", "das Kind", "die Kinder",
             "Das Kind war wichtig.", "Ich sehe das Kind.", "Ich werde mit dem Kind zufrieden sein.", "Die Bedeutung des Kindes ist gro\u00df."),
            ("Daughter", "die Tochter", "die T\u00f6chter",
             "Die Tochter war wichtig.", "Ich sehe die Tochter.", "Ich werde mit der Tochter zufrieden sein.", "Die Bedeutung der Tochter ist gro\u00df."),
            ("Family", "die Familie", "die Familien",
             "Die Familie war wichtig.", "Ich sehe die Familie.", "Ich werde mit der Familie zufrieden sein.", "Die Bedeutung der Familie ist gro\u00df."),
            ("Father", "der Vater", "die V\u00e4ter",
             "Der Vater war wichtig.", "Ich sehe den Vater.", "Ich werde mit dem Vater zufrieden sein.", "Die Bedeutung des Vaters ist gro\u00df."),
            ("Grandfather", "der Gro\u00dfvater", "die Gro\u00dfv\u00e4ter",
             "Der Gro\u00dfvater war wichtig.", "Ich sehe den Gro\u00dfvater.", "Ich werde mit dem Gro\u00dfvater zufrieden sein.", "Die Bedeutung des Gro\u00dfvaters ist gro\u00df."),
            ("Grandmother", "die Gro\u00dfmutter", "die Gro\u00dfm\u00fctter",
             "Die Gro\u00dfmutter war wichtig.", "Ich sehe die Gro\u00dfmutter.", "Ich werde mit der Gro\u00dfmutter zufrieden sein.", "Die Bedeutung der Gro\u00dfmutter ist gro\u00df."),
            ("Husband", "der Ehemann", "die Ehem\u00e4nner",
             "Der Ehemann war wichtig.", "Ich sehe den Ehemann.", "Ich werde mit dem Ehemann zufrieden sein.", "Die Bedeutung des Ehemannes ist gro\u00df."),
            ("Mother", "die Mutter", "die M\u00fctter",
             "Die Mutter war wichtig.", "Ich sehe die Mutter.", "Ich werde mit der Mutter zufrieden sein.", "Die Bedeutung der Mutter ist gro\u00df."),
            ("Sister", "die Schwester", "die Schwestern",
             "Die Schwester war wichtig.", "Ich sehe die Schwester.", "Ich werde mit der Schwester zufrieden sein.", "Die Bedeutung der Schwester ist gro\u00df."),
            ("Son", "der Sohn", "die S\u00f6hne",
             "Der Sohn war wichtig.", "Ich sehe den Sohn.", "Ich werde mit dem Sohn zufrieden sein.", "Die Bedeutung des Sohnes ist gro\u00df."),
            ("Wife", "die Ehefrau", "die Ehefrauen",
             "Die Ehefrau war wichtig.", "Ich sehe die Ehefrau.", "Ich werde mit der Ehefrau zufrieden sein.", "Die Bedeutung der Ehefrau ist gro\u00df."),
        ],
    },
}

HEADERS = ["English", "German", "Plural", "Past \u00b7 Nominativ", "Present \u00b7 Akkusativ", "Future \u00b7 Dativ", "Genitiv"]
COL_WIDTHS = [16, 18, 20, 26, 28, 36, 32]

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

    # Title row: title merged across all but the last column; "Home" link in the last column
    ws.merge_cells(start_row=1, start_column=1, end_row=1, end_column=len(HEADERS) - 1)
    title_cell = ws.cell(row=1, column=1, value=content["title"])
    title_cell.font = TITLE_FONT
    title_cell.alignment = Alignment(horizontal="left", vertical="center")

    home_cell = ws.cell(row=1, column=len(HEADERS), value="\u2302 Contents")
    home_cell.hyperlink = internal_link("Contents", display="\u2302 Contents")
    home_cell.style = "Hyperlink"
    home_cell.font = Font(name=FONT_NAME, size=12, bold=True, underline="single", color="0563C1")
    home_cell.alignment = Alignment(horizontal="right", vertical="center")

    grammar_cell = ws.cell(row=1, column=len(HEADERS) + 1, value="\U0001F4D6 Grammar")
    grammar_cell.hyperlink = internal_link("Grammar", display="\U0001F4D6 Grammar")
    grammar_cell.style = "Hyperlink"
    grammar_cell.font = Font(name=FONT_NAME, size=12, bold=True, underline="single", color="0563C1")
    grammar_cell.alignment = Alignment(horizontal="right", vertical="center")
    ws.column_dimensions[get_column_letter(len(HEADERS) + 1)].width = 14

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

# Blank spacer row, then a distinctly-styled link down to the Grammar page
toc_grammar_row = r + 1
toc.merge_cells(start_row=toc_grammar_row, start_column=1, end_row=toc_grammar_row, end_column=2)
toc_grammar_cell = toc.cell(row=toc_grammar_row, column=1, value="\U0001F4D6 Grammar \u2013 Die vier F\u00e4lle (cases at a glance)")
toc_grammar_cell.hyperlink = internal_link("Grammar", display="\U0001F4D6 Grammar \u2013 Die vier F\u00e4lle (cases at a glance)")
toc_grammar_cell.style = "Hyperlink"
toc_grammar_cell.font = Font(name=FONT_NAME, size=12, bold=True, underline="single", color="0563C1")
toc_grammar_cell.fill = PatternFill(start_color="FCE9C6", end_color="FCE9C6", fill_type="solid")
toc_grammar_cell.border = BORDER
toc_grammar_cell.alignment = Alignment(horizontal="left", vertical="center")
toc.row_dimensions[toc_grammar_row].height = 22

# Grammar reference sheet: the four cases across question words, definite
# articles, and indefinite articles. Placed last (no explicit index), so it
# lands as the final tab. Every domain sheet's corner nav links here.
gram = wb.create_sheet(title="Grammar")
gram.merge_cells(start_row=1, start_column=1, end_row=1, end_column=4)
gram_title = gram.cell(row=1, column=1, value="Die vier F\u00e4lle \u2013 German Cases at a Glance")
gram_title.font = TITLE_FONT
gram_title.alignment = Alignment(horizontal="left", vertical="center")

gram_home = gram.cell(row=1, column=5, value="\u2302 Contents")
gram_home.hyperlink = internal_link("Contents", display="\u2302 Contents")
gram_home.style = "Hyperlink"
gram_home.font = Font(name=FONT_NAME, size=12, bold=True, underline="single", color="0563C1")
gram_home.alignment = Alignment(horizontal="right", vertical="center")
gram.row_dimensions[1].height = 24

def gram_section(row, text, span):
    gram.merge_cells(start_row=row, start_column=1, end_row=row, end_column=span)
    cell = gram.cell(row=row, column=1, value=text)
    cell.font = Font(name=FONT_NAME, size=12, bold=True)
    cell.alignment = Alignment(horizontal="left", vertical="center")
    gram.row_dimensions[row].height = 20

def gram_header_row(row, labels):
    for c, h in enumerate(labels, start=1):
        cell = gram.cell(row=row, column=c, value=h)
        cell.font = HEADER_FONT
        cell.fill = HEADER_FILL
        cell.border = BORDER
        cell.alignment = CENTER

def gram_data_row(row, values, bold_first=True):
    for c, v in enumerate(values, start=1):
        cell = gram.cell(row=row, column=c, value=v)
        cell.border = BORDER
        cell.alignment = WRAP if c > 1 else Alignment(vertical="top")
        cell.font = GERMAN_FONT if (c == 1 and bold_first) else CELL_FONT

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

for c, w in enumerate([18, 14, 14, 14, 32], start=1):
    gram.column_dimensions[get_column_letter(c)].width = w
gram.sheet_view.showGridLines = False

out_path = sys.argv[1] if len(sys.argv) > 1 else os.path.join(
    os.environ.get("VOCAB_OUT_DIR", os.getcwd()),
    "german_vocabulary_by_domain.xlsx",
)
out_path = os.path.abspath(os.path.expanduser(out_path))
os.makedirs(os.path.dirname(out_path), exist_ok=True)
wb.save(out_path)

home = os.path.expanduser("~")
display_path = "~" + out_path[len(home):] if out_path.startswith(home) else out_path
print(f"Saved: {display_path}")
print("Sheets:", wb.sheetnames)
