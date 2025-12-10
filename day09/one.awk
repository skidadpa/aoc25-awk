#!/usr/bin/env gawk -f
function report_error(e) { if (_exit_code) exit _exit_code
                           if (e) { print e; exit _exit_code=1 } }
function abs(x) { return x < 0 ? -x : x }
BEGIN {
    DEBUG = 0
    DFILE = "/dev/stderr"
    FS = ","
    PROCINFO["sorted_in"] = "@val_num_desc"
}
$0 !~ /^[[:digit:]]+,[[:digit:]]+$/ {
    report_error("DATA ERROR at line " NR ": " $0)
}
{
    X[NR] = $1
    Y[NR] = $2
    for (i = 1; i < NR; ++i) {
        AREA[i,NR] = (abs(X[NR] - X[i]) + 1) * (abs(Y[NR] - Y[i]) + 1)
    }
}
END {
    report_error()
    for (a in AREA) {
        print AREA[a]
        break
    }
}
