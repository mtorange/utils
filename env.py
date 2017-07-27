#!/usr/bin/env python

import os
import sys
import collections

def prtEnvs(d):
	m = -1
	for k in d:
		m = max(m, len(k))
	
	sub = "|"
	space = " " * (m + 3) + sub

	for (n, v) in d.items():
		if ":" in v:
			print "%*s = %s" % (m, n, v)
			head = "%*s +-+" % (m, "")
			tail = "%*s   +" % (m, "")
			outs = []
			for tkn in v.split(':'):
				outs.append( [space, tkn] )
			l = len(outs)
			if l > 0: 
				outs[0][0] = head
			if l > 1:
				outs[l-1][0] = tail
			for t in outs:
				print t[0],t[1]
		else:
			print "%*s = %s" % (m, n, v)



if __name__ == "__main__":
	if len(sys.argv) > 1:
		rv = collections.OrderedDict()
		envs = dict(os.environ)

		for arg in sys.argv[1:]:
			delList = []
			for n, v in envs.iteritems():
				if arg.upper() in n.upper():
					rv[n] = v
					delList.append(n)
			for n in delList:
				envs.pop(n, None)
	else:
		rv = collections.OrderedDict(sorted(os.environ.items()))

	prtEnvs(rv)
