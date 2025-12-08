#!/usr/bin/env gawk -f
function report_error(e) { if (_exit_code) exit _exit_code
                           if (e) { print e; exit _exit_code=1 } }
BEGIN {
    DEBUG = 0
    DFILE = "/dev/stderr"
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
    for (i = 1; i <= NR; ++i) {
        DISTANCES[i,NR] = straight_line_distance(i,NR)
    }
}
END {
    report_error()
    for (pair in DISTANCES) {
        split(pair, p, SUBSEP)
        if (DEBUG > 2) {
            print DISTANCES[pair], "from (" X[p[1]] "," Y[p[1]] "," Z[p[1]] ") to (" X[p[2]] "," Y[p[2]] "," Z[p[2]] ")" > DFILE
        }
        merge_to = CIRCUIT[p[1]]
        merge_from = CIRCUIT[p[2]]
        if (merge_to != merge_from) {
            for (junction in JUNCTIONS[merge_from]) {
                CIRCUIT[junction] = merge_to
                JUNCTIONS[merge_to][junction] = 1
            }
            delete JUNCTIONS[merge_from]
            if (DEBUG) {
                print "merging circuit", merge_from, "into circuit", merge_to ",", length(JUNCTIONS), "circuit(s) remain" > DFILE
            }
        } else if (DEBUG > 1) {
            print "junctions", p[1], "and", p[2], "are already both in circuit", merge_to > DFILE
        }
        if (length(JUNCTIONS) == 1) {
            if (DEBUG) {
                print "last wire: (" X[p[1]] "," Y[p[1]] "," Z[p[1]] ") - (" X[p[2]] "," Y[p[2]] "," Z[p[2]] "), value", X[p[1]] * X[p[2]] > DFILE
            }
            print X[p[1]] * X[p[2]]
            exit
        }
    }
    report_error("PROGRAM_ERROR: did not converge into a single circuit")
}
