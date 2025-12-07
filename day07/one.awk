#!/usr/bin/env gawk -f
function report_error(e) { if (_exit_code) exit _exit_code
                           if (e) { print e; exit _exit_code=1 } }
BEGIN {
    DEBUG = 0
    DFILE = "/dev/stderr"
    PATTERN = "^[.]+S[.]+$"
    FS = ""
    split("", BEAMS)
    SPLITTER_HITS = 0
    # verify odd/even splitter alternation, not technically required
    REM = 2
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
            if (i in BEAMS) {
                ++SPLITTER_HITS
                delete BEAMS[i]
                BEAMS[i - 1] = BEAMS[i + 1] = 1
            }
        } else if ($i == "S") {
            REM = (i % 2)
            BEAMS[i] = 1
            next
        }
    }
    REM = !REM
}
END {
    report_error()
    print SPLITTER_HITS
}
