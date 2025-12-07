#!/usr/bin/env gawk -f
function report_error(e) { if (_exit_code) exit _exit_code
                           if (e) { print e; exit _exit_code=1 } }
BEGIN {
    DEBUG = 1
    DFILE = "/dev/stderr"
    PATTERN = "^[.]+S[.]+$"
    FS = ""
    split("", SPLITTERS)
    split("", STARTING_LEVEL)
    split("", STARTING_BEAM)
    # verify odd/even splitter alternation, not technically required
    REM = 2
    NUM_TIMELINES = 0
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
            if (i % 2 != REM) {
                report_error("PROGRAM ERROR: expect odd/even alternation at " NR ", got " $0)
            }
            SPLITTER_LEVELS = (NR - 1) / 2
            SPLITTERS[SPLITTER_LEVELS][i] = 1
        } else if ($i == "S") {
            REM = (i % 2)
            if (DEBUG) {
                print NUM_TIMELINES + 1, ": initial beam at", i, "level 0" > DFILE
            }
            ++NUM_TIMELINES
            STARTING_LEVEL[NUM_TIMELINES] = 0
            STARTING_BEAM[NUM_TIMELINES] = i
            next
        }
    }
    REM = !REM
}
END {
    report_error()
    for (t = 1; t <= NUM_TIMELINES; ++t) {
        level = STARTING_LEVEL[t]
        beam = STARTING_BEAM[t]
        while (level <= SPLITTER_LEVELS) {
            ++level
            if (beam in SPLITTERS[level]) {
                if (DEBUG > 1) {
                    print NUM_TIMELINES + 1, ": beam split at", beam, "level", level > DFILE
                }
                ++NUM_TIMELINES
                STARTING_LEVEL[NUM_TIMELINES] = level
                STARTING_BEAM[NUM_TIMELINES] = beam + 1
                --beam
                if ((DEBUG == 1) && (NUM_TIMELINES % 1000000 == 0)) {
                    print NUM_TIMELINES, "timelines" > DFILE
                }
            }
        }
    }
    print NUM_TIMELINES
}
