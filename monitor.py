#!/usr/bin/python

import time
import os
import datetime
import sys
import getopt


class Option:
    def __init__(self, argv0):
        self.argv0 = argv0

        self.command = None
        self.displayGoneItem = False
        self.searchPatterns = []
        self.excludeSearchPatterns = []
        self.monitoringInterval = 1
        self.indexField = -1
        self.fieldDelimiter = None
        self.displayWidth = 0

    def takeOption(list, defaultValue):
        l = len(list)
        if l == 0: return defaultValue
        if l == 1: return list[0]
        raise getopt.GetoptError

    def usage(self):
        print "Usage: ", self.argv0, "-c <command> [-p <pattern>] [-x <pattern>] [-g] [-m <interval>] [-i <column>] [-F <delimiter>] [-w <width>]"
        print ""
        print "Options:"
        print "\t-c <command>, --command=<command>              : command to be executed"
        print "\t-p <pattern>, --pattern=<pattern>              : search patterns"
        print "\t-x <pattern>, --exclude-pattern=<pattern>      : exclude search patterns"
        print "\t-g, --display-gone-item                        : display gone item as well as new item"
        print "\t-m <interval> --monitoring-interval=<interval> : monitoring interval (seconds, float number)"
        print "\t-i <column> --index-field=<column>             : index field number"
        print "\t-F <delimiter> --field-delimiter=<delimiter>   : field delimiter"
        print "\t-w <width> --display-width=<width>             : display width"
        sys.exit(-1)

    def parse(self, args, exitOnError=True):
		try:
			opts, args = getopt.getopt(args, "c:p:x:gm:i:F:w:",
					["command=", "pattern=", "exclude-pattern=", "display-gone-item",
					"monitoring-interval=", "index-field=", "field-delimiter=", "display-width="])

			for opt, arg in opts:
				if opt in ('-c', '--command'): self.command = arg
				if opt in ('-p', '--pattern'): self.searchPatterns.append(arg)
				if opt in ('-x', '--exclude-pattern'): self.excludeSearchPatterns.append(arg)
				if opt in ('-g', '--display-gone-item'): self.displayGoneItem = True
				if opt in ('-m', '--monitoring-interval'): self.monitoringInterval = float(arg)
				if opt in ('-i', '--index-field'): self.indexField = int(arg)
				if opt in ('-F', '--field-delimiter'): self.fieldDelimiter = arg
				if opt in ('-w', '--display-width'): self.displayWidth = int(arg)

			if self.command == None: raise getopt.GetoptError()
		except (getopt.GetoptError, ValueError):
			if exitOnError: self.usage()
			return False

		return True


def doExec(opt):
    list = []
    idList = []
    with os.popen(opt.command) as out:
        for line in out:
            if 0 == len(opt.searchPatterns):
                flag = True
            else:
                flag = False
                for pat in opt.searchPatterns:
                    if pat in line:
                        flag = True
                        break
            if flag:
                for xpat in opt.excludeSearchPatterns:
                    if xpat in line:
                        flag = False
                        break
            if flag:
                if opt.indexField >= 0:
                    try:
                        id = line.split(opt.fieldDelimiter, opt.indexField + 1)[opt.indexField]
                        idList.append(id)
                        list.append(line.rstrip())
                    except IndexError:
                        idList.append(None)
                        list.append(line.rstrip())
                else:
                    list.append(line.rstrip())

    if opt.indexField >= 0: return idList, list
    else: return list, list


def main(argv0, args):
    oldList = []
    oldIdList = []

    Wheel = [' |', ' /', ' -', ' \\']
    widx = 0

    opt = Option(argv0)
    opt.parse(args, exitOnError=True)

    newProcessSymbol = "[+] " if opt.displayGoneItem else " "
    goneProcessSymbol = "[-] "
    while True:
        newList = []
        goneList = []

        idList, list = doExec(opt)

        if opt.displayGoneItem:
            for i in range(len(oldIdList)):
                if not oldIdList[i] in idList:
                    goneList.append(oldList[i])

        for i in range(len(idList)):
            if not idList[i] in oldIdList:
                newList.append(list[i])

        if (len(newList) + len(goneList)) > 0:
            tm = datetime.datetime.now().strftime("[%H:%M:%S]")
            if opt.displayWidth == 0:
                for line in goneList:
                    print tm + goneProcessSymbol + line
                    tm = "         :"
                for line in newList:
                    print tm + newProcessSymbol + line
                    tm = "         :"
            else:
                for line in goneList:
                    print tm + goneProcessSymbol + line[:opt.displayWidth]
                    tm = "         :"
                for line in newList:
                    print tm + newProcessSymbol + line[:opt.displayWidth]
                    tm = "         :"
        else:
            widx += 1
            widx %= len(Wheel)
            sys.stdout.write(Wheel[widx])
            sys.stdout.write("\r")
            sys.stdout.flush()

        oldList = list
        oldIdList = idList
        time.sleep(opt.monitoringInterval)


if __name__ == "__main__":
    try:
        main(sys.argv[0], sys.argv[1:])
    except KeyboardInterrupt:
        print "User interrupt monitoring. exit..."
