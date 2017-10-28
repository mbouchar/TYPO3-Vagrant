DISTRIB_NAME=ubuntu
DISTRIB_VERSION=16.04

PACKER_TEMPLATE=${DISTRIB_NAME}-${DISTRIB_VERSION}.json

VAGRANT_PROVIDER=libvirt
VAGRANT_BOX_VARIANT=typo3-8-lts
VAGRANT_BOX_NAME=${USER}/${VAGRANT_BOX_VARIANT}
#VAGRANT_LOG=debug
VAGRANT_BOX=output/${DISTRIB_NAME}-${DISTRIB_VERSION}-amd64-${VAGRANT_PROVIDER}.box

DIST_DIR=dist
TYPO3_VERSION=8.7.8
TYPO3_URL=get.typo3.org/${TYPO3_VERSION}
TYPO3_DIST=${DIST_DIR}/typo3_src-${TYPO3_VERSION}.tar.gz

LIBVIRT_VOL=`virsh vol-list default | grep ${USER}-VAGRANTSLASH-${VAGRANT_BOX_VARIANT} | awk '{print $$1}')`

default: build

build: ${TYPO3_DIST} ${VAGRANT_BOX}

${TYPO3_DIST}:
	wget --content-disposition ${TYPO3_URL} -P ${DIST_DIR}

${VAGRANT_BOX}: ${PACKER_TEMPLATE}
	packer build -var 'typo3_version=${TYPO3_VERSION}' -var 'iso_version=${DISTRIB_VERSION}' ${PACKER_TEMPLATE}

install: build
	vagrant box add ${VAGRANT_BOX} --name ${VAGRANT_BOX_NAME} --force

uninstall: testclean
	# Remove vagrant box
	if [ `vagrant box list | grep ${VAGRANT_BOX_NAME} | wc -l` -ne 0 ]; then \
	    vagrant box remove ${VAGRANT_BOX_NAME}; \
	fi
	# Remove libvirt volume from storage pool
	if [ "${LIBVIRT_VOL}" != "" ]; then \
	    virsh vol-delete --pool default ${LIBVIRT_VOL}; \
	fi

clean:
	if [ -e "${VAGRANT_BOX}" ]; then \
	    rm -f ${VAGRANT_BOX}; \
	fi

test: testclean install
	if [ ! -e "Vagrantfile" ]; then \
	    vagrant init ${VAGRANT_BOX_NAME}; \
	fi
	vagrant up --provider=${VAGRANT_PROVIDER}

testclean:
	if [ -e "Vagrantfile" ]; then \
	    if [ `vagrant status | grep running | wc -l` -ne 0 ]; then \
	        vagrant destroy; \
	    fi; \
	    rm -f Vagrantfile; \
	fi

distclean: clean testclean
	if [ -e "packer_cache" ]; then \
	    rm -rf packer_cache; \
	fi

fullclean: distclean uninstall

.PHONY: build install uninstall clean test testclean fullclean distclean
