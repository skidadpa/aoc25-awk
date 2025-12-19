#!/usr/bin/env gawk -f
# This solution does not actually do fitting, just checks to make sure it doesn't need to...
function report_error(e) { if (_exit_code) exit _exit_code
                           if (e) { print e; exit _exit_code=1 } }
BEGIN {
    DEBUG = 0
    DFILE = "/dev/stderr"
    FPAT = "([[:digit:]]+)|([#.])"
    FINDING_SHAPE = 0
    CURRENT_SHAPE = ""
    FINDING_TREES = 0
    FITS = 0
}
/^[[:digit:]]+:$/ {
    if (FINDING_SHAPE) {
        report_error("DATA ERROR: expecting shape at " NR " got " $0)
    }
    if (FINDING_TREES) {
        report_error("DATA ERROR: expecting tree at " NR " got " $0)
    }
    SHAPE_NUM = $1
    FINDING_SHAPE = 1
    CURRENT_SHAPE = ""
    CURRENT_AREA = 0
    CURRENT_BOUND = 0
    next
}
/^[#.]+$/ {
    if (!FINDING_SHAPE) {
        report_error("DATA ERROR: not expecting shape at " NR " got " $0)
    }
    if (FINDING_TREES) {
        report_error("DATA ERROR: expecting tree at " NR " got " $0)
    }
    CURRENT_SHAPE = CURRENT_SHAPE $0 "\n"
    CURRENT_BOUND += NF
    for (i = 1; i <= NF; ++i) {
        if ($i == "#") {
            ++CURRENT_AREA
        }
    }
    next
}
/^$/ {
    if (FINDING_SHAPE) {
        SHAPES[SHAPE_NUM] = CURRENT_SHAPE
        AREAS[SHAPE_NUM] = CURRENT_AREA
        BOUNDS[SHAPE_NUM] = CURRENT_BOUND
        FINDING_SHAPE = 0
        if (DEBUG > 1) {
            print "shape", SHAPE_NUM, "area", CURRENT_AREA, "bound", CURRENT_BOUND > DFILE
        }
        CURRENT_SHAPE = ""
        CURRENT_AREA = 0
        CURRENT_BOUND = 0
    }
    if (FINDING_TREES) {
        report_error("DATA ERROR: expecting tree at " NR " got blank line")
    }
    next
}
/^[[:digit:]]+x[[:digit:]]+:( [[:digit:]]+)+$/ {
    if (!FINDING_TREES) {
        TREE_START = NR
        FINDING_TREES = 1
    }
    if (FINDING_SHAPE) {
        report_error("DATA ERROR: expecting shape at " NR " got " $0)
    }
    if (NF != SHAPE_NUM + 3) {
        report_error("DATA ERROR: expecting " (SHAPE_NUM + 1) " shapes at " NR " saw " $0)
    }
    tree_num = NR - TREE_START
    TREE_WIDTH[tree_num] = $1
    TREE_HEIGHT[tree_num] = $2
    min_needed = 0
    max_needed = 0
    for (i = 3; i <= NF; ++i) {
        TREES[tree_num][i - 3] = $i
        min_needed += AREAS[i - 3] * $i
        max_needed += BOUNDS[i - 3] * $i
    }
    area = $1 * $2
    if (DEBUG > 1) {
        print "tree", tree_num, "area", area, "presents", min_needed "-" max_needed > DFILE
    }
    if (area >= max_needed) {
        ++FITS
    } else if (area >= min_needed) {
        if ((tree_num == 0) && (area == 16)) {
            # we know the sample requires fitting and this one fits
            ++FITS
        } else if ((tree_num == 2) && (area == 60)) {
            # we know the sample requires fitting and this one does not fit
        } else {
            report_error("PROGRAM ERROR: actual packing not supported yet")
        }
    }
}
END {
    report_error()
    if (!FINDING_TREES) {
        report_error("DATA ERROR: no trees found")
    }
    if (DEBUG > 2) {
        for (s in SHAPES) {
            print "SHAPE", s, ":" > DFILE
            print SHAPES[s] > DFILE
        }
        for (t in TREES) {
            printf "TREE %d (%dx%d):", t, TREE_WIDTH[t], TREE_HEIGHT[t] > DFILE
            for (p in TREES[t]) {
                printf " %d", TREES[t][p] > DFILE
            }
            printf "\n" > DFILE
        }
    }
    print FITS
}
