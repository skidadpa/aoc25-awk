#!/usr/bin/env gawk -f
function report_error(e) { if (_exit_code) exit _exit_code
                           if (e) { print e; exit _exit_code=1 } }
BEGIN {
    DEBUG = 0
    DFILE = "/dev/stderr"
    FS = "-"
    DIVIDER_SEEN = 0
    COUNT = 0
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
    LOW[NR] = $1
    HIGH[NR] = $2
}
(NF == 0) {
    DIVIDER_SEEN = 1
}
(NF == 1) {
    if (DEBUG) {
        print "ingredient:", $1 > DFILE
    }
    for (i in LOW) {
        if (($1 >= LOW[i]) && ($1 <= HIGH[i])) {
            if (DEBUG) {
                print "...FRESH" > DFILE
            }
            ++COUNT
            break
        }
    }
}
END {
    report_error()
    print COUNT
}
