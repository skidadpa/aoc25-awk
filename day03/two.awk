#!/usr/bin/env gawk -f
function report_error(e) { if (_exit_code) exit _exit_code
                           if (e) { print e; exit _exit_code=1 } }
BEGIN {
    DEBUG = 0
    DFILE = "/dev/stderr"
    SUM = 0
    PROCINFO["sorted_in"] = "@ind_num_asc"
}
$0 !~ /^[1-9]+$/ {
    report_error("Illegal input: " $0)
}
{
    bank_size = split($0, bank, "")
    split("", batteries)
    split("", battery_counts)
    for (i = bank_size; i >= 1; --i) {
        batteries[bank[i]][++battery_counts[bank[i]]] = i
    }
    split("", keep)
    lowest_index = 0
    if (DEBUG > 1) {
        print $0, ":" > DFILE
        for (battery in batteries) {
            print " ", battery, ":" > DFILE
            for (i in batteries[battery]) {
                print "   ", batteries[battery][i] > DFILE
            }
        }
    }
    # add batteries high to low right to left
    for (battery = 9; battery >= 1; --battery) if (battery in batteries) {
        if (length(keep) >= 12) {
            break
        }
        for (i in batteries[battery]) {
            idx = batteries[battery][i]
            if (idx < lowest_index) {
                break
            }
            keep[idx] = 1
            if (DEBUG > 1) {
                print "added", battery, "at", idx > DFILE
            }
            # determine where to stop adding lower-joltage batteries
            committed_length = 0
            for (j in keep) {
                ++committed_length
                remaining = bank_size - j
                if (DEBUG > 1) {
                    print "keeping", j, "committed", committed_length, "remaining", remaining, "need", 12 - committed_length > DFILE
                }
                if ((0 + bank[j] > battery) && (remaining >= 12 - committed_length)) {
                    if (DEBUG > 1) {
                        print "updating lowest_index to", j > DFILE
                    }
                    if (0 + j > lowest_index) {
                        lowest_index = 0 + j
                        if (DEBUG > 1) {
                            print "at", j, "new lowest index is", lowest_index > DFILE
                        }
                    }
                }
            }
            if (length(keep) >= 12) {
                break
            }
        }
        # determine where to stop adding lower-joltage batteries
        committed_length = 0
        for (i in keep) {
            ++committed_length
            remaining = bank_size - i
            if (remaining >= 12 - committed_length) {
                if (0 + i > lowest_index) {
                    lowest_index = 0 + i
                }
            }
        }
        if (DEBUG > 1) {
            print "after battery", battery, "lowest index is", lowest_index, "/", bank_size > DFILE
        }
    }
    joltage = ""
    for (i in keep) {
        joltage = joltage bank[i]
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
