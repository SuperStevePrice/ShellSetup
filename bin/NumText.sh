#!/usr/bin/env bash
# Written in [Amber](https://amber-lang.com/)
# version: 0.3.4-alpha
# date: 2024-07-21 22:17:08
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
__0_count="1"
if [ $([ "_${__0_count}" != "_1" ]; echo $?) != 0 ]; then
    echo "count is Text by assignment to a value of \"1\"."
fi
parse__19_v0 "${__0_count}";
__AS=$?;
if [ $__AS != 0 ]; then
    echo "Error: parse(count) failed."
fi;
__AF_parse19_v0__30_9=$__AF_parse19_v0;
__1_n=$__AF_parse19_v0__30_9
echo $(echo ${__1_n} '==' 1 | bc -l | sed '/\./ s/\.\{0,1\}0\{1,\}$//') > /dev/null 2>&1
    echo "n is Num based on parse(count) where count is type Text."
parse__19_v0 "${__0_count}";
__AS=$?;
if [ $__AS != 0 ]; then
    echo "Error: parse(count) failed."
fi;
__AF_parse19_v0__41_13=$__AF_parse19_v0;
__2_count=$__AF_parse19_v0__41_13
if [ $(echo ${__2_count} '==' 1 | bc -l | sed '/\./ s/\.\{0,1\}0\{1,\}$//') != 0 ]; then
    echo "count converted from Text to Num by parse(count)."
fi
__3_count=1
if [ $(echo ${__3_count} '==' 1 | bc -l | sed '/\./ s/\.\{0,1\}0\{1,\}$//') != 0 ]; then
    echo "count is Num by assignment to a value of 1."
fi