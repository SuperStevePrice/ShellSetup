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
            ("Kitchen", "die K\u00fcche", "die K\u00fcchen",
             "Ich war in der K\u00fcche.", "Ich bin in der K\u00fcche.", "Ich werde in der K\u00fcche sein."),
            ("Table", "der Tisch", "die Tische",
             "Ich habe am Tisch gegessen.", "Ich sitze am Tisch.", "Ich werde am Tisch sitzen."),
            ("Chair", "der Stuhl", "die St\u00fchle",
             "Ich habe den Stuhl repariert.", "Ich sitze auf dem Stuhl.", "Ich werde den Stuhl kaufen."),
            ("Door", "die T\u00fcr", "die T\u00fcren",
             "Ich habe die T\u00fcr geschlossen.", "Ich \u00f6ffne die T\u00fcr.", "Ich werde die T\u00fcr \u00f6ffnen."),
            ("Window", "das Fenster", "die Fenster",
             "Ich habe das Fenster geputzt.", "Ich schaue aus dem Fenster.", "Ich werde das Fenster schlie\u00dfen."),
            ("Bed", "das Bett", "die Betten",
             "Ich bin fr\u00fch ins Bett gegangen.", "Ich mache das Bett.", "Ich werde ins Bett gehen."),
            ("Bedroom", "das Schlafzimmer", "die Schlafzimmer",
             "Ich habe das Schlafzimmer aufger\u00e4umt.", "Ich schlafe im Schlafzimmer.", "Ich werde das Schlafzimmer streichen."),
            ("Bathroom", "das Badezimmer", "die Badezimmer",
             "Ich habe das Badezimmer geputzt.", "Ich dusche im Badezimmer.", "Ich werde das Badezimmer renovieren."),
            ("Roof", "das Dach", "die D\u00e4cher",
             "Der Sturm hat das Dach besch\u00e4digt.", "Das Dach ist alt.", "Wir werden das Dach reparieren."),
            ("Garden", "der Garten", "die G\u00e4rten",
             "Ich habe im Garten gearbeitet.", "Ich arbeite im Garten.", "Ich werde im Garten pflanzen."),
            ("Living room", "das Wohnzimmer", "die Wohnzimmer",
             "Wir haben im Wohnzimmer gesessen.", "Wir sitzen im Wohnzimmer.", "Wir werden im Wohnzimmer fernsehen."),
            ("Key", "der Schl\u00fcssel", "die Schl\u00fcssel",
             "Ich habe den Schl\u00fcssel verloren.", "Ich suche den Schl\u00fcssel.", "Ich werde einen neuen Schl\u00fcssel machen lassen."),
        ],
    },
    "Nature": {
        "title": "Nature \u2013 Die Natur",
        "rows": [
            ("Tree", "der Baum", "die B\u00e4ume",
             "Der Baum ist im Sturm gefallen.", "Der Baum w\u00e4chst schnell.", "Der Baum wird hoch werden."),
            ("Forest", "der Wald", "die W\u00e4lder",
             "Wir sind durch den Wald gewandert.", "Wir wandern durch den Wald.", "Wir werden durch den Wald wandern."),
            ("River", "der Fluss", "die Fl\u00fcsse",
             "Der Fluss ist \u00fcber die Ufer getreten.", "Der Fluss flie\u00dft schnell.", "Der Fluss wird steigen."),
            ("Mountain", "der Berg", "die Berge",
             "Wir sind auf den Berg gestiegen.", "Wir steigen auf den Berg.", "Wir werden auf den Berg steigen."),
            ("Sky", "der Himmel", "die Himmel",
             "Der Himmel war klar.", "Der Himmel ist blau.", "Der Himmel wird bew\u00f6lkt sein."),
            ("Sun", "die Sonne", "die Sonnen",
             "Die Sonne hat geschienen.", "Die Sonne scheint.", "Die Sonne wird scheinen."),
            ("Moon", "der Mond", "die Monde",
             "Der Mond war voll.", "Der Mond ist hell.", "Der Mond wird aufgehen."),
            ("Star", "der Stern", "die Sterne",
             "Die Sterne haben geleuchtet.", "Die Sterne leuchten.", "Die Sterne werden leuchten."),
            ("Flower", "die Blume", "die Blumen",
             "Ich habe Blumen gepfl\u00fcckt.", "Ich pfl\u00fccke Blumen.", "Ich werde Blumen pflanzen."),
            ("Rain", "der Regen", "\u2014",
             "Es hat geregnet.", "Es regnet.", "Es wird regnen."),
            ("Sea", "das Meer", "die Meere",
             "Wir sind ans Meer gefahren.", "Wir schwimmen im Meer.", "Wir werden ans Meer fahren."),
            ("Animal", "das Tier", "die Tiere",
             "Wir haben die Tiere gef\u00fcttert.", "Wir f\u00fcttern die Tiere.", "Wir werden die Tiere f\u00fcttern."),
        ],
    },
    "City": {
        "title": "The City \u2013 Die Stadt",
        "rows": [
            ("Street", "die Stra\u00dfe", "die Stra\u00dfen",
             "Ich bin die Stra\u00dfe entlanggegangen.", "Ich gehe die Stra\u00dfe entlang.", "Ich werde die Stra\u00dfe entlanggehen."),
            ("Market", "der Markt", "die M\u00e4rkte",
             "Ich habe auf dem Markt eingekauft.", "Ich kaufe auf dem Markt ein.", "Ich werde auf dem Markt einkaufen."),
            ("Building", "das Geb\u00e4ude", "die Geb\u00e4ude",
             "Das Geb\u00e4ude wurde 1920 gebaut.", "Das Geb\u00e4ude steht im Zentrum.", "Das Geb\u00e4ude wird renoviert werden."),
            ("Church", "die Kirche", "die Kirchen",
             "Wir sind in die Kirche gegangen.", "Wir gehen in die Kirche.", "Wir werden in die Kirche gehen."),
            ("Bridge", "die Br\u00fccke", "die Br\u00fccken",
             "Wir sind \u00fcber die Br\u00fccke gefahren.", "Wir fahren \u00fcber die Br\u00fccke.", "Wir werden \u00fcber die Br\u00fccke fahren."),
            ("Train station", "der Bahnhof", "die Bahnh\u00f6fe",
             "Ich bin zum Bahnhof gelaufen.", "Ich laufe zum Bahnhof.", "Ich werde zum Bahnhof laufen."),
            ("Shop", "der Laden", "die L\u00e4den",
             "Ich habe den Laden besucht.", "Ich besuche den Laden.", "Ich werde den Laden besuchen."),
            ("Square", "der Platz", "die Pl\u00e4tze",
             "Wir haben uns auf dem Platz getroffen.", "Wir treffen uns auf dem Platz.", "Wir werden uns auf dem Platz treffen."),
            ("Library", "die Bibliothek", "die Bibliotheken",
             "Ich habe in der Bibliothek studiert.", "Ich studiere in der Bibliothek.", "Ich werde in der Bibliothek studieren."),
            ("Museum", "das Museum", "die Museen",
             "Wir haben das Museum besucht.", "Wir besuchen das Museum.", "Wir werden das Museum besuchen."),
            ("Traffic", "der Verkehr", "\u2014",
             "Der Verkehr war stark.", "Der Verkehr ist stark.", "Der Verkehr wird stark sein."),
            ("Neighborhood", "die Nachbarschaft", "die Nachbarschaften",
             "Ich habe in dieser Nachbarschaft gewohnt.", "Ich wohne in dieser Nachbarschaft.", "Ich werde in dieser Nachbarschaft wohnen."),
        ],
    },
    "Country Life": {
        "title": "Country Life \u2013 Das Landleben",
        "rows": [
            ("Farm", "der Bauernhof", "die Bauernh\u00f6fe",
             "Ich bin auf dem Bauernhof aufgewachsen.", "Ich lebe auf dem Bauernhof.", "Ich werde auf dem Bauernhof arbeiten."),
            ("Field", "das Feld", "die Felder",
             "Der Bauer hat das Feld gepfl\u00fcgt.", "Der Bauer pfl\u00fcgt das Feld.", "Der Bauer wird das Feld pfl\u00fcgen."),
            ("Barn", "die Scheune", "die Scheunen",
             "Wir haben das Heu in die Scheune gebracht.", "Wir bringen das Heu in die Scheune.", "Wir werden das Heu in die Scheune bringen."),
            ("Village", "das Dorf", "die D\u00f6rfer",
             "Ich bin im Dorf geboren.", "Ich wohne im Dorf.", "Ich werde im Dorf bleiben."),
            ("Farmer", "der Bauer", "die Bauern",
             "Der Bauer hat die K\u00fche gemolken.", "Der Bauer melkt die K\u00fche.", "Der Bauer wird die K\u00fche melken."),
            ("Harvest", "die Ernte", "die Ernten",
             "Wir haben die Ernte eingebracht.", "Wir bringen die Ernte ein.", "Wir werden die Ernte einbringen."),
            ("Cow", "die Kuh", "die K\u00fche",
             "Die Kuh hat auf der Wiese gegrast.", "Die Kuh grast auf der Wiese.", "Die Kuh wird auf der Wiese grasen."),
            ("Horse", "das Pferd", "die Pferde",
             "Ich bin auf dem Pferd geritten.", "Ich reite auf dem Pferd.", "Ich werde auf dem Pferd reiten."),
            ("Well", "der Brunnen", "die Brunnen",
             "Wir haben Wasser aus dem Brunnen geholt.", "Wir holen Wasser aus dem Brunnen.", "Wir werden Wasser aus dem Brunnen holen."),
            ("Fence", "der Zaun", "die Z\u00e4une",
             "Wir haben den Zaun repariert.", "Wir reparieren den Zaun.", "Wir werden den Zaun reparieren."),
            ("Chicken", "das Huhn", "die H\u00fchner",
             "Ich habe die H\u00fchner gef\u00fcttert.", "Ich f\u00fcttere die H\u00fchner.", "Ich werde die H\u00fchner f\u00fcttern."),
            ("Meadow", "die Wiese", "die Wiesen",
             "Die Schafe haben auf der Wiese geweidet.", "Die Schafe weiden auf der Wiese.", "Die Schafe werden auf der Wiese weiden."),
        ],
    },
    "Government": {
        "title": "Government \u2013 Die Regierung",
        "rows": [
            ("Law", "das Gesetz", "die Gesetze",
             "Das Parlament hat das Gesetz verabschiedet.", "Das Parlament verabschiedet das Gesetz.", "Das Parlament wird das Gesetz verabschieden."),
            ("State", "der Staat", "die Staaten",
             "Der Staat hat die Steuern erh\u00f6ht.", "Der Staat erh\u00f6ht die Steuern.", "Der Staat wird die Steuern erh\u00f6hen."),
            ("President", "der Pr\u00e4sident", "die Pr\u00e4sidenten",
             "Der Pr\u00e4sident hat eine Rede gehalten.", "Der Pr\u00e4sident h\u00e4lt eine Rede.", "Der Pr\u00e4sident wird eine Rede halten."),
            ("Parliament", "das Parlament", "die Parlamente",
             "Das Parlament hat getagt.", "Das Parlament tagt.", "Das Parlament wird tagen."),
            ("Election", "die Wahl", "die Wahlen",
             "Die Wahl hat im November stattgefunden.", "Die Wahl findet im November statt.", "Die Wahl wird im November stattfinden."),
            ("Citizen", "der B\u00fcrger", "die B\u00fcrger",
             "Der B\u00fcrger hat gew\u00e4hlt.", "Der B\u00fcrger w\u00e4hlt.", "Der B\u00fcrger wird w\u00e4hlen."),
            ("Constitution", "die Verfassung", "die Verfassungen",
             "Die Verfassung wurde 1949 geschrieben.", "Die Verfassung sch\u00fctzt die B\u00fcrger.", "Die Verfassung wird ge\u00e4ndert werden."),
            ("Vote", "die Stimme", "die Stimmen",
             "Ich habe meine Stimme abgegeben.", "Ich gebe meine Stimme ab.", "Ich werde meine Stimme abgeben."),
            ("Minister", "der Minister", "die Minister",
             "Der Minister ist zur\u00fcckgetreten.", "Der Minister tritt zur\u00fcck.", "Der Minister wird zur\u00fccktreten."),
            ("Court", "das Gericht", "die Gerichte",
             "Das Gericht hat entschieden.", "Das Gericht entscheidet.", "Das Gericht wird entscheiden."),
            ("Rights", "das Recht", "die Rechte",
             "Die B\u00fcrger haben f\u00fcr ihre Rechte gek\u00e4mpft.", "Die B\u00fcrger k\u00e4mpfen f\u00fcr ihre Rechte.", "Die B\u00fcrger werden f\u00fcr ihre Rechte k\u00e4mpfen."),
            ("Nation", "die Nation", "die Nationen",
             "Die Nation hat getrauert.", "Die Nation trauert.", "Die Nation wird sich erholen."),
        ],
    },
    "Theology": {
        "title": "Theology \u2013 Die Theologie",
        "rows": [
            ("God", "Gott", "\u2014",
             "Gott hat die Welt erschaffen.", "Gott ist g\u00fctig.", "Gott wird uns f\u00fchren."),
            ("Church (body)", "die Kirche", "die Kirchen",
             "Wir haben die Kirche besucht.", "Wir besuchen die Kirche.", "Wir werden die Kirche besuchen."),
            ("Prayer", "das Gebet", "die Gebete",
             "Ich habe ein Gebet gesprochen.", "Ich spreche ein Gebet.", "Ich werde ein Gebet sprechen."),
            ("Faith", "der Glaube", "\u2014",
             "Er hat seinen Glauben bewahrt.", "Er bewahrt seinen Glauben.", "Er wird seinen Glauben bewahren."),
            ("Grace", "die Gnade", "die Gnaden",
             "Gott hat uns seine Gnade gezeigt.", "Gott zeigt uns seine Gnade.", "Gott wird uns seine Gnade zeigen."),
            ("Sin", "die S\u00fcnde", "die S\u00fcnden",
             "Er hat seine S\u00fcnde bereut.", "Er bereut seine S\u00fcnde.", "Er wird seine S\u00fcnde bereuen."),
            ("Salvation", "die Erl\u00f6sung", "\u2014",
             "Sie haben die Erl\u00f6sung gesucht.", "Sie suchen die Erl\u00f6sung.", "Sie werden die Erl\u00f6sung finden."),
            ("Scripture", "die Schrift", "die Schriften",
             "Ich habe die Schrift gelesen.", "Ich lese die Schrift.", "Ich werde die Schrift lesen."),
            ("Soul", "die Seele", "die Seelen",
             "Seine Seele war unruhig.", "Seine Seele ist unruhig.", "Seine Seele wird Frieden finden."),
            ("Spirit", "der Geist", "die Geister",
             "Der Heilige Geist hat sie erf\u00fcllt.", "Der Heilige Geist erf\u00fcllt sie.", "Der Heilige Geist wird sie erf\u00fcllen."),
            ("Sermon", "die Predigt", "die Predigten",
             "Ich habe die Predigt gehalten.", "Ich halte die Predigt.", "Ich werde die Predigt halten."),
            ("Sacrament", "das Sakrament", "die Sakramente",
             "Wir haben das Sakrament empfangen.", "Wir empfangen das Sakrament.", "Wir werden das Sakrament empfangen."),
        ],
    },
    "Philosophy": {
        "title": "Philosophy \u2013 Die Philosophie",
        "rows": [
            ("Truth", "die Wahrheit", "die Wahrheiten",
             "Er hat die Wahrheit gesucht.", "Er sucht die Wahrheit.", "Er wird die Wahrheit finden."),
            ("Reason", "die Vernunft", "\u2014",
             "Sie hat mit Vernunft gehandelt.", "Sie handelt mit Vernunft.", "Sie wird mit Vernunft handeln."),
            ("Knowledge", "das Wissen", "\u2014",
             "Er hat sein Wissen erweitert.", "Er erweitert sein Wissen.", "Er wird sein Wissen erweitern."),
            ("Being", "das Sein", "\u2014",
             "Die Philosophen haben \u00fcber das Sein diskutiert.", "Die Philosophen diskutieren \u00fcber das Sein.", "Die Philosophen werden \u00fcber das Sein diskutieren."),
            ("Freedom", "die Freiheit", "die Freiheiten",
             "Sie haben f\u00fcr die Freiheit gek\u00e4mpft.", "Sie k\u00e4mpfen f\u00fcr die Freiheit.", "Sie werden f\u00fcr die Freiheit k\u00e4mpfen."),
            ("Justice", "die Gerechtigkeit", "\u2014",
             "Er hat nach Gerechtigkeit gestrebt.", "Er strebt nach Gerechtigkeit.", "Er wird nach Gerechtigkeit streben."),
            ("Virtue", "die Tugend", "die Tugenden",
             "Die Tugend war ihm wichtig.", "Die Tugend ist ihm wichtig.", "Die Tugend wird ihm wichtig sein."),
            ("Wisdom", "die Weisheit", "die Weisheiten",
             "Er hat Weisheit gewonnen.", "Er gewinnt Weisheit.", "Er wird Weisheit gewinnen."),
            ("Idea", "die Idee", "die Ideen",
             "Sie hatte eine neue Idee.", "Sie hat eine neue Idee.", "Sie wird eine neue Idee haben."),
            ("Doubt", "der Zweifel", "die Zweifel",
             "Er hatte Zweifel.", "Er hat Zweifel.", "Er wird Zweifel haben."),
            ("Mind", "der Verstand", "\u2014",
             "Er hat seinen Verstand gesch\u00e4rft.", "Er sch\u00e4rft seinen Verstand.", "Er wird seinen Verstand sch\u00e4rfen."),
            ("Logic", "die Logik", "\u2014",
             "Sie hat mit Logik argumentiert.", "Sie argumentiert mit Logik.", "Sie wird mit Logik argumentieren."),
        ],
    },
    "Military": {
        "title": "The Military \u2013 Das Milit\u00e4r",
        "rows": [
            ("Soldier", "der Soldat", "die Soldaten",
             "Der Soldat hat gek\u00e4mpft.", "Der Soldat k\u00e4mpft.", "Der Soldat wird k\u00e4mpfen."),
            ("Army", "die Armee", "die Armeen",
             "Die Armee ist marschiert.", "Die Armee marschiert.", "Die Armee wird marschieren."),
            ("War", "der Krieg", "die Kriege",
             "Der Krieg hat lange gedauert.", "Der Krieg dauert lange.", "Der Krieg wird enden."),
            ("Peace", "der Frieden", "\u2014",
             "Der Frieden wurde unterzeichnet.", "Der Frieden h\u00e4lt an.", "Der Frieden wird kommen."),
            ("Weapon", "die Waffe", "die Waffen",
             "Sie haben die Waffe niedergelegt.", "Sie legen die Waffe nieder.", "Sie werden die Waffe niederlegen."),
            ("Battle", "die Schlacht", "die Schlachten",
             "Die Schlacht hat drei Tage gedauert.", "Die Schlacht tobt.", "Die Schlacht wird beginnen."),
            ("General", "der General", "die Generäle",
             "Der General hat den Befehl gegeben.", "Der General gibt den Befehl.", "Der General wird den Befehl geben."),
            ("Fortress", "die Festung", "die Festungen",
             "Die Festung wurde belagert.", "Die Festung steht fest.", "Die Festung wird verteidigt werden."),
            ("Victory", "der Sieg", "die Siege",
             "Sie haben den Sieg errungen.", "Sie erringen den Sieg.", "Sie werden den Sieg erringen."),
            ("Defeat", "die Niederlage", "die Niederlagen",
             "Sie haben die Niederlage akzeptiert.", "Sie akzeptieren die Niederlage.", "Sie werden die Niederlage akzeptieren."),
            ("Uniform", "die Uniform", "die Uniformen",
             "Er hat die Uniform getragen.", "Er tr\u00e4gt die Uniform.", "Er wird die Uniform tragen."),
            ("Officer", "der Offizier", "die Offiziere",
             "Der Offizier hat die Truppen gef\u00fchrt.", "Der Offizier f\u00fchrt die Truppen.", "Der Offizier wird die Truppen f\u00fchren."),
        ],
    },
    "Literature and Arts": {
        "title": "Literature and Arts \u2013 Literatur und Kunst",
        "rows": [
            ("Book", "das Buch", "die B\u00fccher",
             "Ich habe das Buch gelesen.", "Ich lese das Buch.", "Ich werde das Buch lesen."),
            ("Poem", "das Gedicht", "die Gedichte",
             "Er hat ein Gedicht geschrieben.", "Er schreibt ein Gedicht.", "Er wird ein Gedicht schreiben."),
            ("Author", "der Autor", "die Autoren",
             "Der Autor hat den Roman ver\u00f6ffentlicht.", "Der Autor ver\u00f6ffentlicht den Roman.", "Der Autor wird den Roman ver\u00f6ffentlichen."),
            ("Painting", "das Gem\u00e4lde", "die Gem\u00e4lde",
             "Sie hat das Gem\u00e4lde bewundert.", "Sie bewundert das Gem\u00e4lde.", "Sie wird das Gem\u00e4lde bewundern."),
            ("Music", "die Musik", "\u2014",
             "Wir haben Musik geh\u00f6rt.", "Wir h\u00f6ren Musik.", "Wir werden Musik h\u00f6ren."),
            ("Theatre", "das Theater", "die Theater",
             "Wir sind ins Theater gegangen.", "Wir gehen ins Theater.", "Wir werden ins Theater gehen."),
            ("Language", "die Sprache", "die Sprachen",
             "Ich habe die Sprache gelernt.", "Ich lerne die Sprache.", "Ich werde die Sprache lernen."),
            ("Word", "das Wort", "die W\u00f6rter",
             "Er hat das Wort gesucht.", "Er sucht das Wort.", "Er wird das Wort suchen."),
            ("Story", "die Geschichte", "die Geschichten",
             "Sie hat die Geschichte erz\u00e4hlt.", "Sie erz\u00e4hlt die Geschichte.", "Sie wird die Geschichte erz\u00e4hlen."),
            ("Art", "die Kunst", "die K\u00fcnste",
             "Er hat die Kunst studiert.", "Er studiert die Kunst.", "Er wird die Kunst studieren."),
            ("Poet", "der Dichter", "die Dichter",
             "Der Dichter hat die Zeilen geschrieben.", "Der Dichter schreibt die Zeilen.", "Der Dichter wird die Zeilen schreiben."),
            ("Verse", "der Vers", "die Verse",
             "Sie hat den Vers zitiert.", "Sie zitiert den Vers.", "Sie wird den Vers zitieren."),
        ],
    },
    "Family": {
        "title": "Family \u2013 Die Familie",
        "rows": [
            ("Family", "die Familie", "die Familien",
             "Die Familie hat zusammen gegessen.", "Die Familie isst zusammen.", "Die Familie wird zusammen essen."),
            ("Father", "der Vater", "die V\u00e4ter",
             "Mein Vater hat mir geholfen.", "Mein Vater hilft mir.", "Mein Vater wird mir helfen."),
            ("Mother", "die Mutter", "die M\u00fctter",
             "Meine Mutter hat gekocht.", "Meine Mutter kocht.", "Meine Mutter wird kochen."),
            ("Son", "der Sohn", "die S\u00f6hne",
             "Mein Sohn hat studiert.", "Mein Sohn studiert.", "Mein Sohn wird studieren."),
            ("Daughter", "die Tochter", "die T\u00f6chter",
             "Meine Tochter hat gesungen.", "Meine Tochter singt.", "Meine Tochter wird singen."),
            ("Brother", "der Bruder", "die Br\u00fcder",
             "Mein Bruder hat mich besucht.", "Mein Bruder besucht mich.", "Mein Bruder wird mich besuchen."),
            ("Sister", "die Schwester", "die Schwestern",
             "Meine Schwester hat mir geschrieben.", "Meine Schwester schreibt mir.", "Meine Schwester wird mir schreiben."),
            ("Grandfather", "der Gro\u00dfvater", "die Gro\u00dfv\u00e4ter",
             "Mein Gro\u00dfvater hat Geschichten erz\u00e4hlt.", "Mein Gro\u00dfvater erz\u00e4hlt Geschichten.", "Mein Gro\u00dfvater wird Geschichten erz\u00e4hlen."),
            ("Grandmother", "die Gro\u00dfmutter", "die Gro\u00dfm\u00fctter",
             "Meine Gro\u00dfmutter hat gebacken.", "Meine Gro\u00dfmutter backt.", "Meine Gro\u00dfmutter wird backen."),
            ("Wife", "die Ehefrau", "die Ehefrauen",
             "Meine Frau hat gelacht.", "Meine Frau lacht.", "Meine Frau wird lachen."),
            ("Husband", "der Ehemann", "die Ehem\u00e4nner",
             "Mein Mann hat gearbeitet.", "Mein Mann arbeitet.", "Mein Mann wird arbeiten."),
            ("Child", "das Kind", "die Kinder",
             "Das Kind hat gespielt.", "Das Kind spielt.", "Das Kind wird spielen."),
        ],
    },
}

HEADERS = ["English", "German", "Plural", "Past", "Present", "Future"]
COL_WIDTHS = [16, 18, 18, 34, 28, 32]

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
