#!/usr/bin/env gawk -f
function report_error(e) { if (_exit_code) exit _exit_code
                           if (e) { print e; exit _exit_code=1 } }
BEGIN {
    DEBUG = 0
    DFILE = "/dev/stderr"
    DFILE = "debug.txt"
    FS = ","
    PROCINFO["sorted_in"] = "@val_num_asc"
}
function straight_line_distance(a, b,   dx, dy, dz) {
    dx = X[b] - X[a]
    dy = Y[b] - Y[a]
    dz = Z[b] - Z[a]
    return sqrt(dx * dx + dy * dy + dz * dz)
}
$0 !~ /^[[:digit:]]+,[[:digit:]]+,[[:digit:]]+$/ {
    report_error("DATA ERROR, expected three numbers separated by commas, got " $0)
}
{
    X[NR] = $1
    Y[NR] = $2
    Z[NR] = $3
    CIRCUIT[NR] = NR
    JUNCTIONS[NR][NR] = 1
}
END {
    report_error()
    split("", distances)
    for (a = 1; a < NR; ++a) {
        for (b = a + 1; b <= NR; ++b) {
            distances[a,b] = straight_line_distance(a,b)
        }
    }
    highest_circuit_number = 0
    if (DEBUG) {
        print length(distances), "distances calculated" > DFILE
    }
    for (pair in distances) {
        split(pair, p, SUBSEP)
        a = p[1]
        b = p[2]
        if (DEBUG) {
            print distances[pair], "from (" X[a] "," Y[a] "," Z[a] ") to (" X[b] "," Y[b] "," Z[b] ")" > DFILE
        }
        merge_to = CIRCUIT[a]
        merge_from = CIRCUIT[b]
        if (merge_to != merge_from) {
            for (junction in JUNCTIONS[merge_from]) {
                CIRCUIT[junction] = merge_to
                JUNCTIONS[merge_to][junction] = 1
            }
            delete JUNCTIONS[merge_from]
            if (DEBUG) {
                print "merging circuit", merge_from, "into circuit", merge_to ",", length(JUNCTIONS), "circuit(s) remain" > DFILE
            }
        } else if (DEBUG) {
            print "junctions", a, "and", b, "are already both in circuit", merge_to > DFILE
        }
        if (length(JUNCTIONS) == 1) {
            if (DEBUG) {
                print "last connection is between (" X[a] "," Y[a] "," Z[a] ") and (" X[b] "," Y[b] "," Z[b] "), returning", X[a] * X[b] > DFILE
            }
            print X[a] * X[b]
            exit
        }
    }
    report_error("PROGRAM_ERROR: did not converge into a single circuit")
}
