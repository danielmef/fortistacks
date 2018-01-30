#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd ${DIR}

NAME="fortios_vnfd"

if ! [ -d "devops" ]; then
  echo "Devops dir not present, cloning...."
  git clone https://osm.etsi.org/gerrit/osm/devops
fi

rm -f ${NAME}.tar.gz

cd ${NAME}/charms/fortios

rm -rf builds/ deps/

charm build

if [ $? -ne 0 ]; then
  echo "Charm is not compiling... aborting."
  exit -1
fi

cd ${DIR}

./devops/descriptor-packages/tools/generate_descriptor_pkg.sh -t vnfd -N ${NAME}
