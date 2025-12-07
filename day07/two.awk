#!/usr/bin/env gawk -f
function report_error(e) { if (_exit_code) exit _exit_code
                           if (e) { print e; exit _exit_code=1 } }
BEGIN {
    DEBUG = 0
    DFILE = "/dev/stderr"
    PATTERN = "^[.]+S[.]+$"
    FS = ""
    split("", SPLITTERS)
    split("", NUM_TIMELINES)
}
$0 !~ PATTERN {
    report_error("DATA ERROR: expected " PATTERN " saw " $0)
}
{
    if (PATTERN == "^[.]+$") {
        PATTERN = "^[.][.^]+[.]$"
        next
    } else {
        PATTERN = "^[.]+$"
    }
    for (i = 1; i <= NF; ++i) {
        if ($i == "^") {
            SPLITTER_LEVELS = (NR - 1) / 2
            SPLITTERS[SPLITTER_LEVELS][i] = 1
        } else if ($i == "S") {
            NUM_TIMELINES[1][i] = 1
            next
        }
    }
}
END {
    report_error()
    for (level = 1; level <= SPLITTER_LEVELS; ++level) {
        for (b in NUM_TIMELINES[level]) {
            if (b in SPLITTERS[level]) {
                NUM_TIMELINES[level + 1][b - 1] += NUM_TIMELINES[level][b]
                NUM_TIMELINES[level + 1][b + 1] += NUM_TIMELINES[level][b]
            } else {
                NUM_TIMELINES[level + 1][b] += NUM_TIMELINES[level][b]
            }
        }
    }
    total_timelines = 0
    for (b in NUM_TIMELINES[level]) {
        total_timelines += NUM_TIMELINES[level][b]
    }
    print total_timelines
}
