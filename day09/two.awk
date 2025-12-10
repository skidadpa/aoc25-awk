#!/usr/bin/env gawk -f
function report_error(e) { if (_exit_code) exit _exit_code
                           if (e) { print e; exit _exit_code=1 } }
function abs(x) { return x < 0 ? -x : x }
function wrap(i) { return (i < 1) ? NR : (i > NR) ? 1 : i }
function next_tile(i, dir) { return wrap(i + dir) }
function link_tiles(a, b,   direction, edge) {
    if (X[a] != X[b]) {
        if (Y[a] != Y[b]) {
            report_error("DATA ERROR: adjacent tiles " a " and " b " not inline")
        }
        if (X[a] > X[b]) {
            link_tiles(b,a)
            return
        }
        direction = "HORIZONTAL"
        edge = ++HORIZONTAL_EDGES[Y[a]]
        # horizontal indexes go from left to right
        LEFT[Y[a]][edge] = X[a]
        RIGHT[Y[a]][edge] = X[b]
    } else {
        if (Y[a] == Y[b]) {
            report_error("DATA ERROR: adjacent tiles " a " and " b " at same location")
        }
        if (Y[a] > Y[b]) {
            link_tiles(b,a)
            return
        }
        direction = "VERTICAL"
        edge = ++VERTICAL_EDGES[X[a]]
        # vertical indexes go from top to bottom
        TOP[X[a]][edge] = Y[a]
        BOTTOM[X[a]][edge] = Y[b]
    }
    if (DEBUG > 4) {
        print direction, "EDGE from (" X[a] "," Y[a] ") to (" X[b] "," Y[b] ")" > DFILE
    }
}
BEGIN {
    DEBUG = 0
    DFILE = "/dev/stderr"
    FS = ","
    PROCINFO["sorted_in"] = "@val_num_desc"
    # in order to locate interior
    START = 1
    NW = 1
    NE = 2
    SE = 3
    SW = 4
    NOT_NW = -1
    NOT_NE = -2
    NOT_SE = -3
    NOT_SW = -4
    FORWARD = 1
    BACKWARD = -1
}
$0 !~ /^[[:digit:]]+,[[:digit:]]+$/ {
    report_error("DATA ERROR at line " NR ": " $0)
}
{
    X[NR] = $1
    Y[NR] = $2
    for (i = 1; i < NR; ++i) {
        minx = $1 < X[i] ? $1 : X[i]
        maxx = $1 > X[i] ? $1 : X[i]
        miny = $2 < Y[i] ? $2 : Y[i]
        maxy = $2 > Y[i] ? $2 : Y[i]
        AREA[minx,miny,maxx,maxy] = (maxx - minx + 1) * (maxy - miny + 1)
        if (DEBUG > 1) {
            print "AREA (" X[i] "," Y[i] ") - (" $1 "," $2 ") = AREA[" minx "," miny "," maxx "," maxy "] = " AREA[minx,miny,maxx,maxy] >DFILE
        }
    }
    if (NR > 1) {
        link_tiles(NR - 1, NR)
    }
    if (($1 < X[START]) || (($1 == X[START]) && ($2 < Y[START]))) {
        START = NR
    }
}
END {
    report_error()
    if (NR > 1) {
        link_tiles(1, NR)
    }

    direction = FORWARD
    # move in a clockwise direction starting with a horizontal move
    if (X[START] == X[next_tile(START, direction)]) {
        direction = BACKWARD
    }
    INTERIOR[X[START],Y[START]] = last_corner = SE
    i = next_tile(START, direction)
    next_move_vertical = 1

    if (DEBUG > 4) {
        print "finding interior clockwise from (" X[START] "," Y[START] "), dir = " direction > DFILE
        print "  INTERIOR[" X[START] "," Y[START] "] = " SE > DFILE
    }
    while (i != START) {
        n = next_tile(i, direction)
        if (next_move_vertical) {
            up = (Y[n] < Y[i])
            switch (last_corner) {
            case 1: # NW
                last_corner = up ? NE : NOT_SE
                break
            case 2: # NE
                last_corner = 0
                break
            case 3: # SE
                last_corner = up ? NOT_NW : SW
                break
            case 4: # SW
                last_corner = 0
                break
            case -1: # NOT_NW
                last_corner = 0
                break
            case -2: # NOT_NE
                last_corner =  up ? NOT_NW : SW
                break
            case -3: # NOT_SE
                last_corner = 0
                break
            case -4: # NOT_SW
                last_corner = up ? NE : NOT_SE
                break
            default:
                report_error("PROCESSING ERROR: illegal corner type " last_corner)
            }
        } else {
            left = (X[n] < X[i])
            switch (last_corner) {
            case 1: # NW
                last_corner = 0
                break
            case 2: # NE
                last_corner = left ? NOT_SW : SE
                break
            case 3: # SE
                last_corner = 0
                break
            case 4: # SW
                last_corner = left ? NW : NOT_NE
                break
            case -1: # NOT_NW
                last_corner = left ? NOT_SW : SE
                break
            case -2: # NOT_NE
                last_corner = 0
                break
            case -3: # NOT_SE
                last_corner = left ? NW : NOT_NE
                break
            case -4: # NOT_SW
                last_corner = 0
                break
            default:
                report_error("PROCESSING ERROR: illegal corner type " last_corner)
            }
        }
        if (!last_corner) {
            # by restricting to clockwise calculations, half of the combinations are impossible
            report_error("PROGRAM ERROR: clockwise interior calculation failed")
        }
        if (DEBUG > 4) {
            print "  INTERIOR[" X[i] "," Y[i] "] = " last_corner > DFILE
        }
        INTERIOR[X[i],Y[i]] = last_corner
        i = n
        next_move_vertical = !next_move_vertical
    }

    if (DEBUG) {
        print length(AREA), "rectangles to check" > DFILE
    }

    for (box in AREA) {
        if (DEBUG) {
            if ((++rectangles_checked % 1000) == 0) {
                print "checked", rectangles_checked, "rectangles" > DFILE
            }
        }
        split(box, p, SUBSEP)
        minx = p[1]
        miny = p[2]
        maxx = p[3]
        maxy = p[4]

        if (DEBUG > 1) {
            print "checking for interiorness of (" minx "," miny "," maxx "," maxy "), AREA = " AREA[box] > DFILE
        }
        if ((minx SUBSEP miny) in INTERIOR) {
            if (DEBUG > 4) {
                print "  VERIFYING INTERIOR OF (" minx "," miny "," maxx "," maxy ") from top left: " INTERIOR[minx, miny] > DFILE
            }
            switch (INTERIOR[minx,miny]) {
            case 1: # NW
            case 2: # NE
            case 4: # SW
            case -3: # NOT_SE
                if (DEBUG > 1) {
                    print "  (" minx "," miny "," maxx "," maxy ") is in exterior" > DFILE
                }
                continue
            case 3: # SE
            case -1: # NOT_NW
            case -2: # NOT_NE
            case -4: # NOT_SW
                break
            default:
                report_error("PROCESSING ERROR: illegal corner type " last_corner)
            }
        }
        if ((minx SUBSEP maxy) in INTERIOR) {
            if (DEBUG > 4) {
                print "  VERIFYING INTERIOR OF (" minx "," miny "," maxx "," maxy ") from bottom left: " INTERIOR[minx,maxy] > DFILE
            }
            switch (INTERIOR[minx,maxy]) {
            case 1: # NW
            case 3: # SE
            case 4: # SW
            case -2: # NOT_NE
                if (DEBUG > 1) {
                    print "  (" minx "," miny "," maxx "," maxy ") is in exterior" > DFILE
                }
                continue
            case 2: # NE
            case -1: # NOT_NW
            case -3: # NOT_SE
            case -4: # NOT_SW
                break
            default:
                report_error("PROCESSING ERROR: illegal corner type " last_corner)
            }
        }
        if ((maxx SUBSEP miny) in INTERIOR) {
            if (DEBUG > 4) {
                print "  VERIFYING INTERIOR OF (" minx "," miny "," maxx "," maxy ") from top right: " INTERIOR[maxx,miny] > DFILE
            }
            switch (INTERIOR[maxx,miny]) {
            case 1: # NW
            case 2: # NE
            case 3: # SE
            case -4: # NOT_SW
                if (DEBUG > 1) {
                    print "  (" minx "," miny "," maxx "," maxy ") is in exterior" > DFILE
                }
                continue
            case 4: # SW
            case -1: # NOT_NW
            case -2: # NOT_NE
            case -3: # NOT_SE
                break
            default:
                report_error("PROCESSING ERROR: illegal corner type " last_corner)
            }
        }
        if ((maxx SUBSEP maxy) in INTERIOR) {
            if (DEBUG > 4) {
                print "  VERIFYING INTERIOR OF (" minx "," miny "," maxx "," maxy ") from bottom right: " INTERIOR[maxx,maxy] > DFILE
            }
            switch (INTERIOR[maxx,maxy]) {
            case -1: # NOT_NW
            case 2: # NE
            case 3: # SE
            case 4: # SW
                if (DEBUG > 1) {
                    print "  (" minx "," miny "," maxx "," maxy ") is in exterior" > DFILE
                }
                continue
            case 1: # NW
            case -2: # NOT_NE
            case -3: # NOT_SE
            case -4: # NOT_SW
                break
            default:
                report_error("PROCESSING ERROR: illegal corner type " last_corner)
            }
        }

        intersected = 0
        if (DEBUG > 1) {
            print "checking for intersections of (" minx "," miny "," maxx "," maxy "), AREA = " AREA[box] > DFILE
        }
        for (x = minx + 1; x < maxx; ++x) {
            if (x in VERTICAL_EDGES) {
                for (edge = 1; edge <= VERTICAL_EDGES[x]; ++edge) {
                    if (DEBUG > 2) {
                        print "  potential intersection of (" minx "," miny "," maxx "," maxy ") at x = " x > DFILE
                    }
                    # The third check probably isn't necessary since another edge will cut the line
                    intersected = ((TOP[x][edge] <= miny) && (BOTTOM[x][edge] > miny)) || \
                                  ((TOP[x][edge] < maxy) && (BOTTOM[x][edge] >= maxy)) || \
                                  ((TOP[x][edge] >= miny) && (BOTTOM[x][edge] <= miny))
                    if (intersected) {
                        if (DEBUG > 1) {
                            print "   edge at " TOP[x][edge] " to " BOTTOM[x][edge] " INTERSECTS" > DFILE
                        }
                        break
                    } else if (DEBUG > 2) {
                        print "   edge at " TOP[x][edge] " to " BOTTOM[x][edge] " does not intersect" > DFILE
                    }
                }
                if (intersected) {
                    break
                }
            }
            if (intersected) {
                break
            }
        }
        if (intersected) {
            continue
        }
        for (y = miny + 1; y < maxy; ++y) {
            if (y in HORIZONTAL_EDGES) {
                for (edge = 1; edge <= HORIZONTAL_EDGES[y]; ++edge) {
                    if (DEBUG > 2) {
                        print "  potential intersection of (" minx "," miny "," maxx "," maxy ") at y = " y > DFILE
                    }
                    # The third check probably isn't necessary since another edge will cut the line
                    intersected = ((LEFT[y][edge] <= minx) && (RIGHT[y][edge] > minx)) || \
                                  ((LEFT[y][edge] < maxx) && (RIGHT[y][edge] >= maxx)) || \
                                  ((LEFT[y][edge] >= minx) && (RIGHT[y][edge] <= minx))
                    if (intersected) {
                        if (DEBUG > 1) {
                            print "   edge at " LEFT[y][edge] " to " RIGHT[y][edge] " INTERSECTS" > DFILE
                        }
                        break
                    } else if (DEBUG > 2) {
                        print "   edge at " LEFT[y][edge] " to " RIGHT[y][edge] " does not intersect" > DFILE
                    }
                }
                if (intersected) {
                    break
                }
            }
            if (intersected) {
                break
            }
        }
        if (intersected) {
            continue
        }
        
        if (DEBUG) {
            print "AREA [" minx "," miny "," maxx "," maxy "] = " AREA[box] >DFILE
        }
        print AREA[box]
        exit
    }
    report_error("PROGRAM ERROR: no solutions found")
}
