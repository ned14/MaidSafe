#!/bin/sh

git fetch origin
git fetch main
git checkout next
git merge remotes/origin/next
git merge remotes/main/next

git submodule update --init --recursive
git submodule foreach git checkout next

cd src/rudp
git fetch main
git merge remotes/main/next
cd ../..

cd src/routing
git fetch main
git merge remotes/main/next
cd ../..

