#!/usr/bin/python
# -*- coding: utf-8 -*-
# This script generates hundreds of random keypresses per second,
#  and sends them to the lyx window
# It requires xvkbd and wmctrl
# It generates a log of the KEYCODES it sends as development/keystest/out/KEYCODES

import random
import os
import re
import sys
import time
#from subprocess import call
import subprocess
import resource
import array
from math import sqrt

# Maximum about of resident LyX memory before we kill it.
# We could possibly adjust this depending on the amount of 
# memory availiable

pid_has_existed=False

def get_max_rss(max_MiB, max_percent):
    F = open('/proc/meminfo','r')
    L = F.readline()
    S = L.split()
    MemTotal_kB = int(S[1])
    print "MemTotal_kB:", MemTotal_kB
    rel_max_bytes = (MemTotal_kB * 1024) * 100 / max_percent
    abs_max_bytes = max_MiB * 1024 * 1024
    max_bytes = min(rel_max_bytes, abs_max_bytes)
    pagesize = resource.getpagesize()
    max_rss = max_bytes / pagesize 
    print "Max_MiB:", max_MiB, "  pagesize:", pagesize, "  max_rss:", max_rss
    return max_rss

#FIXME: use check_env everywhere to make incorrectly name shared_variables easier to check for.    
def check_env(key):
	e=os.environ.get(key)
	if e is None:
		print key + "is None!!! Aborting !!!\n" ; sys.stdout.flush()
		os._exit(1)
	return (e)
	
max_rss = get_max_rss(500,33) 

print 'Beginning keytest.py'

FNULL = open('/dev/null', 'w')

DELAY = '59'

class CommandSource:

    def __init__(self):

	# I have not seriously considered which keycodes should be the most frequent.
        # Also some possible keycodes may be missing entirely particularly combinations of
        # modifiers like ctrl-shift-alt, and currently Function (i.e. F1...F12)
        # keys are never generated

        keycode = [
            "\[Left]",
            '\[Right]',
            '\[Down]',
            '\[Up]',
            '\[BackSpace]',
            '\[Delete]',
            '\[Escape]',
            '\[Return]',
            ]

        keycode[:0] = keycode
	for k in range(0,7):
		keycode.append("\S"+keycode[k])
        keycode[:0] = keycode
	for k in range(0,7):
		keycode.append("\A"+keycode[k])
	for k in range(0,7):
		keycode.append("\C"+keycode[k])

        keycode[:0] = ['\\']

	ascii_keys = range(33,126)

        for k in ascii_keys:
            keycode[:0] = chr(k)

        for k in ascii_keys:
            keycode[:0] = ["\A" + chr(k)]

        for k in ascii_keys:
            keycode[:0] = ["\A" + chr(k)]

        for k in ascii_keys:
            keycode[:0] = ["\C" + chr(k)]
        
	#Some bugs only occur if there is a delay between keypresses
	keycode[:0] = ["\D1"] # 100ms delay
	keycode[:0] = ["\D2"] # 200ms delay
	keycode[:0] = ["\D3"] # 300ms delay
	keycode[:0] = ["\D5"] # 500ms delay
	keycode[:0] = ["\D9"] # 900ms delay

        keycode[:0] = ["\Atp\D5\t\D5i\D5\[Down]\D5s\D5\Ap\D5\As"]
        # We probably don't need shift because we can just use the ascii code for the uppercase characters.
        #for k in ascii_keys:
        #    keycode[:0] = ["\S" + chr(k)]

        self.keycode = keycode
        self.count = 0
        self.count_max = 1999

    def getCommand(self):
        self.count = self.count + 1
        if self.count % 200 == 0:
            return 'RaiseLyx'
        elif self.count > self.count_max:
            os._exit(0)
        else:
            keystr = ''
            for k in range(1, 2):
                keystr = keystr + self.keycode[random.randint(1,
                        len(self.keycode)) - 1]
            if random.uniform(0, 1) < 0.5:
                return 'KK: ' + keystr
            else:
                return 'KO: ' + keystr

# This is a back-of-the-envolope job designed to get the 
# proportion of keycodes dropped to adapt to an optimal value
def pick_drop_prob(fname):
    if float(max_drop) < 0.001:
	return float(max_drop)
    dir=os.path.dirname(fname)
    listfname = dir + "list_of_sizes.txt"
    os.system ( "ls " + dir + 
        "/*.KEYCODEpure -l | awk '{print $5}' | sort -rn | tail -n 20 > "
        + listfname )
    infile = open(listfname, 'r')
    lines = infile.readlines()
    drop_props=[] #Proportions droped
    for L in range(0, len(lines) - 1):
        x = float(lines[L])
        y = float(lines[L+1])
        drop_props.append( ( x - y ) / x ) 
    L = len(drop_props)-1

    # The next line contains a formula that seems to do a resonable job
    # at tuning the adaptivity of the number of lines to drop.
    while L >= 0 and random.uniform(0, 1) > (sqrt(drop_props[L])/2):
        print "reject p", drop_props[L], "with p", sqrt(drop_props[L])/2
        L = L - 1
    if L >= 0:
        print "accept p", drop_props[L], "with p", sqrt(drop_props[L])/2
        proportion_of_keycodes_dropped=drop_props[L]
        base_drop = ( proportion_of_keycodes_dropped * 3) 
        print "autogen drop is ", base_drop, proportion_of_keycodes_dropped
        #probability_we_drop_a_command = float(lines[L])*2+0.0011
    else:
        base_drop=float(max_drop)
    return random.uniform(0, float(base_drop)) + 0.0011
    # 0.0011 is chosen to be larger than 0.001, which we sometimes treat as 0.

class CommandSourceFromFile(CommandSource):

#    def hasalt(self):
#	a = False
# 	for l in self.lines:
#		if l.find("\A") > -1:
#			a = True

#    def index_of_Alt(self):
#	a = array.array('l') 
#	for idx, l in enumerate(self.lines):
#		if l.find("\A") > -1:
#			a.append(idx)

    def __init__(self, filename, p):

	if os.path.exists(filename+"M"):
            filename=filename+"M"
            p=0

        self.infile = open(filename, 'r')
        self.lines = self.infile.readlines()
        self.infile.close()
        linesbak = self.lines
        self.p = p
        print p, self.p, 'self.p'
        self.i = 0
        self.count = 0
        self.loops = 0

#	if random.uniform(0, 1) < 0.2:
#		if (
#		string.replace(str, old)

        # Now we start randomly dropping lines, which we hope are redundant
        # p is the probability that any given line will be removed
	if random.uniform(0, 1) < 0.05:
		if random.uniform(0, 1) < 0.5:
			to_remove="\S"
		else:	
			to_remove="\A"
		a = array.array('l')
	        for idx, l in enumerate(self.lines):
                	if l.find(to_remove) > -1:
                        	a.append(idx)

		print "ioA ", a

	        #ioA =  index_of_Alt();
		if len(a) > 0:
			r1 = random.randint(0,len(a)-1)
			r=a[r1]
			self.lines[r]=self.lines[r].replace(to_remove,"")
			p = 0
			print "ioAr ", r1, r, to_remove
	

        if p > 0.001:
            if random.uniform(0, 1) < 0.5:
                print 'randomdrop_independant\n'
                self.randomdrop_independant()
            else:
                print 'randomdrop_slice\n'
                self.randomdrop_slice()
        if screenshot_out is None:
            count_atleast = 100
        else:
            count_atleast = 1
        self.max_count = max(len(self.lines) + 20, count_atleast)
        if len(self.lines) < 1:
            self.lines = linesbak

    def randomdrop_independant(self):
        # The next couple of lines are to ensure that at least one line is dropped

        drop = random.randint(0, len(self.lines) - 1)
        del self.lines[drop]
        origlines = self.lines
        self.lines = []
        for l in origlines:
            if random.uniform(0, 1) < self.p:
                print 'Randomly dropping line ' + l + '\n',
            else:
                self.lines.append(l)
        print 'LINES\n'
        print self.lines
        sys.stdout.flush()

    def randomdrop_slice(self):
        lines = self.lines
        if random.uniform(0, 1) < 0.2:
            lines.append(lines[0])
            del lines[0]
        num_lines = len(lines)
        max_num_drop = max ( 1 , max(5 * (1 - self.p) , num_lines * (1 - self.p ) ) )
        num_drop = random.randint(1, round(max_num_drop) )
        drop_mid = random.randint(0, num_lines)
        drop_start = max(drop_mid - num_drop / 2, 0)
        drop_end = min(drop_start + num_drop, num_lines)
        print drop_start, drop_mid, drop_end
        print lines
        del lines[drop_start:drop_end]
        print lines
        self.lines = lines

    def getCommand(self):
        if self.count >= self.max_count:
            os._exit(0)
        if self.i >= len(self.lines):
            self.loops = self.loops + 1
            if self.loops > 3:
                os._exit(0)
            self.i = 0
            return 'Loop'
        line = self.lines[self.i]
        self.count = self.count + 1
        self.i = self.i + 1
        #print 'Line read: <<' + line + '>>\n'
        sys.stdout.write('r')
        return line.rstrip('\n').rstrip()

def check_mem():
    f = open("/proc/" + sys.argv[1] + "/stat",'r')
    l = f.readline()
    s = l.split()
    rss = s[23]
    if (rss > max_rss):
        print "LyX process exceeded memory limit of ", rss , "pages." 
        kill_lyx()
    time.sleep(1)

    
def lyx_sleeping():
    global pid_has_existed
    if lyx_pid.find("\n") >= 0:
       return False # FIXME: this just disables this feature for multi-process applications 
    fname = '/proc/' + lyx_pid + '/status'
    if not os.path.exists(fname):
        if pid_has_existed:
             print "PID has disapearred!!! Aborting!!!"
             sys.stdout.flush()
             os._exit(1)
        return False
    pid_has_existed=True
    f = open(fname, 'r')
    lines = f.readlines()
    sleeping = lines[1].find('(sleeping)') > 0

    if not sleeping:
	sys.stdout.write(' ')
    # print 'LYX_STATE', lines[1] , 'SLEEPING=', sleeping

    return sleeping

def kill_lyx():
    print("kill_lyx activated");
    os.system("echo kill -XCPU " + lyx_pid)
    os.system("kill -XCPU " + lyx_pid)
    time.sleep(5)
    os.system("echo kill -9 " + lyx_pid)
    os.system("kill -9 " + lyx_pid)

    os._exit(1)

def sendKeystring(keystr, LYX_PID, opt="-xsendevent"):

    # print "sending keystring "+keystr+"\n"

    if not re.match(".*\w.*", keystr):
        print 'print .' + keystr + '.\n'
        keystr = 'a'
    before_secs = time.time()
    while not lyx_sleeping():
        time.sleep(0.01)
        sys.stdout.write('.')
        #if time.time() - before_secs > 180:
        if time.time() - before_secs > 60:
            print 'Killing due to freeze (KILL_FREEZE)'
            # Do profiling, but sysprof has no command line interface?
            # os.system("killall -KILL lyx")
            kill_lyx()
    if not screenshot_out is None:
        while not lyx_sleeping():
            time.sleep(0.01)
            print '.',
        print 'Making Screenshot: ' + screenshot_out + ' OF ' + infilename
        #time.sleep(0.2)
        os.system('import -window root '+screenshot_out+str(x.count)+".png")
        #time.sleep(0.1)
    sys.stdout.flush()
    if (subprocess.call(
            ["xvkbd", opt, "-delay", DELAY, "-text", keystr],
            stdout=FNULL,stderr=FNULL
            ) == 0):
        sys.stdout.write('*')
    else:
        sys.stdout.write('X')
    subprocess.call(["echo","xvkbd", opt, "-delay", DELAY, "-text", keystr])

def system_retry(num_retry, cmd):
    i = 0
    print "KPP02aa " + cmd ; sys.stdout.flush()
    rtn = os.system(cmd)
    print "KPP02b" ; sys.stdout.flush()
    while ( ( i < num_retry ) and ( rtn != 0) ):
        sys.stdout.write("_\n");
        sys.stdout.flush();
        i = i + 1
	rtn=os.system(cmd)
        time.sleep(1)
    if ( rtn != 0 ):
        print "Command Failed: "+cmd
        print " EXITING!\n"
        print "KPP02iXXXXb" ; sys.stdout.flush()
        sys.stdout.flush();
        os._exit(1)

def RaiseWindow():
    os.system("echo x-session-manager PID: $X_PID.")
    os.system("echo x-session-manager open files: `lsof -p $X_PID | grep ICE-unix | wc -l`")
    ####os.system("wmctrl -l | ( grep '"+lyx_window_name+"' || ( killall lyx ; sleep 1 ; killall -9 lyx ))")
    #os.system("wmctrl -R '"+lyx_window_name+"' ;sleep 0.1")
    #system_retry(30, "wmctrl -R '"+lyx_window_name+"'")
    print "KPP02a" ; sys.stdout.flush()
    system_retry(30, check_env("RAISE_WINDOW_CMD"))
    print "KPP02z" ; sys.stdout.flush()


lyx_pid = os.environ.get('LYX_PID')
print 'lyx_pid: ' + lyx_pid + '\n'
infilename = os.environ.get('KEYTEST_INFILE')
outfilename = os.environ.get('KEYTEST_OUTFILE')
max_drop = os.environ.get('MAX_DROP')
lyx_window_name = os.environ.get('LYX_WINDOW_NAME')
screenshot_out = os.environ.get('SCREENSHOT_OUT')

file_new_command = os.environ.get('FILE_NEW_COMMAND')
if file_new_command is None:
    file_new_command = "\Afn"

ResetCommand = os.environ.get('RESET_COMMAND')
if ResetCommand is None:
    ResetCommand = "\[Escape]\[Escape]\[Escape]\[Escape]" + file_new_command
    #ResetCommand="\[Escape]\[Escape]\[Escape]\[Escape]\Cw\Cw\Cw\Cw\Cw\Afn"

if lyx_window_name is None:
    lyx_window_name = 'LyX'

print 'outfilename: ' + outfilename + '\n'
print 'max_drop: ' + max_drop + '\n'

if infilename is None:
    print 'infilename is None\n'
    x = CommandSource()
    print 'Using x=CommandSource\n'
else:
    print 'infilename: ' + infilename + '\n'
    probability_we_drop_a_command = pick_drop_prob(infilename)
    print 'probability_we_drop_a_command: '
    print '%s' % probability_we_drop_a_command
    print '\n'
    x = CommandSourceFromFile(infilename, probability_we_drop_a_command)
    print 'Using x=CommandSourceFromFile\n'

print "KPP 1" ; sys.stdout.flush()
outfile = open(outfilename, 'w')
print "KPP02" ; sys.stdout.flush()

RaiseWindow()
print "KPP03", lyx_pid ; sys.stdout.flush()
sendKeystring("\Afn", lyx_pid)
print "KPP04" ; sys.stdout.flush()
write_commands = True

while True:
    #os.system('echo -n LOADAVG:; cat /proc/loadavg')
    c = x.getCommand()
    if c == 'Loop':
        outfile.close()
        outfile = open(outfilename + '+', 'w')
        print 'Now Looping'
    outfile.writelines(c + '\n')
    outfile.flush()
    if c == 'RaiseLyx':
        print 'Raising Lyx'
        RaiseWindow()
    elif c[0:4] == 'Ra: ':
        os.system('wmctrl -R "' + c[4:] + '"')
    elif c[0:4] == 'KK: ' or c[0:4] == 'KO: ':
        if os.path.exists('/proc/' + lyx_pid + '/status'):
	    if c[0:2] == 'KO':
                # "-compcact" has no effect, we use it as an easy way to avoid
                # sending -xsendevent. -xsentevent sometimes stops a new dialog
                # from being raised which may or may not be what we want.
                sendKeystring(c[4:], lyx_pid, opt="-compact")
            else:
                sendKeystring(c[4:], lyx_pid)
        else:
            ##os.system('killall lyx; sleep 2 ; killall -9 lyx')
            print 'No path /proc/' + lyx_pid + '/status, exiting'
            os._exit(1)
    elif c[0:4] == 'KD: ':
        DELAY = c[4:].rstrip('\n')
        print 'Setting DELAY to ' + DELAY + '.'
    elif c[0:4] == 'PA: ':
        clipboard = c[4:].rstrip('\n')
        print 'Pasting ' + clipboard + '.'
	os.system('printf "%s" "' + clipboard + '" | xclip -selection clipboard')
	time.sleep(0.1)
        os.system('echo ; echo -n xclip: ; xclip -selection XA_CLIPBOARD -o ; echo ')	
	sendKeystring("\Cv", lyx_pid)
	time.sleep(1)
        print "killall xclip"
        os.system('killall xclip') #hack
    elif c == 'Loop':
        RaiseWindow()
        sendKeystring(ResetCommand, lyx_pid)
    else:
        print "Unrecognised Command '" + c + "'\n"

os.system("echo 'ps gaux | grep xclip | grep -v xclip'")
os.system("ps gaux | grep xclip | grep -v xclip")
print "killing xclip etc., exiting"
os.system("killall xclip") #hack, xclip doesn't give a way to kill it nicely
os.system("echo 'ps gaux | grep xclip | grep -v xclip'")
os.system("ps gaux | grep xclip | grep -v xclip")
os.system("./list_all_children.sh kill " + str(os.getpid()))
