#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd ${DIR}

NAME="fortios_nsd"

if ! [ -d "devops" ]; then
  echo "Devops dir not present, cloning...."
  git clone https://osm.etsi.org/gerrit/osm/devops
fi

rm -f ${NAME}.tar.gz

./devops/descriptor-packages/tools/generate_descriptor_pkg.sh -t nsd -N ${NAME}
