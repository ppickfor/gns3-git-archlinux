#!/bin/bash 
SCRIPTPATH=$(readlink -f $0)
SCRIPTPATH=${SCRIPTPATH%/*}
source ${SCRIPTPATH}/logme.sh
cd ${SCRIPTPATH}
[ -d repo ] || mkdir repo
TMPDIR=$(mktemp -d /tmp/build_XXXXXXX)
trap "{ /bin/rm -rf ${TMPDIR} ; exit 255; }" SIGINT SIGTERM
PACKAGES=(python-apache-libcloud python-netifaces-git ws4py)
GNS3PACKAGES=(dynamips-git  gns3-gui-git  gns3-server-git  iouyap-git  vpcs-git)
cp -r "${GNS3PACKAGES[@]}" ${TMPDIR}/
for PACKAGE in "${GNS3PACKAGES[@]}"
do
	[ -f ${SCRIPTPATH?}/repo/${PACKAGE}*.pkg.tar.* ] && continue
	cd ${TMPDIR}/${PACKAGE}
	makepkg -d
	mv ${TMPDIR}/${PACKAGE}/*.pkg.tar.* ${SCRIPTPATH?}/repo/
done
for PACKAGE in "${PACKAGES[@]}"
do
	[ -f ${SCRIPTPATH?}/repo/${PACKAGE}*.pkg.tar.* ] && continue
	cd ${TMPDIR}
	curl -O https://aur.archlinux.org/packages/${PACKAGE:0:2}/${PACKAGE}/${PACKAGE}.tar.gz
	tar xzf ${PACKAGE}.tar.gz
	cd ${TMPDIR}/${PACKAGE}
	makepkg -d
	mv ${TMPDIR}/${PACKAGE}/*.pkg.tar.* ${SCRIPTPATH?}/repo/
done
rm -rf ${TMPDIR}
cd ${SCRIPTPATH}
repo-add repo/custom.db.tar.gz repo/*.pkg.*
