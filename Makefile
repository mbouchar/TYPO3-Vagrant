UBUNTU_VERSION=16.04

PACKER_TEMPLATE=ubuntu-${UBUNTU_VERSION}.json

VAGRANT_PROVIDER=libvirt
VAGRANT_BOX=output/ubuntu-${UBUNTU_VERSION}-amd64-${VAGRANT_PROVIDER}.box
VAGRANT_BOX_NAME=${USER}/ubuntu

#VAGRANT_LOG=debug

LIBVIRT_VOL=`virsh vol-list default | grep ${USER}-VAGRANTSLASH-ubuntu | awk '{print $$1}')`

DIST_DIR=dist
TYPO3_DIST=${DIST_DIR}/typo3_src-8.7.4.tar.gz

default: build

build: ${TYPO3_DIST} ${VAGRANT_BOX}

${TYPO3_DIST}:
	wget --content-disposition get.typo3.org/current -P ${DIST_DIR}

${VAGRANT_BOX}: ${PACKER_TEMPLATE}
	packer build ${PACKER_TEMPLATE}

install: build
	vagrant box add ${VAGRANT_BOX} --name ${VAGRANT_BOX_NAME} --force

uninstall: testclean
	# Remove vagrant box
	if [ `vagrant box list | grep mbouchar/ubuntu | wc -l` -ne 0 ]; then \
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

fullclean: clean testclean uninstall

distclean: clean testclean
	if [ -e "packer_cache" ]; then \
	    rm -rf packer_cache \
	fi

.PHONY: build install uninstall clean test testclean fullclean distclean
