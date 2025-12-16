#!/usr/bin/env gawk -f
function report_error(e) { if (_exit_code) exit _exit_code
                           if (e) { print e; exit _exit_code=1 } }
BEGIN {
    DEBUG = 6
    DFILE = "/dev/stderr"
    FPAT = "([[][.#]+])|([(][[:digit:]]+(,[[:digit:]]+)*[)])|([{][[:digit:]]+(,[[:digit:]]+)*[}])"
    MAX_TOTAL_PRESSES = 1000
    SUM = 0
}
$0 !~ /^\[[.#]+\]( [(][[:digit:]]+(,[[:digit:]]+)*[)])+ [{][[:digit:]]+(,[[:digit:]]+)*[}]$/ {
    report_error("DATA ERROR at line " NR ": " $0)
}
{
    num_machines = split(substr($NF,2,length($NF)-2), TARGET, ",")

    split("", BUTTONS)
    for (i = 2; i < NF; ++i) {
        split(substr($i,2,length($i)-2), current_button, ",")
        for (m in current_button) {
            BUTTONS[i - 1][current_button[m] + 1] = 1
        }
        if (DEBUG) {
            BUTTON_DESCRIPTION[i - 1] = "(" current_button[1]
            for (m = 2; m <= length(current_button); ++m) {
                BUTTON_DESCRIPTION[i - 1] = BUTTON_DESCRIPTION[i - 1] "," current_button[m]
            }
            BUTTON_DESCRIPTION[i - 1] = BUTTON_DESCRIPTION[i - 1] " )"
        }
    }

    if (DEBUG) {
        printf "%d: target: (%d", NR, TARGET[1] > DFILE
        for (m = 2; m <= num_machines; ++m) {
            printf ",%d", TARGET[m] > DFILE
        }
        printf ")  buttons:" > DFILE
        for (b in BUTTONS) {
            printf " %s", BUTTON_DESCRIPTION[b]  > DFILE
        }
        printf "\n" > DFILE
    }

    split("", STARTING_VALUES)
    for (i = 1; i <= num_machines; ++i) {
        STARTING_VALUES[i] = 0
    }
    press_count = 0

    # optimization...
    do {
        split("", ACTIVATORS)
        split("", PUSHED_BUTTONS)

        for (b in BUTTONS) for (m in BUTTONS[b]) {
            ACTIVATORS[m][b] = 1
        }

        for (machine in ACTIVATORS) {
            for (b in BUTTONS) {
                MAX_PRESSES[b] = 999999999
                for (m in BUTTONS[b]) {
                    available_presses = TARGET[m] - STARTING_VALUES[m]
                    if (available_presses < MAX_PRESSES[b]) {
                        MAX_PRESSES[b] = available_presses
                    }
                }
                if (DEBUG > 5) {
                    print "MAX_PRESSES[" b "] =", MAX_PRESSES[b], ":", BUTTON_DESCRIPTION[b] > DFILE
                }
            }
            required_presses = TARGET[machine] - STARTING_VALUES[machine]
            if (DEBUG > 5) {
                print "machine " machine " needs " required_presses " more presses" > DFILE
            }
            total_available = 0
            for (b in ACTIVATORS[machine]) {
                total_available += MAX_PRESSES[b]
            }
            for (b in ACTIVATORS[machine]) {
                available_other = total_available - MAX_PRESSES[b]
                if (required_presses > available_other) {
                    auto_press_count = required_presses - available_other
                    if (DEBUG > 5) {
                        print "auto-pressing button", b, auto_press_count, "times"  > DFILE
                    }
                    PUSHED_BUTTONS[b] += auto_press_count
                    required_presses -= auto_press_count
                    press_count += auto_press_count
                    for (m in BUTTONS[b]) {
                        STARTING_VALUES[m] += auto_press_count
                    }
                }
            }
        }
    } while (length(PUSHED_BUTTONS) > 0)

    start = STARTING_VALUES[1]
    found = (STARTING_VALUES[1] >= TARGET[1])
    for (m = 2; m <= num_machines; ++m) {
        start = start "," STARTING_VALUES[m]
        if (STARTING_VALUES[m] < TARGET[m]) {
            found = 0
        }
    }

    if (found) {
        if (DEBUG) {
            print press_count + 1, "presses needed" > DFILE
        }
        SUM += press_count + 1
        next
    }

    split("", VALUES)
    split("", SEEN)

    VALUES[press_count][start] = 1
    SEEN[start] = 1

    while (press_count < MAX_TOTAL_PRESSES) {
        if (DEBUG) {
            print "after", press_count, "presses,", length(VALUES[press_count]), "values to process" > DFILE
        }
        for (value in VALUES[press_count]) {
            split(value, v, ",")
            for (b in BUTTONS) {
                button_allowed = 1
                found = 1
                for (m in v) {
                    if (m in BUTTONS[b]) {
                        if (v[m] >= TARGET[m]) {
                            button_allowed = 0
                            break
                        } else {
                            n[m] = v[m] + 1
                        }
                    } else {
                        n[m] = v[m]
                    }
                    if (n[m] < TARGET[m]) {
                        found = 0
                    }
                }
                if (!button_allowed) {
                    continue
                }
                if (found) {
                    if (DEBUG) {
                        print press_count + 1, "presses needed" > DFILE
                    }
                    SUM += press_count + 1
                    next
                }
                new_value = n[1]
                for (m = 2; m <= num_machines; ++m) {
                    new_value = new_value "," n[m]
                }
                if (!(new_value in SEEN)) {
                    VALUES[press_count + 1][new_value] = 1
                    SEEN[new_value] = 1
                }
            }
        }
        delete VALUES[press_count]
        ++press_count
    }
    report_error("PROGRAM ERROR: did not find a match after " MAX_TOTAL_PRESSES " presses")
}
END {
    report_error()
    print SUM
}
