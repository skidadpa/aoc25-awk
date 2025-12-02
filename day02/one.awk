#!/usr/bin/env gawk -f
function report_error(e) { if (_exit_code) exit _exit_code
                           if (e) { print e; exit _exit_code=1 } }
BEGIN {
    DEBUG = 0
    DFILE = "/dev/stderr"
    FS = "[-,]"
    SUM = 0
}
$0 !~ /^[[:digit:]]+-[[:digit:]]+(,[[:digit:]]+-[[:digit:]]+)*$/ {
    report_error("Illegal input: " $0)
}
NR != 1 {
    report_error("More than one line in input")
}
{
    if (DEBUG) {
        print NF / 2, "ranges to check" > DFILE
    }
    for (begin = 1; begin < NF; begin += 2) {
        end = begin + 1
        if (DEBUG > 1) {
            print " ", $begin, "-", $end > DFILE
        }
        for (i = $begin; i <= $end; ++i) {
            id = "" i
            size = length(id)
            if (size % 2) {
                gsub(/./, "9", id)
                if (DEBUG > 3) {
                    print "skipping from", i, "to", id > DFILE
                }
                i = 0 + id
                continue
            }
            half = size / 2
            if (substr(id, 1, half) == substr(id, half+1, half)) {
                if (DEBUG > 2) {
                    print id, "is illegal" > DFILE
                }
                SUM += 0 + id
            }
        }
    }
}
END {
    report_error()
    print SUM
}
