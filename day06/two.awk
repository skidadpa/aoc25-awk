#!/usr/bin/env gawk -f
function report_error(e) { if (_exit_code) exit _exit_code
                           if (e) { print e; exit _exit_code=1 } }
BEGIN {
    DEBUG = 0
    DFILE = "/dev/stderr"
    COUNT = 0
    DONE = 0
    FS = ""
    GRAND_TOTAL = 0
}
/^[ [:digit:]]+$/ && !DONE {
    if (!COUNT) {
        COUNT = NF
    }
    if (COUNT != NF) {
        report_error("DATA ERROR, expected " COUNT " width, got: " $0)
    }
    for (i = 1; i <= NF; ++i) {
        DATA[i] = DATA[i] $i
    }
    next
}
/^[ *+]+$/ && !DONE {
    if (COUNT != NF) {
        report_error("DATA ERROR, expected " COUNT " width, got: " $0)
    }
    operator = " "
    for (i = 1; i <= NF; ++i) {
        if ($i ~ "[+*]") {
            if (operator != " ") {
                report_error("DATA ERROR, did not expect operator, got " $i)
            }
            operator = $i
            sum = 0
            product = 1
            if (DEBUG) {
                print operator, "(" > DFILE
            }
        }
        if (DATA[i] ~ "[[:digit:]]") {
            if (operator == " ") {
                report_error("DATA ERROR, got data with no operator: " DATA[i])
            }
            if (DEBUG) {
                print "  ", DATA[i] > DFILE
            }
            if (operator == "+") {
                sum += DATA[i]
            } else {
                product *= DATA[i]
            }
        } else {
            if (operator == " ") {
                report_error("DATA ERROR, hit end of data with no operator")
            }
            if (operator == "+") {
                if (DEBUG) {
                    print "  ) =", sum > DFILE
                }
                GRAND_TOTAL += sum
            } else {
                if (DEBUG) {
                    print "  ) =", product > DFILE
                }
                GRAND_TOTAL += product
            }
            operator = " "
        }
    }
    if (operator == "+") {
        if (DEBUG) {
            print "  ) =", sum > DFILE
        }
        GRAND_TOTAL += sum
    } else {
        if (DEBUG) {
            print "  ) =", product > DFILE
        }
        GRAND_TOTAL += product
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
