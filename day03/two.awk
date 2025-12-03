#!/usr/bin/env gawk -f
function report_error(e) { if (_exit_code) exit _exit_code
                           if (e) { print e; exit _exit_code=1 } }
BEGIN {
    DEBUG = 1
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
    for (i in bank) {
        batteries[bank[i]][i] = 1
    }
    need_to_remove = bank_size - 12
    for (battery in batteries) {
        if (need_to_remove <= 0) {
            break
        }
        for (i in batteries[battery]) {
            bank[i] = ""
            if (--need_to_remove <= 0) {
                break
            }
        }
    }
    joltage = ""
    for (i in bank) {
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
