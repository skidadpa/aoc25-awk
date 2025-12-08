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
}
END {
    report_error()
    split("", distances)
    split("", circuit)
    split("", junctions)
    for (a = 1; a < NR; ++a) {
        for (b = a + 1; b <= NR; ++b) {
            distances[a,b] = straight_line_distance(a,b)
        }
    }
    highest_circuit_number = 0
    if (DEBUG > 1) {
        print length(distances), "distances calculated" > DFILE
    }
    circuits_to_create = (NR < 100) ? 10 : 1000
    for (pair in distances) if (circuits_to_create-- > 0) {
        split(pair, p, SUBSEP)
        a = p[1]
        b = p[2]
        if (DEBUG) {
            print distances[pair], "from (" X[a] "," Y[a] "," Z[a] ") to (" X[b] "," Y[b] "," Z[b] ")" > DFILE
        }
        if (a in circuit) {
            if (b in circuit) {
                merge_to = circuit[a]
                merge_from = circuit[b]
                if (merge_to != merge_from) {
                    for (junction in junctions[merge_from]) {
                        circuit[junction] = merge_to
                        junctions[merge_to][junction] = 1
                    }
                    delete junctions[merge_from]
                    if (DEBUG > 2) {
                        print "merging circuit", merge_from, "into circuit", merge_to > DFILE
                    }
                } else if (DEBUG > 2) {
                    print "junctions", a, "and", b, "are already both in circuit", merge_to > DFILE
                }
            } else {
                circuit[b] = circuit[a]
                junctions[circuit[a]][b] = 1
                if (DEBUG > 2) {
                    print "adding junction", b, "to circuit", circuit[a] > DFILE
                }
            }
        } else if (b in circuit) {
            circuit[a] = circuit[b]
            junctions[circuit[b]][a] = 1
            if (DEBUG > 2) {
                print "adding junction", a, "to circuit", circuit[b] > DFILE
            }
        } else {
            ++highest_circuit_number
            circuit[a] = circuit[b] = highest_circuit_number
            junctions[highest_circuit_number][a] = junctions[highest_circuit_number][b] = 1
            if (DEBUG > 2) {
                print "creating circuit", highest_circuit_number, "with junctions", a, "and", b > DFILE
            }
        }
    }
    if (DEBUG > 1) {
        print length(junctions), "circuits created" > DFILE
    }
    split("", circuit_sizes)
    for (i in junctions) {
        circuit_sizes[i] = length(junctions[i])
    }
    PROCINFO["sorted_in"] = "@val_num_desc"
    product = 1
    circuits_to_multiply = 3
    for (i in circuit_sizes) if (circuits_to_multiply-- > 0) {
        if (DEBUG) {
            print "circuit of size", circuit_sizes[i] > DFILE
        }
        product *= circuit_sizes[i]
    }
    print product
}
