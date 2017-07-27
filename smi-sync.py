#!/usr/bin/python

import sys
import re

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print "Usage: ", sys.argv[0], "+-seconds"
        sys.exit(-1)

    diff = int(float(sys.argv[1])*1000)
    rexp = re.compile(r'<sync\s+start\s*=\s*(\d+)>', flags=re.IGNORECASE)
    shift = lambda match: "<Sync Start={}>".format(int(match.group(1)) + diff)

    for line in sys.stdin:
        print rexp.sub(shift, line)
