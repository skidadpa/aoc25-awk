#!/usr/bin/env gawk -f
function report_error(e) { if (_exit_code) exit _exit_code
                           if (e) { print e; exit _exit_code=1 } }
function find_paths(path, dst,   route_end, ROUTES, o) {
    if (path in PATHS) {
        return
    }
    PATHS[path] = 1
    route_end = split(path, ROUTE, ",")
    if (ROUTE[route_end] == dst) {
        ++PATHS_TO_DEST
        if (DEBUG > 1) {
            if (PATHS_TO_DEST % 1000000 == 0) {
                print PATHS_TO_DEST, "paths to", dst, "found" > DFILE
            }
            if (DEBUG > 4) {
                print path > DFILE
            }
        }
    }
    for (o in FILTERED_OUTPUTS[ROUTE[route_end]]) {
        find_paths(path "," o, dst)
    }
}
function count_paths(src, dst,   k) {
    split("", PATHS)
    PATHS_TO_DEST = 0

    split("", FILTERED_OUTPUTS)
    for (n in OVERLAPPING_NODES[src "," dst]) {
        for (o in OUTPUTS[n]) {
            if (o in OVERLAPPING_NODES[src "," dst]) {
                FILTERED_OUTPUTS[n][o] = 1
            }
        }
    }
    find_paths(src, dst)
    if (DEBUG) {
        print PATHS_TO_DEST, "paths from", src, "to", dst > DFILE
    }
    return PATHS_TO_DEST
}
BEGIN {
    DEBUG = 0
    DFILE = "/dev/stderr"
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
    split("svr svr dac fft fft dac", SRCS)
    split("dac fft fft dac out out", DSTS)
    for (s in SRCS) {
        src = SRCS[s]
        dst = DSTS[s]
        TO_CHECK[1][src] = 1
        split("", OUTPUT_TREE_NODES)
        round = 0
        while (++round in TO_CHECK) {
            if (DEBUG > 4) {
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
        if (DEBUG > 4) {
            printf "\n" > DFILE
        }
        TO_CHECK[1][dst] = 1
        split("", INPUT_TREE_NODES)
        round = 0
        while (++round in TO_CHECK) {
            if (DEBUG > 4) {
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
        if (DEBUG > 4) {
            printf "\n" > DFILE
        }
        split("", OVERLAPPING_NODES[src "," dst])
        for (n in OUTPUT_TREE_NODES) if (n in INPUT_TREE_NODES) {
            OVERLAPPING_NODES[src "," dst][n] = 1
        }
        if (DEBUG) {
            print length(OVERLAPPING_NODES[src "," dst]), "nodes from", src, "to", dst > DFILE
        }
    }
    if (length(OVERLAPPING_NODES["dac,fft"]) > 1) {
        split("svr dac fft out", ENDPOINTS)
        if (length(OVERLAPPING_NODES["fft,dac"]) > 1) {
            report_error("PROGRAM ERROR: loop between fft and dac nodes")
        }
    } else {
        split("svr fft dac out", ENDPOINTS)
        if (length(OVERLAPPING_NODES["fft,dac"]) < 1) {
            report_error("PROGRAM ERROR: no connection between fft and dac nodes")
        }
    }
    print count_paths(ENDPOINTS[1],ENDPOINTS[2]) * count_paths(ENDPOINTS[2],ENDPOINTS[3]) * count_paths(ENDPOINTS[3],ENDPOINTS[4])
}
