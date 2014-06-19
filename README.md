gns3-git-archlinux
==================

Build tools for gns3 1.0 alpha archlinux docker image
Does not contain iou or ios images for obvious reasons

on arch linux host

install build dependencies makepkg has dependency checking off so even build dependencies arnt checked :(
pacman -S cmake python-setuptools arch-install-scripts expect
./build-custom-repo.sh
sudo ./mkimage-gns3-arch.sh
#builds docker image ppickfor/gns3-iou
xhost + ;docker run -h gns3-iou -v ~/iou:/iou -v ~/ios:/ios -v /tmp/.X11-unix:/tmp/.X11-unix -e DISPLAY=unix/$DISPLAY -e LANG=en_US.UTF-8 -it  ppickfor/gns3:latest bash
python2 /iou/keygen.py
gns3
