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
        for (n = $begin; n <= $end; ++n) {
            id = "" n
            size = length(id)
            half = size / 2
            # This is very inefficient, could optimize fail checks and/or compare to substr()
            for (len = 1; len <= half; ++len) {
                if (size % len) {
                    continue
                }
                if (match(id, "^(" substr(id, 1, len) "){" size / len "}$")) {
                    if (DEBUG > 2) {
                        print id, "is illegal" > DFILE
                    }
                    SUM += 0 + id
                    break
                }
            }
        }
    }
}
END {
    report_error()
    print SUM
}
