#!/usr/bin/env gawk -f
function report_error(e) { if (_exit_code) exit _exit_code
                           if (e) { print e; exit _exit_code=1 } }
BEGIN {
    DEBUG = 0
    DFILE = "/dev/stderr"
    FS = ""
    SUM = 0
}
$0 !~ /^[1-9]+$/ {
    report_error("Illegal input: " $0)
}
{
    POS = 0
    MAX = 0
    for (i = 1; i <= NF; ++i) {
        if ($i > MAX) {
            MAX = $i
            POS = i
        }
    }
    if (POS < NF) {
        M1 = MAX
        M2 = 0
        for (i = POS + 1; i <= NF; ++i) {
            if ($i > M2) {
                M2 = $i
            }
        }
    } else {
        M1 = 0
        M2 = MAX
        for (i = 1; i < POS; ++i) {
            if ($i > M1) {
                M1 = $i
            }
        }
    }
    SUM += M1 * 10 + M2
}
END {
    report_error()
    print SUM
}
