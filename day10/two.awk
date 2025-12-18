#!/usr/bin/env gawk -f
function report_error(e) { if (_exit_code) exit _exit_code
                           if (e) { print e; exit _exit_code=1 } }
function indent(   s, i) {
    s = ""
    for (i = 0; i < LEVEL; ++i) {
        s = s "  "
    }
    return s
}
function presses_needed(target,   targs, parity, i, least, c, presses, cost, p, t, t_next) {
    if (target in COSTS) {
        if (DEBUG > 2) {
            printf "%s target: %s cached, cost %d\n", indent(), target, COSTS[target] > DFILE
        }
        return COSTS[target]
    }
    split(target, targs, ",")
    parity = 0
    for (i in targs) {
        if (targs[i] % 2) {
            parity += lshift(1, i - 1)
        }
    }
    if (DEBUG > 2) {
        printf "%s target: %s parity: %d\n", indent(), target, parity > DFILE
        ++LEVEL
    }
    least = 99999999
    for (c in PARITIES[parity]) {
        cost = split(c, presses, ",")
        split(target, targs, ",")
        ok = 1
        for (p in presses) if (ok) {
            for (t in targs) if (ok) {
                if (and(lshift(1, t - 1), presses[p])) {
                    if (targs[t] < 1) {
                        ok = 0
                    }
                    --targs[t]
                }
            }
        }
        if (!ok) continue
        tnext = ""
        comma = ""
        for (t in targs) {
            targs[t] /= 2
            tnext = tnext comma targs[t]
            comma = ","
        }
        cost += 2 * presses_needed(tnext)
        if (least > cost) {
            least = cost
        }
    }
    COSTS[target] = least
    if (DEBUG > 2) {
        --LEVEL
        print indent(), "cost", least > DFILE
    }
    return least
}
BEGIN {
    DEBUG = 0
    if (DEBUG > 2) {
        LEVEL = 0
    }
    DFILE = "/dev/stderr"
    FPAT = "([[][.#]+])|([(][[:digit:]]+(,[[:digit:]]+)*[)])|([{][[:digit:]]+(,[[:digit:]]+)*[}])"
    MAX_TOTAL_PRESSES = 1000
    SUM = 0
}
$0 !~ /^\[[.#]+\]( [(][[:digit:]]+(,[[:digit:]]+)*[)])+ [{][[:digit:]]+(,[[:digit:]]+)*[}]$/ {
    report_error("DATA ERROR at line " NR ": " $0)
}
{
    target = substr($NF,2,length($NF)-2)

    split("", BUTTONS)
    split("", COMBINATIONS)
    next_mask = 1
    for (i = 2; i < NF; ++i) {
        split(substr($i,2,length($i)-2), current_button, ",")
        value = 0
        for (m in current_button) {
            value += lshift(1,current_button[m])
        }
        BUTTONS[value] = $i
        split("", NEW_COMBINATIONS)
        NEW_COMBINATIONS[value] = value
        for (c in COMBINATIONS) {
            NEW_COMBINATIONS[c "," value] = xor(COMBINATIONS[c], value)
        }
        for (c in NEW_COMBINATIONS) {
            COMBINATIONS[c] = NEW_COMBINATIONS[c]
        }
    }

    split("", PARITIES)
    for (c in COMBINATIONS) {
        PARITIES[COMBINATIONS[c]][c] = 1
    }
    PARITIES[0][""] = 1

    start = gensub(/[[:digit:]]+/, "0", "g", target)

    if (DEBUG > 1) {
        printf "%d: target: (%s) buttons:", NR, target > DFILE
        for (b in BUTTONS) {
            printf " %d%s", b, BUTTONS[b] > DFILE
        }
        printf "\n" > DFILE
        print "PARITIES:" > DFILE
        for (p in PARITIES) {
            printf " %d (%d):", p, length(PARITIES[p]) > DFILE
            for (c in PARITIES[p]) {
                printf " %s", c > DFILE
            }
            printf "\n" > DFILE
        }
    }

    split("", COSTS)
    COSTS[start] = 0
    SUM += presses_needed(target)

    if (DEBUG) {
        print NR, ":", COSTS[target] > DFILE
    }
}
END {
    report_error()
    if (DEBUG) {
        print SUM > DFILE
    }
    print SUM
}
