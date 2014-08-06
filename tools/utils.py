#!/usr/bin/env python
# Copyright (c) 2012 maidsafe.net limited
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
#
#     * Redistributions of source code must retain the above copyright notice,
#     this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright notice,
#     this list of conditions and the following disclaimer in the documentation
#     and/or other materials provided with the distribution.
#     * Neither the name of the maidsafe.net limited nor the names of its
#     contributors may be used to endorse or promote products derived from this
#     software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
# TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
# THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import socket
import platform
import os
import sys
import psutil
import subprocess
import multiprocessing

# MaidSafe imports
import vault_killer


all = { 'Common' : 'common', 'Rudp' : 'rudp', 'Routing' : 'routing',
        'Private' : 'private', 'Pd' : 'pd', 'Encrypt' : 'encrypt',
        'Drive' : 'drive', 'Lifestuff' : 'lifestuff' }


def TimeOut(func, args=(), kwargs={}, timeout_duration=10, default=None):
  """This function will spawn a thread and run the given function
  using the args, kwargs and return the given default value if the
  timeout_duration is exceeded.
  """ 
  import threading
  class InterruptableThread(threading.Thread):
    def __init__(self):
      threading.Thread.__init__(self)
      self.result = default
    def run(self):
      self.result = func(*args, **kwargs)
  it = InterruptableThread()
  it.start()
  it.join(timeout_duration)
  return it.result
#  if it.isAlive():
#    try:
#      it._Thread__stop()
#    except:
#      print(str(it.getName()) + " could not be terminated")
#  return result

def LookingFor(proc, keyword, line_limit, required_repeated_time):
  i = 0
  repeated_time = 0
  while i < (line_limit * required_repeated_time):
    line = str(proc.stdout.readline())
    print(line.strip("\r\n"))
    if line.find(keyword) != -1:
      repeated_time = repeated_time + 1
      if repeated_time == required_repeated_time:
        return True
    i = i + 1
  return False

def ClearScreen():
  os.system( [ 'clear', 'cls' ][ platform.system() == 'Windows' ] )

def ResetScreen():
  os.system( [ 'reset', 'cls' ][ platform.system() == 'Windows' ] )


def CppLint():
  encoding = sys.getfilesystemencoding()
  script_path = os.path.dirname(unicode(__file__, encoding))
  return os.path.join(script_path, 'cpplint.py')


def CountProcs(name):
  num = 0
  for proc in psutil.process_iter():
    try:
      if proc.name.find(name) >= 0:
         num = num + 1
    except:
      pass
  return num


def YesNo(question, default='yes'):
  valid = { 'yes':True, 'y':True, 'ye':True, 'no':False, 'n':False }
  if default == None:
    prompt = ' [y/n] '
  elif default == 'yes':
    prompt = ' [Y/n] '
  elif default == 'no':
    prompt = ' [y/N] '
  else:
    raise ValueError("invalid default answer: '%s'" % default)

  while True:
    sys.stdout.write(question + prompt)
    choice = raw_input().lower()
    if default is not None and choice == '':
      return valid[default]
    elif choice in valid:
      return valid[choice]
    else:
      sys.stdout.write("Please respond with 'yes' or 'no' (or 'y' or 'n').\n")


def GetIp():
  s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
  s.connect(('8.8.8.8', 53))
  ip = s.getsockname()[0]
  s.close()
  return ip


def GetProg(prog):
  if platform.system() == 'Windows':
    return os.path.join(os.curdir, prog + '.exe')
  else:
    return os.path.join(os.curdir, prog)


def CheckCurDirIsBuildDir():
  if FindFile('lifestuff_python_api', os.path.join(os.curdir), ('.so','.pyd')) != None:
    return True
  print("The current working directory does not contain lifestuff_python_api")
  if not YesNo('Do you want to build lifestuff_python_api in this directory?'):
    print("You need to run this script from a build directory.")
    return False

  build_type = ''
  while build_type == '':
    sys.stdout.write('Specify Debug [d], Release [r], RelWithDebInfo [rwdi], or MinSizeRel [msr]: ')
    choice = raw_input().lower()
    if choice == 'd':
      build_type = 'Debug'
    elif choice == 'r':
      build_type = 'Release'
    elif choice == 'rwdi':
      build_type = 'RelWithDebInfo'
    elif choice == 'msr':
      build_type = 'MinSizeRel'

  if platform.system() == 'Windows':
    return subprocess.call(['cmake', '--build', '.', '--target', 'lifestuff_python_api', '--config', build_type]) == 0
  else:
    if subprocess.call(['cmake', '..', '-DCMAKE_BUILD_TYPE=' + build_type]) != 0:
      return False
    return subprocess.call(['cmake', '--build', '.', '--target', 'lifestuff_python_api']) == 0


def BuildType():
  with open(os.path.join(os.curdir, 'CMakeCache.txt')) as cmake_cache:
    content = cmake_cache.readlines()
  if any('CMAKE_BUILD_TYPE:STRING=Debug' in s for s in content):
    return 'Debug'
  if any('CMAKE_BUILD_TYPE:STRING=Release' in s for s in content):
    return 'Release'


def GetLib():
  option = ''
  while option.lower() not in all.values() and option != 'q':
    print("Libraries available")
    print("-------------------")
    for key, value in all.iteritems():
      print(key)
    print("-------------------")
    option = raw_input('please type library name (q to exit): ')
  return option


def StyleCheck():
  option = GetLib()
  if option == 'q':
    ClearScreen()
    return
  directory = os.path.join(os.path.curdir, '..', 'src', option)
  style_check = ''
  for r,d,f in os.walk(directory):
    for files in f:
      if (files.endswith('.cc') or files.endswith('.h')) and not \
         (files.endswith('.pb.cc') or files.endswith('.pb.h')):
        style_check = os.path.join(r,files)
        subprocess.call(['python', CppLint() , style_check])


def FindFile(name, path=None, exts=('','.exe')):
  path = path or os.environ['PATH']
  for dir in path.split(os.pathsep):
    for ext in exts:
      binpath = os.path.join(dir, name) + ext
      if os.path.exists(binpath):
        return os.path.abspath(binpath)
  return None


def CppCheck():
  checker = FindFile('cppcheck')
  if checker == None:
    return
  option = GetLib()
  if option == 'q':
    ClearScreen()
    return
  directory = os.path.join(os.path.curdir, '..', 'src', option)
  style_check = ''
  for r,d,f in os.walk(directory):
    for files in f:
      if (files.endswith('.cc') or files.endswith('.h')):
        file_to_check = os.path.join(r,files)
        subprocess.call([checker, file_to_check])
  return checker


def work(cmd):
  return subprocess.call(cmd, shell=False)


def RunNetwork(number_of_vaults):
  pool = multiprocessing.Pool(processes=number_of_vaults)
  pool.map(work, [FindFile('test_common', os.curdir)] * number_of_vaults)


def main():
  ClearScreen()
  if not utils.CheckCurDirIsBuildDir():
    return -1


if __name__ == '__main__':
      sys.exit(main())
