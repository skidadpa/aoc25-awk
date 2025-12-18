#!/usr/bin/env gawk -f
function report_error(e) { if (_exit_code) exit _exit_code
                           if (e) { print e; exit _exit_code=1 } }
function find_paths(path, dest,   route_end, ROUTES, o) {
    if (path in PATHS) {
        return
    }
    PATHS[path] = 1
    route_end = split(path, ROUTE, ",")
    # split("", IN_ROUTE)
    # for (r in ROUTE) {
    #     IN_ROUTE[ROUTE[r]] = 1
    # }
    if (ROUTE[route_end] == dest) {
        if (DEBUG > 1) {
            print path > DFILE
        }
        ++PATHS_TO_DEST
    }
    if (ROUTE[route_end] in STOP_AT) {
        return
    }
    for (o in OUTPUTS[ROUTE[route_end]]) {
        # if (o in IN_ROUTE) {
        #     report_error("PROGRAM ERROR: loop discovered")
        # }
        find_paths(path "," o, dest)
    }
}
function count_paths(start, dest,   k) {
    split("", PATHS)
    split("", STOP_AT)
    for (k in KEY_NODES) {
        if (k != start) {
            STOP_AT[k] = 1
        }
    }
    PATHS_TO_DEST = 0
    find_paths(start, dest)
    if (DEBUG) {
        print PATHS_TO_DEST, "paths from", start, "to", dest > DFILE
    }
    return PATHS_TO_DEST
}
BEGIN {
    DEBUG = 2
    DFILE = "/dev/stderr"
    # DFILE = "debug.out"
    FPAT = "[a-z]{3}"
}
$0 !~ /^[a-z]{3}:( [a-z]{3})+$/ {
    report_error("DATA ERROR at line " NR ":" $0)
}
{
    for (i = 2; i <= NF; ++i) {
        OUTPUTS[$1][$i] = 1
        INPUTS[$i][$1] = 1
    }
}
END {
    report_error()
    if (DEBUG > 5) {
        print "OUTPUTS:" > DFILE
        for (i in OUTPUTS) {
            printf "%s:", i > DFILE
            for (o in OUTPUTS[i]) {
                printf " %s", o > DFILE
            }
            printf "\n" > DFILE
        }
        printf "\n" > DFILE
        print "INPUTS:" > DFILE
        for (o in INPUTS) {
            printf "%s:", o > DFILE
            for (i in INPUTS[o]) {
                printf " %s", i > DFILE
            }
            printf "\n" > DFILE
        }
    }
    split("", KEY_NODES)
    KEY_NODES["svr"] = KEY_NODES["dac"] = KEY_NODES["fft"] = KEY_NODES["out"] = 1
    # print count_paths("dac", "fft")
    # print count_paths("fft", "dac")
    # print count_paths("svr", "dac") * count_paths("dac", "fft") * count_paths("fft", "out") + \
    #       count_paths("svr", "fft") * count_paths("fft", "dac") * count_paths("dac", "out")
    split("dac fft svr dac svr", SRCS)
    split("fft dac fft out out", DSTS)
    for (s in SRCS) {
        src = SRCS[s]
        dst = DSTS[s]
        TO_CHECK[1][src] = 1
        split("", OUTPUT_TREE_NODES)
        round = 0
        while (++round in TO_CHECK) {
            if (DEBUG > 1) {
                printf ".", round > DFILE
            }
            for (n in TO_CHECK[round]) {
                if (n in OUTPUT_TREE_NODES) {
                    continue
                }
                OUTPUT_TREE_NODES[n] = 1
                for (o in OUTPUTS[n]) {
                    TO_CHECK[round + 1][o] = 1
                }
            }
            delete TO_CHECK[round]
        }
        if (DEBUG > 1) {
            printf "\n" > DFILE
        }
        TO_CHECK[1][dst] = 1
        split("", INPUT_TREE_NODES)
        round = 0
        while (++round in TO_CHECK) {
            if (DEBUG > 1) {
                printf ".", round > DFILE
            }
            for (n in TO_CHECK[round]) {
                if (n in INPUT_TREE_NODES) {
                    continue
                }
                INPUT_TREE_NODES[n] = 1
                for (i in INPUTS[n]) {
                    TO_CHECK[round + 1][i] = 1
                }
            }
            delete TO_CHECK[round]
        }
        if (DEBUG > 1) {
            printf "\n" > DFILE
        }
        split("", OVERLAPPING_NODES[src "," dst])
        for (n in OUTPUT_TREE_NODES) if (n in INPUT_TREE_NODES) {
            OVERLAPPING_NODES[src "," dst][n] = 1
        }
        if (DEBUG) {
            print "from", src, "to", dst > DFILE
            print "output tree size:", length(OUTPUT_TREE_NODES) > DFILE
            print "input tree size:", length(INPUT_TREE_NODES) > DFILE
            print "overlapping nodes:", length(OVERLAPPING_NODES[src "," dst]) > DFILE
            if (src in INPUT_TREE_NODES) {
                print src, "in input tree" > DFILE
            }
            if (dst in OUTPUT_TREE_NODES) {
                print dst, "in output tree" > DFILE
            }
        }
    }
    split("svr,fft fft,dac svr,fft:fft,dac svr,fft", SRCS)
    split("fft,dac dac,out dac,out fft,dac:dac,out", DSTS)
    for (i in SRCS) {
        src = SRCS[i]
        dst = DSTS[i]
        for (n in OVERLAPPING_NODES[src]) if (n in OVERLAPPING_NODES[dst]) {
            OVERLAPPING_NODES[src ":" dst][n] = 1
        }
        if (DEBUG) {
            print "from", src, "to", dst > DFILE
            print "overlapping nodes:", length(OVERLAPPING_NODES[src ":" dst]) > DFILE
            for (o in OVERLAPPING_NODES[src ":" dst]) {
                print " ", o > DFILE
            }
        }
    }
}
