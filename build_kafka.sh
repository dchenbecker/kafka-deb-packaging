#!/bin/bash
set -e
set -u
name=kafka
version=0.8.2.1
scalaVersion=2.11.5
description="Apache Kafka is a distributed publish-subscribe messaging system."
url="https://kafka.apache.org/"
arch="all"
section="misc"
license="Apache Software License 2.0"
package_version="-1"
src_package="kafka-${version}-src.tgz"
download_url="http://mirrors.sonic.net/apache/kafka/${version}/${src_package}"
origdir="$(pwd)"
gradleVersion=2.3
gradleZip="gradle-${gradleVersion}-bin.zip"
gradleUrl="https://services.gradle.org/distributions/${gradleZip}"

#_ MAIN _#
rm -rf ${name}*.deb
if [[ ! -f "${src_package}" ]]; then
  wget ${download_url}
fi
mkdir -p tmp && pushd tmp
# Get gradle set up
rm -f ${gradleZip}
rm -rf gradle-${gradleVersion}
wget ${gradleUrl}
unzip ${gradleZip}
# Get kafka source build ready
rm -rf kafka
mkdir -p kafka
cd kafka
mkdir -p build/usr/lib/kafka/{bin,libs,config}
mkdir -p build/etc/default
mkdir -p build/etc/init
mkdir -p build/etc/kafka
mkdir -p build/var/log/kafka

tar zxf ${origdir}/${src_package}
cd kafka-${version}-src
../../gradle-${gradleVersion}/bin/gradle
./gradlew -PscalaVersion=${scalaVersion} jar
cp -v ${origdir}/artifacts/log4j.properties config/server.properties ../build/etc/kafka/
cp -v bin/kafka*.sh ../build/usr/lib/kafka/bin/
cp -v clients/build/libs/* core/build/libs/* core/build/dependant-libs-${scalaVersion}/* ../build/usr/lib/kafka/libs/

cd ../build

fpm -t deb \
    -n ${name} \
    -v ${version}${package_version} \
    --description "${description}" \
    --url="{$url}" \
    -a ${arch} \
    --category ${section} \
    --vendor "" \
    --license "${license}" \
    -m "${MAINTAINER:-$USER@localhost}" \
    --prefix=/ \
    -s dir \
    -d java7-runtime \
    --deb-default ${origdir}/artifacts/default/kafka-broker \
    --deb-upstart ${origdir}/artifacts/upstart/kafka-broker \
    -- .
mv kafka*.deb ${origdir}
popd
