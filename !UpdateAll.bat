rem @cmd /c "%~dpn0.sh %*"

rem attrib +r !UpdateAll.bat
git fetch origin
git fetch main
git checkout next
git merge remotes/origin/next
git merge remotes/main/next
rem git checkout -f next_ned14
rem git merge next

git submodule update --init --recursive
git submodule foreach git checkout next
rem git checkout next

cd src\rudp
git fetch main
git merge remotes/main/next
cd ..\..

cd src\routing
git fetch main
git merge remotes/main/next
cd ..\..
