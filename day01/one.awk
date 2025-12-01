#!/usr/bin/env gawk -f
function report_error(e) { if (_exit_code) exit _exit_code
                           if (e) { print e; exit _exit_code=1 } }
function move(n) {
    DIAL += n
    DIAL %= 100
    if (DIAL < 0) {
        DIAL += 100
    }
    if (DIAL == 0) {
        ++COUNT
    }
}
BEGIN {
    DEBUG = 0
    DIAL = 50
    COUNT = 0
    FPAT = "[[:digit:]]+"
}
/^L[[:digit:]]+$/ {
    move(0 - $1)
    next
}
/^R[[:digit:]]+$/ {
    move(0 + $1)
    next
}
{
    report_error("illegal rotation: " $0)
}
END {
    report_error()
    print COUNT
}
