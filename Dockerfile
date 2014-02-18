# AppScale
#
# VERSION               0.0.1

FROM      ubuntu
MAINTAINER Chris Bunch <chris@appscale.com>

# First, add repositories to APT
RUN sed -i -e 's,\(deb http://archive.ubuntu.com/ubuntu precise main \).*,\1 restricted universe multiverse,' -e 's,\(deb http://archive.ubuntu.com/ubuntu precise-updates main \).*,\1 restricted universe,' -e 's,\(deb http://security.ubuntu.com/ubuntu precise-security main \).*,\1 restricted universe,' /etc/apt/sources.list


# Install base packages
RUN apt-get update

RUN apt-get install -y ant autoconf automake bison build-essential byacc bzip2 ca-certificates cmake curl debhelper dh-make dpkg-dev erlang fakeroot firefox-locale-en flex g++ gcc git git-core git-man krb5-locales language-pack-en language-pack-en-base language-pack-en-base libasn1-8-heimdal libbsd0 libbz2-dev libc6-dev libclass-isa-perl libcppunit-dev libcurl3-gnutls libedit2 liberror-perl libevent-dev libexpat1-dev libgcrypt11 libgdbm3 libgnutls26 libgpg-error0 libgpm2 libgssapi-krb5-2 libgssapi3-heimdal libhcrypto4-heimdal libheimbase1-heimdal libheimntlm0-heimdal libhx509-5-heimdal libidn11 libk5crypto3 libkeyutils1 libkrb5-26-heimdal libkrb5-3 libkrb5support0 libldap-2.4-2 libp11-kit0 libpython2.7 libreadline-dev libroken18-heimdal librtmp0 libsasl2-2 libsasl2-modules libssl-dev libswitch-perl libtasn1-3 libtool libwind0-heimdal libx11-6 libx11-data libxau6 libxcb1 libxdmcp6 libxext6 libxml2-dev libxmuu1 locales lsb-release maven2 ntp openssh-client openssl patch perl perl-base perl-modules pkg-config python-dev python2.7 python2.7-minimal rsync rsync ruby1.8-dev subversion sudo unzip vim vim vim-common vim-runtime vim-tiny wget xauth zlib1g-dev

# remove conflict package
RUN apt-get -y purge haproxy

# Round 2 packages installed by appscale_build.sh
RUN apt-get install -y bind9-host cron dnsutils ejabberd erlang-nox geoip-database iptables libbind9-80 libdns81 libevent-1.4-2 libgeoip1 libisc83 libisccc80 libisccfg82 libjs-jquery liblcms1 liblockfile-bin liblockfile1 liblwres80 libnfnetlink0 libpcre++-dev libpcre++0 libpcre3-dev libpcrecpp0 libruby libxslt1-dev libxslt1.1 libyaml-0-2 libzip-ruby1.8 logrotate lsof memcached openssh-server procmail python-django python-fpconst python-imaging python-m2crypto python-pip python-pkg-resources python-setuptools python-soappy python-support python-yaml rabbitmq-server ruby sendmail sendmail-base sendmail-bin sendmail-cf sensible-mda socat ssh ssh-import-id

# Round 3 packages
RUN apt-get install -y python-sqlalchemy python-sqlalchemy-ext


# Next, grab the main and tools branches from git
# Use my docker branch until it gets merged into master.
ADD . /root/appscale

# Install main
RUN bash /root/appscale/debian/appscale_build.sh

RUN git clone git://github.com/AppScale/appscale-tools /root/appscale-tools
RUN cd /root/appscale-tools && git checkout 1.12.0

# Install the tools
RUN bash /root/appscale-tools/debian/appscale_build.sh
