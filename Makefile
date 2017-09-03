PACKER_TEMPLATE=ubuntu-16.04.json

VAGRANT_PROVIDER=libvirt
VAGRANT_BOX=ubuntu-16.04-amd64-${VAGRANT_PROVIDER}.box
VAGRANT_BOX_NAME=${USER}/ubuntu

#VAGRANT_LOG=debug

default: build

build: ${VAGRANT_BOX}

${VAGRANT_BOX}: ${PACKER_TEMPLATE}
	packer build ${PACKER_TEMPLATE}

install: build
	vagrant box add ${VAGRANT_BOX} --name ${VAGRANT_BOX_NAME} --force

clean:
	rm -f ${VAGRANT_BOX}

distclean: clean testclean
	vagrant box remove ${VAGRANT_BOX_NAME}

test: testclean
	vagrant init ${VAGRANT_BOX_NAME}
	vagrant up --provider=${VAGRANT_PROVIDER}

testclean:
	if [ -e "Vagrantfile" ]; then \
	    vagrant destroy; \
	    rm -f Vagrantfile; \
	fi

.PHONY: build install clean distclean test testclean
