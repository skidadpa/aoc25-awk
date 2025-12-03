#!/usr/bin/env gawk -f
function report_error(e) { if (_exit_code) exit _exit_code
                           if (e) { print e; exit _exit_code=1 } }
BEGIN {
    DEBUG = 2
    DFILE = "/dev/stderr"
    SUM = 0
    PROCINFO["sorted_in"] = "@ind_num_desc"
}
$0 !~ /^[1-9]+$/ {
    report_error("Illegal input: " $0)
}
{
    bank_size = split($0, bank, "")
    split("", batteries)
    for (i in bank) {
        batteries[bank[i]][i] = 1
    }
    split("", keep)
    lowest_index = 0
    if (DEBUG > 1) {
        print $0, ":" > DFILE
        for (battery in batteries) {
            print " ", battery, ":" > DFILE
            for (i in batteries[battery]) {
                print "   ", i > DFILE
            }
        }
    }
    # add batteries high to low right to left
    for (battery in batteries) {
        if (length(keep) >= 12) {
            break
        }
        last_index = bank_size
        for (i in batteries[battery]) {
            if ((i in keep) || ((i + 0) < lowest_index)) {
                continue
            }
            keep[i] = 1
            if (length(keep) >= 12) {
                break
            }
            last_index = 0 + i
        }
        # see if there are at least 11 batteries after the last battery of a given type
        if (!lowest_index && (last_index + 12 <= bank_size)) {
            # if so, don't add any lower-joltage batteries before here
            lowest_index = last_index
        }
    }
    joltage = ""
    for (i in keep) {
        joltage = bank[i] joltage
    }
    if (DEBUG) {
        print $0, ":", joltage > DFILE
    }
    SUM += 0 + joltage
}
END {
    report_error()
    print SUM
}
