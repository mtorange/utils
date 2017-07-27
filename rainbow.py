#!/usr/bin/env python

import re, os, math, datetime, time, array
import math
import sys


COL_BASE=(20, 20, 0)
USE_MATH=True
OUT="js"

if __name__ == "__main__":
	#colormap = [i for i in range(0,60)]
	colormap = array.array('f')
	for i in xrange(60):
		colormap.append(0.0)


	if USE_MATH:
		for i in xrange(0,60): colormap[i] =  (math.sin(math.pi * 2 * (i/60.0)) + 1.0) / 2.0
	else:
		for i in xrange(0,10): colormap[i] = i/10.0
		for i in xrange(10,30): colormap[i] = 1.0
		for i in xrange(30,40): colormap[i] = (39-i)/10.0
		for i in xrange(40,60): colormap[i] = 0.0


	if OUT == "html":
		print "<html><body><table height='100%' border='0' cellpadding='0' cellspacing='0' ><tr>"
	#base=(0, 0, 30)
	#scale=(255 - COL_BASE[0], 255 - COL_BASE[1], 255 - COL_BASE[2])
	scale = [ 255 - c for c in COL_BASE ]
	for n in xrange(60):
		cmap = (
			colormap[ (n) % 60],
			colormap[ (n+20) % 60],
			colormap[ (n+40) % 60],
		)
		c = [ int(cmap[i] * scale[i]) + COL_BASE[i] for i in xrange(3) ]
		#r = int(map[0]*scale[0]) + base[0]
		#g = int(g*scale[1]) + base[1]
		#b = int(b*scale[2]) + base[2]
		#print rr, gg, bb
		if OUT == "html":
			print "<td width='10' bgcolor='#{:02X}{:02X}{:02X}'></td>".format(c[0], c[1], c[2])
		elif OUT == "js":
			sys.stdout.write( "'#{:02X}{:02X}{:02X}'".format(c[0], c[1], c[2]))
			if 59 == n:
				sys.stdout.write( "\n")
			elif 9 == (n % 10):
				sys.stdout.write( ",\n")
			else:
				sys.stdout.write( ",")

	if OUT == "html":
		print "</tr></table></body></html>"
