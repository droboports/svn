### ZLIB ###
_build_zlib() {
local VERSION="1.2.8"
local FOLDER="zlib-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://zlib.net/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --prefix="${DEPS}" --libdir="${DEST}/lib"
make
make install
rm -vf "${DEST}/lib/libz.a"
popd
}

### OPENSSL ###
_build_openssl() {
local VERSION="1.0.2d"
local FOLDER="openssl-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://mirror.switch.ch/ftp/mirror/openssl/source/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
cp -vf "src/${FOLDER}-parallel-build.patch" "target/${FOLDER}/"
pushd "target/${FOLDER}"
patch -p1 -i "${FOLDER}-parallel-build.patch"
./Configure --prefix="${DEPS}" --openssldir="${DEST}/etc/ssl" \
  zlib-dynamic --with-zlib-include="${DEPS}/include" --with-zlib-lib="${DEPS}/lib" \
  shared threads linux-armv4 -DL_ENDIAN ${CFLAGS} ${LDFLAGS} \
  -Wa,--noexecstack -Wl,-z,noexecstack
sed -i -e "s/-O3//g" Makefile
make
make install_sw
mkdir -p "${DEST}/libexec"
cp -vfa "${DEPS}/bin/openssl" "${DEST}/libexec/"
cp -vfa "${DEPS}/lib/libssl.so"* "${DEST}/lib/"
cp -vfa "${DEPS}/lib/libcrypto.so"* "${DEST}/lib/"
cp -vfaR "${DEPS}/lib/engines" "${DEST}/lib/"
cp -vfaR "${DEPS}/lib/pkgconfig" "${DEST}/lib/"
rm -vf "${DEPS}/lib/libcrypto.a" "${DEPS}/lib/libssl.a"
sed -e "s|^libdir=.*|libdir=${DEST}/lib|g" -i "${DEST}/lib/pkgconfig/libcrypto.pc"
sed -e "s|^libdir=.*|libdir=${DEST}/lib|g" -i "${DEST}/lib/pkgconfig/libssl.pc"
popd
}

### SQLITE ###
_build_sqlite() {
local VERSION="3081101"
local FOLDER="sqlite-autoconf-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://sqlite.org/2015/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --host="${HOST}" --prefix="${DEPS}" --libdir="${DEST}/lib" --disable-static
make
make install
popd
}

### EXPAT ###
_build_expat() {
local VERSION="2.1.0"
local FOLDER="expat-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://sourceforge.net/projects/expat/files/expat/${VERSION}/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --host="${HOST}" --prefix="${DEPS}" \
  --libdir="${DEST}/lib" --disable-static
make
make install
popd
}

### APR ###
_build_apr() {
local VERSION="1.5.2"
local FOLDER="apr-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://mirror.switch.ch/mirror/apache/dist/apr/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --host="${HOST}" --prefix="${DEPS}" \
  --libdir="${DEST}/lib" --disable-static \
  --enable-nonportable-atomics \
  ac_cv_file__dev_zero=yes ac_cv_func_setpgrp_void=yes \
  apr_cv_process_shared_works=yes apr_cv_mutex_robust_shared=no \
  apr_cv_tcp_nodelay_with_cork=yes ac_cv_sizeof_struct_iovec=8 \
  apr_cv_mutex_recursive=yes ac_cv_sizeof_pid_t=4 ac_cv_sizeof_size_t=4 \
  ac_cv_struct_rlimit=yes ap_cv_atomic_builtins=yes apr_cv_epoll=yes \
  apr_cv_epoll_create1=yes
export QEMU_LD_PREFIX="${TOOLCHAIN}/${HOST}/libc"
make
make install
popd
}

### APR-UTIL ###
_build_aprutil() {
local VERSION="1.5.4"
local FOLDER="apr-util-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://mirror.switch.ch/mirror/apache/dist/apr/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --host="${HOST}" --prefix="${DEPS}" \
  --libdir="${DEST}/lib" \
  --with-apr="${DEPS}" --without-apr-iconv \
  --with-crypto --with-openssl="${DEPS}" \
  --with-sqlite3="${DEPS}" --with-expat="${DEPS}"
make
make install
popd
}

### SERF ###
_build_serf() {
local VERSION="1.3.8"
local FOLDER="serf-${VERSION}"
local FILE="${FOLDER}.tar.bz2"
local URL="http://serf.googlecode.com/svn/src_releases/${FILE}"

_download_bz2 "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
scons PREFIX="${DEPS}" LIBDIR="${DEST}/lib" \
  CC="${CC}" CPPFLAGS="${CPPFLAGS}" CFLAGS="${CFLAGS}" LINKFLAGS="${LDFLAGS}" \
  APR="${DEPS}" APU="${DEPS}" OPENSSL="${DEPS}"
scons install
rm -vf "${DEST}/lib/libserf-1.a"
popd
}

### SVN ###
_build_svn() {
local VERSION="1.9.0"
local FOLDER="subversion-${VERSION}"
local FILE="${FOLDER}.tar.bz2"
local URL="http://mirror.switch.ch/mirror/apache/dist/subversion/${FILE}"

_download_bz2 "${FILE}" "${URL}" "${FOLDER}"
cp "src/${FOLDER}-no-mach-o-xcompile-test.patch" "target/${FOLDER}/"
pushd "target/${FOLDER}"
# Remove Mach-O test
patch -p1 -i "${FOLDER}-no-mach-o-xcompile-test.patch"
# Remove python dependency
echo "#!/bin/sh" > build/find_python.sh

./configure --host="${HOST}" --prefix="${DEST}" --mandir="${DEST}/man" \
  --disable-static \
  --with-apr="${DEPS}" --with-apr-util="${DEPS}" \
  --with-zlib="${DEPS}" --with-sqlite="${DEPS}" \
  --with-serf="${DEPS}" \
  --without-jdk --without-jikes --without-junit \
  --without-doxygen --without-swig \
  ac_cv_path_PERL=none ac_cv_path_RUBY=none

make
make install
popd
}

### CERTIFICATES ###
_build_certificates() {
# update CA certificates on a Debian/Ubuntu machine:
#sudo update-ca-certificates
cp -vf /etc/ssl/certs/ca-certificates.crt "${DEST}/etc/ssl/certs/"
ln -vfs certs/ca-certificates.crt "${DEST}/etc/ssl/cert.pem"
}

### BUILD ###
_build() {
  _build_zlib
  _build_openssl
  _build_sqlite
  _build_expat
  _build_apr
  _build_aprutil
  _build_serf
  _build_svn
  _build_certificates
  _package
}
