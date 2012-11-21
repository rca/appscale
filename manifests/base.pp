Exec { path => ["/usr/bin", "/usr/local/bin", "/usr/sbin", "/bin", "/sbin"] }

class box_cleanup {
  exec { "apt-get update": }

  exec { "fix_hosts":
    command => "sed -i -e 's/127.0.1.1.*/127.0.1.1 lucid64/' /etc/hosts",
    onlyif => "grep comcast /etc/hosts",
  }

  file { "/home/vagrant/appscale":
    ensure => directory,
    mode => 0755,
    owner => vagrant,
    group => vagrant,
  }
}

class appscale_tools_dependencies {
  package { ["build-essential", "debhelper", "dh-make", "fakeroot", "lintian", "gnupg", "pbuilder",
             "ec2-api-tools", "openjdk-6-jdk", "vim", "openssh-server", "git-core", "tcsh", "python-sphinx"]:
    ensure => present,
    require => Exec["apt-get update"],
    before => [File["/usr/lib/jvm/java-6-openjdk/lib/security"], File["/usr/lib/jvm/java-6-openjdk/lib/cacerts"]],
  }

  file { "/usr/lib/jvm/java-6-openjdk/lib/security":
    ensure => directory,
    recurse => true,
    mode => 0775,
    owner => root,
    group => root,
  }

  file { "/usr/lib/jvm/java-6-openjdk/lib/cacerts":
    ensure => present,
    recurse => true,
    mode => 0664,
    owner => root,
    group => root,
  }
}

class appscale_dependencies {
  file { "/etc/apt/sources.list":
    ensure => present,
    source => "/home/vagrant/appscale/appscale/files/sources.list",
    before => Exec["apt-get update"],
    notify => Exec["apt-get update"],
  }

  exec { "apt-get -y upgrade":
    require => File["/etc/apt/sources.list"],
  }

  exec { "update_apt":
    command => "apt-get update",
  }

  exec { "add_deadsnakes_ppa":
    command => "add-apt-repository ppa:fkrull/deadsnakes",
    unless => "test -e /etc/apt/sources.list.d/fkrull-deadsnakes-lucid.list",
  }

  package { "python-software-properties":
    ensure => present,
    require => Exec["update_apt"],
  }

  package { "cmake":
    ensure => present,
  }

  package { [
    "curl", "autoconf", "automake", "libtool",
    "gcc", "g++", "pkg-config", "ant", "maven2", "doxygen", "graphviz",
    "rsync", "tcl-dev", "python-tk", "tk8.4-dev", "ntp", "cvs", "wget", "bzr",
    "xterm", "bison", "flex", "byacc", "unzip", "bzip2", "libc6-dev",
    "subversion", "erlang", "dpkg-dev", "python-dev", "libssl-dev",
    "libevent-dev", "ruby1.8-dev", "thin1.8", "unixodbc-dev", "zlib1g-dev",
    "liblog4cpp5-dev", "libexpat1-dev", "libncurses5-dev", "libbz2-dev",
    "libreadline-dev", "libgdbm-dev", "swig", "screen", "libsqlite3-dev",
    "libcppunit-dev", "libcairo2-dev", "libpango1.0-dev", "libxml2-dev",
    "libart-2.0-2", "libboost1.40-dev",
    "mysql-cluster-server-5.1", "mysql-cluster-client-5.1"]:

    ensure => present,
    require => Package["cmake"],
  }

  exec { "add_rabbitmq_repo":
    command => "add-apt-repository 'deb http://www.rabbitmq.com/debian/ testing main'",
    unless => "grep -q rabbitmq.com /etc/apt/sources.list",
    logoutput => "on_failure",
    require => Package["python-software-properties"],
    notify => Exec["apt-get update"],
  }

  exec { "add_rabbitmq_gpg_key":
    command => "wget -O - http://www.rabbitmq.com/rabbitmq-signing-key-public.asc | sudo apt-key add -",
    unless => "apt-key list | grep info@rabbitmq.com",
    logoutput => "on_failure",
    notify => Exec["apt-get update"],
  }

  exec { "generate_locale":
    environment => [
      "LANGUAGE=en_US.UTF-8",
      "LANG=en_US.UTF-8",
      "LC_ALL=en_US.UTF-8"],
    command => "locale-gen en_US.UTF-8",
    unless => "grep -i en_us.utf-8 /usr/share/i18n/SUPPORTED",
  }

  exec { "reconfigure_locales":
    environment => [
      "LANGUAGE=en_US.UTF-8",
      "LANG=en_US.UTF-8",
      "LC_ALL=en_US.UTF-8"],
    command => "dpkg-reconfigure locales",
    unless => "grep -i en_us.utf-8 /usr/share/i18n/SUPPORTED",
  }

  # setup /etc/mysql and add the debian files below before installing the
  # package so that the service is able to start.
  file { "/etc/mysql":
    ensure => directory,
    mode => 0755,
    before => [File["/etc/mysql/debian-start.inc.sh"], File["/etc/mysql/debian-start"]],
  }

  file { "/etc/mysql/debian-start":
    ensure => present,
    mode => 0755,
    source => "/home/vagrant/appscale/appscale/debian/debian-start",
    before => Package["mysql-cluster-server-5.1"],
  }

  file { "/etc/mysql/debian-start.inc.sh":
    ensure => present,
    mode => 0644,
    source => "/home/vagrant/appscale/appscale/debian/debian-start.inc.sh",
    before => Package["mysql-cluster-server-5.1"],
  }
}

class appscale_development {
  file { "/home/vagrant/.devscripts":
    ensure => link,
    target => "/home/vagrant/.appscale-tools/devscripts",
  }
}

class appscale {
  exec { "clone_appscale":
    command => "git clone /home/vagrant/appscale/appscale",
    cwd => "/root",
    unless => "test -e /root/appscale",
  }

  exec { "update_repo":
    cwd => "/root/appscale",
    command => "git pull",
    require => Exec["clone_appscale"],
  }

  file { "/etc/profile.d/go.sh":
    ensure => present,
    source => "/home/vagrant/appscale/appscale/files/go.sh",
    mode => 0644,
  }
}

include box_cleanup
include appscale_tools_dependencies
include appscale_dependencies
include appscale_development
include appscale
