#!/usr/bin/python
# -*- coding: utf-8 -*-

import sys 
import os
from subprocess import call, check_call
from random import randrange
import getpass
import time
import string
import shutil

print "Starting cache-bisect.py"


outfilename = "/tmp/cache-bisect." + getpass.getuser() + ".log"
outfile = open(outfilename, 'w')

trunk=False
trunk=True
#source_dir = '/mnt/big/xp/src/lyx-1.6.x-bisect'  # must NOT end in a slash
if trunk:
	source_dir = '/var/cache/keytest/lyx-devel'  # must NOT end in a slash
	cache_dir = source_dir + '.cache/'  # must end in a slash
	source_dir = '/mnt/modern/xp/src/lyx-devel'
else:
	source_dir = '/var/cache/keytest/lyx-1.6.x'  # must NOT end in a slash
	cache_dir = source_dir + '.cache/'  # must end in a slash
	source_dir = '/mnt/sdb7/xp/src/svn2/lyx-1.6.x'

store_dir = cache_dir + 'store/'

os.system('mkdir -p ' + cache_dir)

for p in [cache_dir, cache_dir, store_dir, source_dir]:
	if not os.path.exists(p):
		print 'Path', p, 'does not exist, exiting'
		os._exit(1)
	if not os.path.exists(p + '/..'):
		print 'Path', p + '/..', 'does not exist, exiting'
		print 'Perhaps ' + p + 'is not a directory?'
		os._exit(1)

#source_dir = '/mnt/big/xp/src/lyx-1.6.x-bisect2'  # must NOT end in a slash

#make_cmd= 'mkdir -p `pwd`.path ; rm `pwd`.path/a*  ; rm -r autom4te.cache ; rm aclocal.m4 ; ln -s /usr/bin/automake-`cat autogen.sh  | grep "LyX only supports automake" | grep -o "1.[0-9]*" |tail -n1` `pwd`.path/automake &&ln -s /usr/bin/aclocal-`cat autogen.sh  | grep "LyX only supports automake" | grep -o "1.[0-9]*" |tail -n1` `pwd`.path/aclocal && ln -s /usr/bin/autoconf `pwd`.path/autoconf &&   export PATH=`pwd`.path:$PATH && (make distclean || make clean)  ./autogen.sh &&   ./configure --without-included-boost --enable-debug --prefix=`pwd`_bin && make && make install && make install'  #&& make clean'
#make_cmd='mkdir -p `pwd`.path ; rm `pwd`.path/a* ; make distclean ; make clean ; rm -r autom4te.cache ; rm aclocal.m4 ; ln -s /usr/bin/automake-`cat autogen.sh  | grep "LyX only supports automake" | grep -o "1.[0-9]*" |tail -n1` `pwd`.path/automake &&ln -s /usr/bin/aclocal-`cat autogen.sh  | grep "LyX only supports automake" | grep -o "1.[0-9]*" |tail -n1` `pwd`.path/aclocal && ln -s /usr/bin/autoconf `pwd`.path/autoconf &&   export PATH=`pwd`.path:$PATH && ./autogen.sh && CXX=g++-4.2 CC=gcc-4.2 CXXFLAGS=-Os CFLAGS=-Os ./configure --enable-debug --prefix=`pwd`_bin && make && make install'  #&& make clean'
#make_cmd='(make distclean ; make clean ; rm -r autom4te.cache ; rm aclocal.m4 ;  export PATH=/var/cache/keytest/lyx-devel.cache/26000.path:$PATH && sed -i.bak s/0-[34]/0-5/ ./autogen.sh && ./autogen.sh && CXX=g++-4.2 CC=gcc-4.2 CXXFLAGS=-Os CFLAGS=-Os ./configure --enable-debug --prefix=`pwd`_bin && nice -19 make -j2 && nice -19 make install) | tee MAKE.LOG'  #&& make clean'
make_cmd='(make distclean ; make clean ; rm -r autom4te.cache ; rm aclocal.m4 ;  export PATH=/mnt/big/keytest/path/bin:$PATH && sed -i.bak s/0-[34]/0-5/ ./autogen.sh && ./autogen.sh && CXX=g++-4.2 CC=gcc-4.2 CXXFLAGS=-Os CFLAGS=-Os ./configure --enable-debug --prefix=`pwd`_bin && nice -19 make -j2 && nice -19 make install) | tee MAKE.LOG'  #&& make clean'

reverse_search = True
reverse_search = False
#must_make = True  # If we fail to make the file, we call this a "bad" rather than "cannot test"
must_make = False

# ToDo:
# replace .tmp with .partial_copy and .not_yet_made
def logline (line):
        outfile.flush()
        print line
        print >> outfile, line
        outfile.flush()
	sys.stdout.flush()

def set_revision(new_v, tmp_d):
    #check_call(['svn', 'up', '-r' + new_v, '--force'], cwd=tmp_d)
    if os.system ('cd "'+tmp_d+'" && yes tf | svn up -r'+new_v+' --force') != 0:
        print "SVN UPDATE FAILED"
        os._exit(1)

def cmp_version(x, y):
    print VERS
    print x, y
    return cmp(int(x), int(y))


def get_cached_versions():
    #vers = [f for f in os.listdir(cache_dir) if (f.upper() == f.lower() and not (f.count('.') or f.count('_')))]
    vers = [f.replace('_bin','') for f in os.listdir(cache_dir) if (f.endswith('_bin'))]
    vers.sort(cmp_version)
    return vers


def version_in_range(v, lo, hi):
    if cmp_version(v, lo) < 0:
        return False
    elif cmp_version(v, hi) > 0:
        return False
    return True

def killall_p (s):
    # Unlike killall, this searchs within command parameters, as well as the
    # command name

        #os.system("kPID=`ps a | grep '"+s+"' | grep -v grep | sed 's/^ *//g'|  sed 's/ .*$//'`
    print "killall_p " + s+ " activated"
    os.system("(kPID=`ps a | grep '"+s+
    "' | grep -v grep | sed 's/^ *//g'|  sed 's/ .*$//'`\n\
        echo kPID $kPID "+s+"\n\
        echo kill $kPID\n\
        kill $kPID\n\
        sleep 0.1\n\
        echo kill -9 $kPID\n\
        kill -9 $kPID) 2> /dev/null")

def clean_up ():
    print "CLEAN UP (killer) activated"
    killall_p("autolyx")
    killall_p("keytest.py")
    killall_p("xclip")
    os.system("./list_all_children.sh kill " + str(os.getpid()))

def filter_versions(vers, lo, hi):
    return [v for v in vers if cmp]


def ver2dir(v):
    return cache_dir + v

def ver2store(v):
    return cache_dir + 'store/' + v + '.tar.gz'

def ver_stored(v):
    print "ver2store: ", ver2store(v)
    return os.path.exists(ver2store(v))

def check_has_VC(v):
    check_call(['svn', 'info'], cwd=ver2dir(v))


def is_built(d):
    '''Returns true if the source directory d has successfully built it's binaries'''
    return os.path.exists(d+"_bin/share/lyx/chkconfig.ltx")

def make_ver(new_v, old_v=None, alt_v=None):
    print 'MAKING', new_v, old_v, alt_v
    print >> outfile, 'MAKING', new_v, old_v, alt_v
    outfile.flush()
    new_d = ver2dir(new_v)
    if old_v is None:
        old_d = source_dir
    else:
        old_d = ver2dir(old_v)
	if is_built(old_d) and os.path.exists(old_d):
        # remove all the files that are built rather than part of the svn tree
        # We could also remove all of the non-svn files wit something like the following line
	    #os.system("cd " + old_d + " && for d in ` find . -type d | grep -v '/.svn'` ; do svn status|egrep '^\?'|awk '{print $2}'|xargs rm -rf; done")
            call(['make', 'distclean'], cwd=old_d)
            call(['make', 'clean'], cwd=old_d)
    fail_d = new_d + '.fail'
    tmp_d = new_d + '.tmp'
    if os.path.exists(cache_dir + fail_d):
        print >> outfile, "Failed make: see",cache_dir + fail_d
        return 1
    if is_built(new_d):
        print >> outfile, "make already done, see "+new_d+"_bin/share/lyx/chkconfig.ltx"
        return 0
    if not ( os.path.exists(tmp_d) or os.path.exists(new_d) ):
        if not os.path.exists(old_d):
            old_d = old_d + '.tmp'
        if not os.path.exists(old_d):
            old_d = source_dir
        call(['rm', '-rf', tmp_d + '.cp'])
	print "Copying " + old_d + " to " + new_d
	
	if ver_stored(old_v):
		#This could leave partial copies around, I should really use a tmpdir
		#os.system("cd " + cache_dir + " && tar -zxf " + ver2store(old_v))
		tmp_dir = cache_dir + '/tmp'
		tmp_d = tmp_dir + '/' + old_v
		check_call(['mkdir', '-p', 'tmp'], cwd=cache_dir)
		check_call(['tar', '-zxf', store_dir + '/' + old_v + '.tar.gz' ], cwd=tmp_dir)
		#print "CMD: cd " + cache_dir + " && tar -zxf " + ver2store(old_v)
		check_call(['mv', tmp_d, new_d])
		check_has_VC(new_v)
		set_revision(new_v, new_d)
		print "Untarred and moved"
	else:
	        call(['cp', '-ru', old_d, tmp_d + '.cp'])
		print "Copyed " + old_d + " to " + new_d
        	check_call(['mv', tmp_d + '.cp', tmp_d])
    if not os.path.exists(new_d):
        set_revision(new_v, tmp_d) # will exit on failure
        check_call(['mv', tmp_d, new_d])
    print >> outfile, "Make DIR: ",new_d
    print "Make DIR: ",new_d
    check_has_VC(new_v)
    result = call(make_cmd, cwd=new_d, shell=True)
    if result == 0:
        print 'Make successful'
        if not os.path.exists(new_d+"_bin/share/lyx/chkconfig.ltx"):
            print 'But '+new_d+"_bin/share/lyx/chkconfig.ltx"+'Does not exist'
            result=3
        else:
            print 'CMD: (cd '+new_d+' && (make clean || make distclean)) && cd'+cache_dir+' && nice -19 tar -c "'+new_v+' | nice -19 gzip -9 > "'+ver2store(new_v) + '" && rm -rf "'+new_v+'"'
            os.system('(cd ' +new_d+' && (make clean || make distclean)) && cd'+cache_dir+' && nice -19 tar -c "'+new_v+' | nice -19 gzip -9 > "'+ver2store(new_v) + '" && rm -rf "'+new_v+'"')
    print >> outfile, "Make result: ",result
    outfile.flush()
    return result


def change_after(cmd, v):
    print ""
    print "TESTING VERSION " + v
    result = run_cmd(cmd, v)
    ca = result_after(result)
    print >> outfile, 'BISECT_change_after', v, ca
    print 'BISECT_change_after', v, ca
    return ca


def change_before(cmd, v):
    result = run_cmd(cmd, v)
    cb = result_before(result)
    print >> outfile, 'BISECT_change_before', v, cb
    print 'BISECT_change_before', v, cb
    return cb


def result_after(i):
    if reverse_search:
        return result_bad(i)
    else:
        return result_good(i)


def result_before(i):
    if reverse_search:
        return result_good(i)
    else:
        return result_bad(i)


def result_good(i):
    return i == 0


def result_bad(i):
    return not result_ugly(i) and not result_good(i)


def result_ugly(i):
    return i == 125  # Like git, we treat 125 as "We cannot test this version"


def run_cmd(cmd, v):
    #result = call('pwd ; echo SS ' + cmd, shell=True, cwd=ver2dir(v))
    print "CMD", cmd
    print "V2D", ver2dir(v)
    #result = subprocess.call(cmd, shell=True, cwd=ver2dir(v))
    os.system('mkdir "'+ver2dir(v)+'"')
    result = call(cmd, cwd=ver2dir(v))
    # Uncommenting the following line will cause the "tar -zxf" process to be killed
    # AFAICT this *should* is impossible because clean_up shouldn't even run at the
    # same time, but I'll leave it comment out until I find out what the problem is.
    ####clean_up()
    print cmd, result
    return result


def do_bisect(cmd, vers, build):
    lo = 0
    hi = len(vers) - 1

    round_up = 0 # 1 to round_up, 0 to not round_up
    m = (lo + hi + round_up) / 2
    # We round up m as rejecting a faulty version is faster than verifying
    # a correct one. OTOH selecting a version that is less likely to be
    # faulty is safer as we cannot falsely reject a working version 

    print lo, hi, m
    print vers[lo], vers[hi], vers[m]
    print vers

    ###print >> outfile, 'VERS', final_vers

    while len(vers) > 2:
        print 'i', lo, hi, m, cmd
        print 'v', vers[lo], vers[hi], vers[m], cmd
        print vers

        print '#ugly = Nonese'

        ugly = False

        if build or must_make:
            result = make_ver(vers[m], vers[lo], vers[hi])
            print 'AMKE RESULT', result
            if result > 0:
                if must_make:
                    ugly = False
                    result = 1
                else:
                    ugly = True  # Not good, or bad, just ugly.
            else:
                result = run_cmd(cmd, vers[m])
        else:
            result = run_cmd(cmd, vers[m])
        
        if not ugly:
            if result > 127:
                print "result = ", result, " > 127"
                os._exit(1)
            ugly = result_ugly(result)
        if ugly:
            logline( vers[m] + ' is UGLY' )
            del vers[m]
            hi = len(vers) - 1
            m = randrange(0, len(vers))
        else:
            if result_after(result):
                logline( vers[m] + ' is AFTER')
                del vers[lo:m]
            else:
                logline( vers[m] + ' is BEFORE')
                del vers[m + 1:hi + 1]
            hi = len(vers) - 1
            m = (lo + hi + round_up) / 2

        print 'VERS REMAINING:', vers
        print >> outfile, 'VERS REMAINING:', vers

    return vers


def check_bisect(cmd, vers):
    lo = 0
    hi = len(vers) - 1
    l = vers[lo]
    h = vers[hi]
    if make_ver(l):
        return False
    if make_ver(h):
        return False
    if change_before(cmd, l):
        logline( 'Cannot bisect, change before ' + l\
             + ' or regression test invalid')
        return False
    if change_after(cmd, h):
        logline( 'Cannot bisect, change after ' + h\
             + ' or regression test invalid' )
        return False
    return True


def do_check_bisect(cmd, vers, build):
    print "do_check_bisect", vers
    print >> outfile, "do_check_bisect", vers
    if check_bisect(cmd, vers):
        return do_bisect(cmd, vers, build)
    else:
        print "check_bisect_failed"
        print >> outfile, "check_bisect_failed"
        return

def open_and_readlines(fname):
    f = open(fname, 'r')
    lines = f.readlines()
    for i in range(0, len(lines)):
        lines[i] = lines[i].rstrip('\n')
    return lines


def get_versions_between(L, H):
    return [`n` for n in xrange (int(L), int(H)+1)]

    #vers=[]
    #for v in (range(l,h+1)):
    #    vers.append(v)
    #return vers

    #svn log only reports changes on the directory object
    #so it doesn't report all relevant versions

    #vers = [f for f in open_and_readlines(all_versions_file)
    #        if version_in_range(f, l, h)]
    #vers.sort(cmp_version)
    #return vers


def get_cached_versions_between(l, h):
    vers = [f for f in get_cached_versions() if version_in_range(f, l, h)]
    if l not in vers:
        vers.append(l)
    if h not in vers:
        vers.append(h)
    vers.sort(cmp_version)
    print 'BTWN', l, h, vers
    return vers


def two_level_bisect(cmd, LO, HI):
    if make_ver(LO):
        return False
    if make_ver(HI):
        return False
    vers = get_cached_versions_between(LO, HI)
    print 'CACHED_VERSIONS', vers
    print >> outfile, 'CACHED_VERSIONS', vers
    if len(vers) > 2:
        vers = do_check_bisect(cmd, vers, True)
    print 'Closest Cached Versions', vers
    print >> outfile, 'Closest Cached Versions', vers
    if vers is None:
        return
    if len(vers) != 2:
        return
    vers = get_versions_between(vers[0], vers[1])
    print 'BETWEEN VERSIONS', vers
    vers = do_check_bisect(cmd, vers, True)
    print "END TWO LEVEL BISECT"
    rel_vers= get_versions_between(vers[0], vers[1])
    print 'Relevant Versions', rel_vers
    print >> outfile, 'Relevant Versions', rel_vers
    outfile.flush()
    for v in rel_vers:
	os.system('grep "^r' + v + ' " svn.log.*')
	os.system('grep "^r' + v + ' " svn.log.* >> ' + outfilename)
    
def check_system(cmd):
    result = os.system(cmd)
    if result != 0:
        logline ("CHECK_SYSTEM: " + cmd + "failed with " + str(result))
        os._exit(result)

def make_all_versions_file(VERS):
    svn_log_fname = 'svn.log.' + newest_ver
    svn_log_tmp_fname = svn_log_fname + '.tmp'
    if not os.path.exists(all_versions_file):
        logline("Making all_versions_file " + all_versions_file)
        make_from_old=False
        for ver in VERS:
            if os.path.exists("all_versions." + ver):
                make_from_old=True
                v=ver
                break
        if make_from_old:
            delta = int(newest_ver) - int(v)
            lines_needed = str(delta * 2)
            logline('Making all_versions_file' + all_versions_file +
                    ' from ' + v)
            make_log_cmd = '(cd ' + ver2dir(newest_ver) + ' && svn log -q) | head -n ' + lines_needed + ' > ' + svn_log_tmp_fname
            logline(make_log_cmd)
            check_system(make_log_cmd)
            make_ver_file_cmd = "(grep -o '^r[[:digit:]]*' " + svn_log_tmp_fname + ' | sed s/r// ; cat all_versions.' + v + ' ) | sort -urn > ' + all_versions_file
            logline(make_ver_file_cmd)
            check_system(make_ver_file_cmd)
            check_call(['mv', svn_log_tmp_fname, svn_log_fname])
            make_from_old=True
        else:
            if not os.path.exists(svn_log_fname):
                logline('Making log file ' + svn_log_tmp_fname)
                check_system('echo PWD1 `pwd`')
                check_system('(cd ' + ver2dir(newest_ver) +
                                      ' && svn log -q) > '+svn_log_tmp_fname)
                check_call(['mv ', svn_log_tmp_fname, svn_log_fname])
            logline('Making all_versions_file' + all_versions_file)
            
            #I get an error here but I cannot figure out why. It works if I run it from the command line.
            logline("grep -o '^r[[:digit:]]*' < " + svn_log_fname +
                    " | sed s/r// > "+all_versions_file) 
            check_call("grep -o '^r[[:digit:]]*' < " + svn_log_fname +
                       " | sed s/r// > "+all_versions_file) 


def multisect(cmd, vers):
    i = 1
    j = 0
    while i < len(vers):
        print >> outfile, 'MULTISECT', vers[i]
        print 'MULTISECT', vers[i]
        if make_ver(vers[i], vers[i-1])==0:
            if change_after(cmd, vers[i]):
                return two_level_bisect(cmd, vers[i], vers[j])
            else:
                j=i
        i = i + 1
    print >> outfile, "END MULTISECT"


def default_vers():
	vers_fname="default_vers.txt"
	if not os.path.exists(vers_fname):
		shutil.copyfile(vers_fname+".in",vers_fname)
	f=open(vers_fname,'r')
	lines=f.readlines()
	lines.reverse()
	return map(string.strip, lines)

print >> outfile, 'BISECT_BEGIN '
outfile.flush()
#final_vers = multisect('$TEST_COMMAND', ['30614', '27418', '23000'])
cmd = os.sys.argv
del cmd[0]

VERS = os.environ.get('VERS')
if VERS is None:
    if trunk:
	    #VERS = ['33612','33588','33522','33263','33051','32000', '30612','29473','27418','24000','20000']
            VERS = default_vers()
    else:
	    VERS = ['33347','31193', '28760']
else:
    VERS = VERS.split()

for v in VERS:
    # Mention that this directory has been used to multisect, so it should not
    # be automatically deleted
    check_system ("echo do not automatically delete > " + ver2dir(v) + ".multisect")

newest_ver = VERS[0]
#We may want to manually override this as follows:
#newest_ver='33263'

print VERS
print >> outfile, VERS 
print newest_ver
time.sleep(1)
make_ver(newest_ver)
if run_cmd(cmd, newest_ver) == 0:
    print 'Could not reproduce on directory:', newest_ver, '\n'
    logline ('Could not reproduce on directory:' + newest_ver + '\n')
    #check_call("./cache-add-dir.sh");
    check_call("./cache-add-dir.sh");
    logline ("/cache-add-dir.sh done\n")
    print "/cache-add-dir.sh done"
    VERS = default_vers()
    logline("Computed Vers")
    if newest_ver == VERS[0]:
        print 'Could not reproduce on up-to-date directory:', newest_ver, '\n'
        os._exit(1)
    else:
        newest_ver = VERS[0]
    	logline("About to make VER " + newest_ver + "\n")
        make_ver(newest_ver)
    	logline("made VER " + newest_ver + "\n")
        if run_cmd(cmd, newest_ver) == 0:
            print 'Could not reproduce on updated directory:', newest_ver, '\n'
            os._exit(1)

all_versions_file = "all_versions." + newest_ver

final_vers = multisect(cmd, VERS)
#final_vers = two_level_bisect('true', "21107","23000")
#final_vers = do_bisect('true', get_versions_between("21107","23000"),True)
outfile.flush()
print
print >> outfile, 'BISECT_FINAL', final_vers
print 'BISECT_FINAL', final_vers
os.system('echo BISECT_BEGIN >> /tmp/adsfadsf.log')
os.system('echo BISECT_FINAL >> /tmp/adsfadsf.log')

clean_up()
os._exit(0)
	
