#!/usr/bin/env gawk -f
function report_error(e) { if (_exit_code) exit _exit_code
                           if (e) { print e; exit _exit_code=1 } }
BEGIN {
    DEBUG = 0
    DFILE = "/dev/stderr"
    FS = "-"
    DIVIDER_SEEN = 0
}
$0 !~ /^([[:digit:]]+(-[[:digit:]]+)?)?$/ {
    report_error("illegal input data: " $0)
}
(NF == 1) && !DIVIDER_SEEN {
    report_error("ERROR at line " NR ", ingrediennt found in fresh range section: " $0)
}
(NF != 1) && DIVIDER_SEEN {
    report_error("ERROR at line " NR ", unexpected data in ingredient section: " $0)
}
(NF == 2) {
    if (DEBUG) {
        print "range", NR, ":", $1, "-", $2 > DFILE
    }
    # for (low in FRESH)
    # FRESH[$1] = $2
}
(NF == 0) {
    DIVIDER_SEEN = 1
}
END {
    report_error()
    print NR
}
