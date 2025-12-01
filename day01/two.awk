#!/usr/bin/env gawk -f
function report_error(e) { if (_exit_code) exit _exit_code
                           if (e) { print e; exit _exit_code=1 } }
# True brute force approach...
function moveby(n, i) {
    if (DEBUG > 1) {
        print "Moving dial by", i * n, "from", DIAL
    }
    while (n > 0) {
        --n
        DIAL += i
        if (DIAL == 100) {
            DIAL = 0
        }
        if (DIAL == 0) {
            if (DEBUG) {
                print "...hit 0"
            }
            ++COUNT
        } else if (DIAL < 0) {
            DIAL += 100
        }
    }
}
BEGIN {
    DEBUG = 0
    DIAL = 50
    COUNT = 0
    FPAT = "[[:digit:]]+"
}
/^L[[:digit:]]+$/ {
    moveby(0 + $1, -1)
    next
}
/^R[[:digit:]]+$/ {
    moveby(0 + $1, 1)
    next
}
{
    report_error("illegal rotation: " $0)
}
END {
    report_error()
    print COUNT
}
