#!/usr/bin/env gawk -f
function report_error(e) { if (_exit_code) exit _exit_code
                           if (e) { print e; exit _exit_code=1 } }
BEGIN {
    DEBUG = 0
    DFILE = "/dev/stderr"
    FS = ""
}
$0 !~ /^[.@]+$/ {
    report_error("illegal input: " $0)
}
{
    for (i = 1; i <= NF; ++i) {
        if ($i == "@") {
            ROLLS[i,NR] = 1
        }
    }
}
END {
    report_error()
    sum = 0
    for (coords in ROLLS) {
        split(coords, c, SUBSEP)
        x = c[1]
        y = c[2]
        adjacent = (((x - 1) SUBSEP (y - 1)) in ROLLS) + \
                   (((  x  ) SUBSEP (y - 1)) in ROLLS) + \
                   (((x + 1) SUBSEP (y - 1)) in ROLLS) + \
                   (((x - 1) SUBSEP (  y  )) in ROLLS) + \
                   (((x + 1) SUBSEP (  y  )) in ROLLS) + \
                   (((x - 1) SUBSEP (y + 1)) in ROLLS) + \
                   (((  x  ) SUBSEP (y + 1)) in ROLLS) + \
                   (((x + 1) SUBSEP (y + 1)) in ROLLS)
        if (adjacent < 4) {
            ++sum
        }
        if (DEBUG) {
            print "[" x "," y "] :", adjacent, "adjacent,", ((adjacent < 4) ? "ACCESSIBLE" : "inaccessible") > DFILE
        }
    }
    print sum
}
