#!/usr/bin/env bash

# Debug this script if in debug mode
(( $DEBUG == 1 )) && set -x

# Import dsip_lib utility / shared functions if not already
if [[ "$DSIP_LIB_IMPORTED" != "1" ]]; then
    . ${DSIP_PROJECT_DIR}/dsiprouter/dsip_lib.sh
fi

# search for RPM using external APIs mirrors and archives
# not guaranteed to find an RPM, outputs empty string if search fails
# arguments:
#   $1 == rpm to search for
# options:
#   -a <arch filter>
#   --arch=<arch filter>
#   -d <distro filter>
#   --distro=<distro filter>
#   -f <grep filter>
#   --filter=<grep filter>
#function rpmSearch() {
#    local RPM_SEARCH="" DISTRO_FILTER="" ARCH_FILTER="" GREP_FILTER="" SEARCH_RESULTS=""
#
#    while (( $# > 0 )); do
#        # last arg is user and database
#        if (( $# == 1 )); then
#            RPM_SEARCH="$1"
#            shift
#            break
#        fi
#
#        case "$1" in
#            -a)
#                shift
#                ARCH_FILTER="$1"
#                shift
#                ;;
#            --arch=*)
#                ARCH_FILTER="$(echo "$1" | cut -d '=' -f 2)"
#                shift
#                ;;
#            -d)
#                shift
#                DISTRO_FILTER="$1"
#                shift
#                ;;
#            --distro=*)
#                DISTRO_FILTER="$(echo "$1" | cut -d '=' -f 2)"
#                shift
#                ;;
#            -f)
#                shift
#                GREP_FILTER="$1"
#                shift
#                ;;
#            --filter=*)
#                GREP_FILTER="$(echo "$1" | cut -d '=' -f 2)"
#                shift
#                ;;
#        esac
#    done
#
#    # if grep filter not set it defaults to rpm search
#    if [[ -z "$GREP_FILTER" ]]; then
#        GREP_FILTER="${RPM_SEARCH}"
#    fi
#
#    # grab the results of the search using an API on rpmfind.net
#    SEARCH_RESULTS=$(
#        curl -sL "https://www.rpmfind.net/linux/rpm2html/search.php?query=${RPM_SEARCH}&system=${DISTRO_FILTER}&arch=${ARCH_FILTER}" 2>/dev/null |
#            perl -e "\$rpmfind_base_url='https://rpmfind.net'; \$rpm_search='${RPM_SEARCH}'; @matches=(); " -0777 -e \
#                '$html = do { local $/; <STDIN> };
#                @matches = ($html =~ m%(?<=\<a href=["'"'"'])([-a-zA-Z0-9\@\:\%\._\+~#=/]*${rpm_search}[-a-zA-Z0-9\@\:\%\._\+\~\#\=]*\.rpm)(?=["'"'"']\>)%g);
#                foreach my $match (@matches) { print "${rpmfind_base_url}${match}\n"; }' 2>/dev/null |
#            grep -m 1 "${GREP_FILTER}"
#    )
#
#    if [[ -n "$SEARCH_RESULTS" ]]; then
#        echo "$SEARCH_RESULTS"
#    fi
#}

# compile and install rtpengine from RPM's
function install {
    local OS_ARCH=$(uname -m)
    local OS_KERNEL=$(uname -r)
    local RHEL_BASE_VER=$(rpm -E %{rhel})

    # Install required libraries
    amazon-linux-extras enable -y GraphicsMagick1.3 >/dev/null
    amazon-linux-extras enable -y redis6 >/dev/null
    amazon-linux-extras install -y epel >/dev/null
    yum groupinstall --setopt=group_package_types=mandatory,default,optional -y 'Development Tools'

    yum install -y gcc glib2 glib2-devel zlib zlib-devel openssl openssl-devel pcre pcre-devel libcurl libcurl-devel \
        xmlrpc-c xmlrpc-c-devel libpcap libpcap-devel hiredis hiredis-devel json-glib json-glib-devel libevent libevent-devel \
        iptables iptables-devel xmlrpc-c-devel gperf system-lsb redhat-rpm-config rpm-build rpmrebuild pkgconfig \
        freetype-devel fontconfig-devel libxml2-devel nc dkms logrotate rsyslog perl perl-IPC-Cmd spandsp-devel bc libwebsockets-devel \
        gperf gperftools gperftools-devel gperftools-libs gzip mariadb-devel perl-Config-Tiny spandsp \
        libbluray-devel libavcodec-devel libavformat-devel libavutil-devel libswresample-devel libavfilter-devel \
        libjpeg-turbo-devel mosquitto-devel glib2-devel xmlrpc-c-devel hiredis-devel libpcap-devel libevent-devel json-glib-devel \
        gperf nasm yasm yasm-devel autoconf automake bzip2 bzip2-devel libtool make mercurial libtiff-devel
    yum install -y kernel-devel-${OS_KERNEL} kernel-headers-${OS_KERNEL}

    if (( $? != 0 )); then
        printerr "Problem with installing the required libraries for RTPEngine"
        exit 1
    fi

    # create rtpengine user and group
    # sometimes locks aren't properly removed (this seems to happen often on VM's)
    rm -f /etc/passwd.lock /etc/shadow.lock /etc/group.lock /etc/gshadow.lock &>/dev/null
    userdel rtpengine &>/dev/null; groupdel rtpengine &>/dev/null
    useradd --system --user-group --shell /bin/false --comment "RTPengine RTP Proxy" rtpengine

    ## compile and install libxh264
    if [[ ! -d ${SRC_DIR}/libxh264 ]]; then
        git clone --depth 1 https://code.videolan.org/videolan/x264 ${SRC_DIR}/libxh264
    fi
    ( cd ${SRC_DIR}/libxh264 && ./configure --prefix=/usr --libdir=/usr/lib64 --enable-static && make && make install; exit $?; ) ||
    { printerr 'Failed to compile and install libxh264'; return 1; }

    ## compile and install libx265
    if [[ ! -d ${SRC_DIR}/libx265 ]]; then
        git clone --depth 1 https://github.com/videolan/x265 ${SRC_DIR}/libx265
    fi
    ( cd ${SRC_DIR}/libx265/build/linux && rm -rf ${SRC_DIR}/libx265/.git &&
        cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX=/usr -DLIB_INSTALL_DIR=/usr/lib64 \
        -DENABLE_SHARED=FALSE ../../source && make && make install; exit $?;
    ) || { printerr 'Failed to compile and install libx265'; return 1; }

    ## compile and install libfdkaac
    if [[ ! -d ${SRC_DIR}/libfdkaac ]]; then
        git clone --depth 1 https://github.com/mstorsjo/fdk-aac ${SRC_DIR}/libfdkaac
    fi
    ( cd ${SRC_DIR}/libfdkaac && autoreconf -i && ./configure --prefix=/usr --libdir=/usr/lib64 --disable-shared && make && make install; exit $?; ) ||
    { printerr 'Failed to compile and install libfdkaac'; return 1; }

    ## compile and install libmp3lame
    if [[ ! -d ${SRC_DIR}/libmp3lame ]]; then
        git clone --depth 1 https://github.com/gypified/libmp3lame.git ${SRC_DIR}/libmp3lame
    fi
    ( cd ${SRC_DIR}/libmp3lame && ./configure --prefix=/usr --libdir=/usr/lib64 --disable-shared --enable-nasm && make && make install; exit $?; ) ||
    { printerr 'Failed to compile and install libmp3lame'; return 1; }

    ## compile and install libopus
    if [[ ! -d ${SRC_DIR}/libopus ]]; then
        git clone --depth 1 https://gitlab.xiph.org/xiph/opus.git ${SRC_DIR}/libopus ||
        git clone --depth 1 https://github.com/xiph/opus.git ${SRC_DIR}/libopus
    fi
    ( cd ${SRC_DIR}/libopus && autoreconf -i && ./configure --prefix=/usr --libdir=/usr/lib64 --disable-shared && make && make install; exit $?; ) ||
    { printerr 'Failed to compile and install libopus'; return 1; }

    ## compile and install libvpx
    if [[ ! -d ${SRC_DIR}/libvpx ]]; then
        git clone --depth 1 https://chromium.googlesource.com/webm/libvpx.git ${SRC_DIR}/libvpx
    fi
    ( cd ${SRC_DIR}/libvpx && ./configure --prefix=/usr --libdir=/usr/lib64 --disable-examples --disable-unit-tests --enable-vp9-highbitdepth --as=yasm &&
        make && make install; exit $?;
    ) || { printerr 'Failed to compile and install libvpx'; return 1; }

    ## compile and install ffmpeg
    if [[ ! -d ${SRC_DIR}/ffmpeg ]]; then
        git clone --depth 1 https://git.ffmpeg.org/ffmpeg.git ${SRC_DIR}/ffmpeg ||
        git clone --depth 1 https://github.com/FFmpeg/FFmpeg.git ${SRC_DIR}/ffmpeg
    fi
    ( cd ${SRC_DIR}/ffmpeg && ./configure --prefix=/usr --libdir=/usr/lib64 --pkg-config-flags="--static" --extra-libs=-lpthread --extra-libs=-lm \
        --enable-gpl --enable-libfdk-aac --enable-libfreetype --enable-libmp3lame --enable-libopus --enable-libvpx --enable-libx264 --enable-libx265 \
        --enable-nonfree && make && make install; exit $?;
    ) || { printerr 'Failed to compile and install ffmpeg'; return 1; }

    ## compile and install librabbitmq
    if [[ ! -d ${SRC_DIR}/librabbitmq ]]; then
        git clone --depth 1 -b v0.11.0 https://github.com/alanxz/rabbitmq-c.git ${SRC_DIR}/librabbitmq
    fi
    ( cd ${SRC_DIR}/librabbitmq && mkdir -p build && cd build/ && cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_INSTALL_LIBDIR=lib64 \
        -DBUILD_EXAMPLES=FALSE -DBUILD_TESTS=FALSE .. && make && make install; exit $?;
    ) || { printerr 'Failed to compile and install librabbitmq'; return 1; }

    ## compile and install libspandsp
    if [[ ! -d ${SRC_DIR}/libspandsp ]]; then
        git clone --depth 1 https://github.com/freeswitch/spandsp.git ${SRC_DIR}/libspandsp
    fi
    ( cd ${SRC_DIR}/libspandsp && ./bootstrap.sh && ./configure --prefix=/usr --libdir=/usr/lib64 && make && make install; exit $?; ) ||
    { printerr 'Failed to compile and install libspandsp'; return 1; }

    ## compile and install libwebsockets
    if [[ ! -d ${SRC_DIR}/libwebsockets ]]; then
        git clone --depth 1 https://github.com/warmcat/libwebsockets.git ${SRC_DIR}/libwebsockets
    fi
    ( cd ${SRC_DIR}/libwebsockets && mkdir -p build && cd build/ && cmake -DCMAKE_INSTALL_PREFIX=/usr -DLIB_SUFFIX=64 -DLWS_WITH_HTTP2=1 \
        -DLWS_OPENSSL_INCLUDE_DIRS=${SRC_DIR}/openssl/include -DLWS_OPENSSL_LIBRARIES="${SRC_DIR}/openssl/libssl.so;${SRC_DIR}/openssl/libcrypto.so" .. &&
        make && make install; exit $?;
    ) || { printerr 'Failed to compile and install libwebsockets'; return 1; }

    ## compile and install RTPEngine as an RPM package
    ## reuse repo if it exists and matches version we want to install
    if [[ -d ${SRC_DIR}/rtpengine ]]; then
        if [[ "x$(cd ${SRC_DIR}/rtpengine 2>/dev/null && git branch --show-current 2>/dev/null)" != "x${RTPENGINE_VER}" ]]; then
            rm -rf ${SRC_DIR}/rtpengine
            git clone --depth 1 -b ${RTPENGINE_VER} https://github.com/sipwise/rtpengine.git ${SRC_DIR}/rtpengine
        fi
    else
        git clone --depth 1 -b ${RTPENGINE_VER} https://github.com/sipwise/rtpengine.git ${SRC_DIR}/rtpengine
    fi

    RTPENGINE_RPM_VER=$(grep -oP 'Version:.+?\K[\w\.\~\+]+' ${SRC_DIR}/rtpengine/el/rtpengine.spec)
    if (( $(echo "$RTPENGINE_VER" | perl -0777 -pe 's|mr(\d+\.\d+)\.(\d+)\.(\d+)|\1\2\3 >= 6.511|gm' | bc -l) )); then
        PREFIX="rtpengine-${RTPENGINE_RPM_VER}"
    else
        PREFIX="ngcp-rtpengine-${RTPENGINE_RPM_VER}"
    fi

    RPM_BUILD_ROOT="${HOME}/rpmbuild"
    rm -rf ${RPM_BUILD_ROOT} 2>/dev/null
    mkdir -p ${RPM_BUILD_ROOT}/SOURCES &&
    (
        # some packages had to be compiled from source and therefore the default rpm build will fail
        # we remove these from the the rpm spec files so we can still reliably install the other deps
        # this also allows us to keep the standard post/pre build configurations from the spec file
        perl -i -pe 's|(%define archname) rtpengine-mr|\1 rtpengine-|; s|(BuildRequires:  ffmpeg-devel)|#\1|;' \
            -pe 's|(Requires.*ffmpeg-libs)|#\1|; s|(BuildRequires:.*%{mysql_devel_pkg}) ffmpeg-devel|\1|;' \
            -pe 's|(BuildRequires.*pkgconfig.spandsp.)|#\1|; s|(BuildRequires.*pkgconfig.libwebsockets.)|#\1|;' \
             ${SRC_DIR}/rtpengine/el/rtpengine.spec &&
        cd ${SRC_DIR} &&
        tar -czf ${RPM_BUILD_ROOT}/SOURCES/ngcp-rtpengine-${RTPENGINE_RPM_VER}.tar.gz --transform="s%^rtpengine%${PREFIX}%g" rtpengine/ &&
        # build the RPM's
        rpmbuild -ba ${SRC_DIR}/rtpengine/el/rtpengine.spec &&
        rpmrebuild --change-spec-requires='sed -re "/^(Requires:.*)(libspandsp\.so|libwebsockets\.so).*/d"' \
            -bp ${RPM_BUILD_ROOT}/RPMS/${OS_ARCH}/ngcp-rtpengine-${RTPENGINE_RPM_VER}*.rpm &&
        # install the RPM's
        yum localinstall -y ${RPM_BUILD_ROOT}/RPMS/${OS_ARCH}/ngcp-rtpengine-${RTPENGINE_RPM_VER}*.rpm \
            ${RPM_BUILD_ROOT}/RPMS/noarch/ngcp-rtpengine-dkms-${RTPENGINE_RPM_VER}*.rpm \
            ${RPM_BUILD_ROOT}/RPMS/${OS_ARCH}/ngcp-rtpengine-kernel-${RTPENGINE_RPM_VER}*.rpm
#            ${RPM_BUILD_ROOT}/RPMS/${OS_ARCH}/ngcp-rtpengine-recording-${RTPENGINE_RPM_VER}*.rpm
        exit $?
    )

    if (( $? != 0 )); then
        printerr "Problem installing RTPEngine RPM's"
        exit 1
    fi

    # make sure RTPEngine kernel module configured
    if [[ -z "$(find /lib/modules/${OS_KERNEL}/ -name 'xt_RTPENGINE.ko' 2>/dev/null)" ]]; then
        printerr "Problem installing RTPEngine kernel module"
        exit 1
    fi

    # stop the demaon so we can configure it properly
    systemctl stop ngcp-rtpengine-daemon

    # ensure config dirs exist
    mkdir -p /var/run/rtpengine ${SYSTEM_RTPENGINE_CONFIG_DIR}
    chown -R rtpengine:rtpengine /var/run/rtpengine

    # rtpengine config file
    # ref example config: https://github.com/sipwise/rtpengine/blob/master/etc/rtpengine.sample.conf
    # TODO: move from 2 seperate config files to generating entire config
    #       1st we should change to generating config using rtpengine-start-pre
    #       eventually we should create a config parser similar to how kamailio config is parsed
    cp -f ${DSIP_PROJECT_DIR}/rtpengine/configs/rtpengine.conf ${SYSTEM_RTPENGINE_CONFIG_FILE}

    # setup rtpengine defaults file
    cp -f ${DSIP_PROJECT_DIR}/rtpengine/configs/default.conf /etc/default/rtpengine.conf

    # Enable and start firewalld if not already running
    systemctl enable firewalld
    systemctl start firewalld

    # Fix for bug: https://bugzilla.redhat.com/show_bug.cgi?id=1575845
    if (( $? != 0 )); then
        systemctl restart dbus
        systemctl restart firewalld
    fi

    # Setup Firewall rules for RTPEngine
    firewall-cmd --zone=public --add-port=${RTP_PORT_MIN}-${RTP_PORT_MAX}/udp --permanent
    firewall-cmd --reload

    # Setup RTPEngine Logging
    cp -f ${DSIP_PROJECT_DIR}/resources/syslog/rtpengine.conf /etc/rsyslog.d/rtpengine.conf
    touch /var/log/rtpengine.log
    systemctl restart rsyslog

    # Setup logrotate
    cp -f ${DSIP_PROJECT_DIR}/resources/logrotate/rtpengine /etc/logrotate.d/rtpengine

    # Setup tmp files
    echo "d /var/run/rtpengine.pid  0755 rtpengine rtpengine - -" > /etc/tmpfiles.d/rtpengine.conf

    # Reconfigure systemd service files
    cp -f ${DSIP_PROJECT_DIR}/rtpengine/systemd/rtpengine-v1.service /etc/systemd/system/rtpengine.service
    cp -f ${DSIP_PROJECT_DIR}/rtpengine/rtpengine-start-pre /usr/sbin/
    cp -f ${DSIP_PROJECT_DIR}/rtpengine/rtpengine-stop-post /usr/sbin/
    chmod +x /usr/sbin/rtpengine*

    # Reload systemd configs
    systemctl daemon-reload
    # Enable the RTPEngine to start during boot
    systemctl enable rtpengine

    # preliminary check that rtpengine actually installed
    if cmdExists rtpengine; then
        exit 0
    else
        exit 1
    fi
}

# Remove RTPEngine
function uninstall {
    systemctl disable rtpengine
    systemctl stop rtpengine
    rm -f /etc/systemd/system/rtpengine.service
    systemctl daemon-reload

    yum remove -y ngcp-rtpengine\*

    rm -f /usr/sbin/rtpengine* /etc/rsyslog.d/rtpengine.conf /etc/logrotate.d/rtpengine

    # TODO: make uninstall source libs
    rm -rf ${SRC_DIR}/libxh264 ${SRC_DIR}/libx265 ${SRC_DIR}/libfdkaac ${SRC_DIR}/libmp3lame ${SRC_DIR}/libopus ${SRC_DIR}/rtpengine \
        ${SRC_DIR}/libvpx ${SRC_DIR}/ffmpeg ${SRC_DIR}/librabbitmq ${SRC_DIR}/libspandsp ${SRC_DIR}/libwebsockets

    # check that rtpengine actually uninstalled
    if ! cmdExists rtpengine; then
        exit 0
    else
        exit 1
    fi
}

case "$1" in
    uninstall)
        uninstall
        ;;
    install)
        install
        ;;
    *)
        printerr "usage $0 [install | uninstall]"
        exit 1
        ;;
esac
