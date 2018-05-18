#!/bin/bash
set -x -e

##
## Build the Docs
##

# if run from the vagrant project switch to linode-api-docs to mimic baker
[[ -d "linode-api-docs" ]] && cd linode-api-docs

export HOME='/target'
echo $HOME

version_number=$(git describe --tags --abbrev=0 | tr -d '[:space:]')
version_extension=$(git log ${version_number}..HEAD --oneline | wc -l | tr -d '[:space:]')

version=${version_number}-${version_extension}

echo 'Building Debian Package'
# index.html, openapi.yaml
package_version="${version}"
description='Linode API Docs'
pkg_name="linode-docs"
replaces="linode-alpha-docs,linode-vagrant-docs"

if [ -v BUILD_ENV -a -n "${BUILD_ENV}" ]; then
  description="${description} ($BUILD_ENV)"
  package_version="${version}~${BUILD_ENV}${commit_num:-0}"
fi

fpm -s dir -t deb -n "${pkg_name}" -v "${version_number}" --iteration "${version_extension}" \
  -x Vagrantfile -x Dockerfile -x build.sh -x \*.deb -x \*.changes -x .git -x .vagrant \
  --vendor Linode --url https://github.com/linode/linode-api-docs \
  --description "${description}" -m ops@linode.com \
  -a all --prefix /usr/share/linode-docs/templates/ \
  --after-install linode-docs.postinst \
  --replaces "${replaces}" -- \
  index.html openapi.yaml linode-logo.svg redoc.standalone.js \
  favicon.ico changelog/index.html changelog/changelog-style.css linode-logo-white.svg

outfile="$(ls -t ${pkg_name}*_all.deb | head -1)"
sha1=$(sha1sum ${outfile})
sha256=$(sha256sum ${outfile})
md5=$(md5sum ${outfile})
size=$(stat -c%s "$outfile")

(
cat <<EOF
Format: 1.8
Date: $(date -R)
Source: ${pkg_name}
Binary: ${pkg_name}
Architecture: all
Version: ${version}
Distribution: linode-jessie-dev
Urgency: low
Maintainer: Linode Operations <ops@linode.com>
Changed-By: Linode Developers <devs+manager@linode.com>
Description:
 ${description}
Changes:
 ${pkg_name} (${package_version}) linode-jessie-dev; urgency=low
  .
  * $(git log -1 --pretty=format:%s)
Checksums-Sha1:
 ${sha1% *} ${size} ${outfile}
Checksums-Sha256:
 ${sha256% *} ${size} ${outfile}
Files:
 ${md5% *} ${size} linode-jessie-dev/api extra ${outfile}
EOF
) > ${outfile::-3}changes