#!/usr/bin/env bash
# Written in [Amber](https://amber-lang.com/)
# version: 0.3.4-alpha
# date: 2024-07-20 22:01:30
function input__0_v0 {
    local prompt=$1
    printf "$prompt";
    __AS=$?
    read;
    __AS=$?
    __AF_input0_v0="$REPLY";
    return 0
}
function parse__19_v0 {
    local text=$1
    [ -n "${text}" ] && [ "${text}" -eq "${text}" ] 2>/dev/null;
    __AS=$?;
if [ $__AS != 0 ]; then
__AF_parse19_v0=''
return $__AS
fi
    __AF_parse19_v0="${text}";
    return 0
}
function includes__27_v0 {
    local arr=("${!1}")
    local value=$2
    for v in "${arr[@]}"
do
        if [ $([ "_${v}" != "_${value}" ]; echo $?) != 0 ]; then
            __AF_includes27_v0=1;
            return 0
fi
done
    __AF_includes27_v0=0;
    return 0
}
__AMBER_ARRAY_0=("Bier" "Cappucinno" "Cola" "Espresso" "Kaffee" "Latte" "Wasser");
__0_getraenke=("${__AMBER_ARRAY_0[@]}")
function get_validated_input__46_v0 {
    local prompt=$1
    local is_number=$2
    local benutzereingabe=""
    while :
do
        input__0_v0 "${prompt}"" ";
        __AF_input0_v0__17_31="${__AF_input0_v0}";
        local benutzereingabe="${__AF_input0_v0__17_31}"
        if [ $([ "_${benutzereingabe}" != "_" ]; echo $?) != 0 ]; then
            echo "Eingabe darf nicht leer sein. Bitte versuchen Sie es erneut."
            continue
fi
        if [ ${is_number} != 0 ]; then
            parse__19_v0 "${benutzereingabe}";
            __AS=$?;
if [ $__AS != 0 ]; then
                echo "Fehler: Die Eingabe, ""${benutzereingabe}"", ist keine gültige Zahl."
                continue
fi;
            __AF_parse19_v0__26_13=$__AF_parse19_v0;
            echo $__AF_parse19_v0__26_13 > /dev/null 2>&1
fi
        __AF_get_validated_input46_v0="${benutzereingabe}";
        return 0
done
}
function validier_getraenk__47_v0 {
    local getraenk=$1
    includes__27_v0 __0_getraenke[@] "${getraenk}";
    __AF_includes27_v0__38_12=$__AF_includes27_v0;
    __AF_validier_getraenk47_v0=$__AF_includes27_v0__38_12;
    return 0
}
echo "Programm gestartet.
"
get_validated_input__46_v0 "Geben Sie Ihr bevorzugtes Getränk ein: " 0;
__AF_get_validated_input46_v0__46_5="${__AF_get_validated_input46_v0}";
__1_getraenk="${__AF_get_validated_input46_v0__46_5}"
validier_getraenk__47_v0 "${__1_getraenk}";
__AF_validier_getraenk47_v0__48_4=$__AF_validier_getraenk47_v0;
if [ $__AF_validier_getraenk47_v0__48_4 != 0 ]; then
    get_validated_input__46_v0 "Geben Sie die Anzahl der Getränke ein: " 1;
    __AF_get_validated_input46_v0__50_9="${__AF_get_validated_input46_v0}";
    nummer_getraenk="${__AF_get_validated_input46_v0__50_9}"
    echo "
Sie haben ""${nummer_getraenk}"" ""${__1_getraenk}"" bestellt.
"
else
    echo "Tut mir leid, Wir haben kein ""${__1_getraenk}""."
fi
echo "
Programm beendet.
"