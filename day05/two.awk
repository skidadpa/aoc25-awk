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
    report_error("ERROR at line " NR ", ingredient found in fresh range section: " $0)
}
(NF != 1) && DIVIDER_SEEN {
    report_error("ERROR at line " NR ", unexpected data in ingredient section: " $0)
}
(NF == 2) {
    if (DEBUG) {
        print "range", NR, ":", $1, "-", $2 > DFILE
    }
    split("", overlaps)
    min = 0 + $1
    max = 0 + $2
    for (i in FRESH) {
        if (((min >= (0 + i)) && (min <= FRESH[i])) || \
            ((max >= (0 + i)) && (max <= FRESH[i])) || \
            ((min < (0 + i)) && (max > FRESH[i]))) {
            overlaps[i] = FRESH[i]
            if (DEBUG) {
                print "...overlaps range", i, "-", FRESH[i] > DFILE
            }
        }
    }
    for (i in overlaps) {
        if ((0 + i) < min) {
            min = 0 + i
        }
        if (overlaps[i] > max) {
            max = overlaps[i]
        }
        delete FRESH[i]
    }
    FRESH[min] = max
}
(NF == 0) {
    DIVIDER_SEEN = 1
}
END {
    report_error()
    if (DEBUG) {
        print "UPDATED RANGES:" > DFILE
        for (i in FRESH) {
            print " ", i, "-", FRESH[i] > DFILE
        }
    }
    sum = 0
    for (i in FRESH) {
        sum += 1 + FRESH[i] - i
    }
    print sum
}
