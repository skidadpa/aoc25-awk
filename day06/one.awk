#!/usr/bin/env gawk -f
function report_error(e) { if (_exit_code) exit _exit_code
                           if (e) { print e; exit _exit_code=1 } }
BEGIN {
    DEBUG = 0
    DFILE = "/dev/stderr"
    COUNT = 0
    DONE = 0
    GRAND_TOTAL = 0
}
/^[ [:digit:]]+$/ && !DONE {
    if (!COUNT) {
        COUNT = NF
    }
    if (COUNT != NF) {
        report_error("DATA ERROR, expected " COUNT " fields, got: " $0)
    }
    for (i = 1; i <= NF; ++i) {
        DATA[i][NR] = $i
    }
    next
}
/^[ *+]+$/ && !DONE {
    if (COUNT != NF) {
        report_error("DATA ERROR, expected " COUNT " fields, got: " $0)
    }
    for (operator = 1; operator <= NF; ++operator) {
        if (DEBUG) {
            printf("%s ( %d", $operator, DATA[operator][1]) > DFILE
            for (i = 2; i < NR; ++i) {
                printf(", %d", DATA[operator][i]) > DFILE
            }
            printf(") = ") > DFILE
        }
        if ($operator == "+") {
            sum = 0
            for (i = 1; i < NR; ++i) {
                sum += DATA[operator][i]
            }
            GRAND_TOTAL += sum
            if (DEBUG) {
                print sum > DFILE
            }
        } else {
            product = 1
            for (i = 1; i < NR; ++i) {
                product *= DATA[operator][i]
            }
            GRAND_TOTAL += product
            if (DEBUG) {
                print product > DFILE
            }
        }
    }
    DONE = 1
    next
}
{
    report_error("DATA ERROR: " $0)
}
END {
    report_error()
    print GRAND_TOTAL
}
