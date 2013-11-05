define append_if_no_such_line($file, $line, $refreshonly = 'false') {
   exec { "/bin/echo '$line' >> '$file'":
      unless      => "/bin/grep -Fxqe '$line' '$file'",
      path        => "/bin",
      refreshonly => $refreshonly,
   }
}

class must-have {
  include apt
  apt::ppa { "ppa:webupd8team/java": }

  exec { 'apt-get update':
    command => '/usr/bin/apt-get update',
    before => Apt::Ppa["ppa:webupd8team/java"],
  }

  exec { 'apt-get update 2':
    command => '/usr/bin/apt-get update',
    require => [ Apt::Ppa["ppa:webupd8team/java"], Package["git-core"] ],
  }

  package { ["vim", "curl", "git-core", "bash"]:
    ensure => present,
    require => Exec["apt-get update"],
    before => Apt::Ppa["ppa:webupd8team/java"],
  }

  package { "oracle-java7-installer":
    ensure => present,
    require => Exec["apt-get update 2"],
  }

  exec { "accept_license":
    command => "echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections && echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections",
    cwd => "/home/vagrant",
    user => "vagrant",
    path => "/usr/bin/:/bin/",
    require => Package["curl"],
    before => Package["oracle-java7-installer"],
    logoutput => true,
  }

  file { "/vagrant/solr":
    ensure => directory,
    before => Exec["download_solr"]
  }

  exec { "download_solr":
    command => "curl -L http://artfiles.org/apache.org/lucene/solr/4.5.1/solr-4.5.1.tgz | tar zx --directory=/vagrant/solr --strip-components 1",
    cwd => "/vagrant",
    user => "vagrant",
    path => "/usr/bin/:/bin/",
    require => Exec["accept_license"],
    logoutput => true,
  }

  file { "/etc/init/solr.conf":
    source => "/vagrant/scripts/etc/init/solr.conf",
    require => Exec["download_solr"]
  }

  file { "/etc/init.d/solr":
    ensure => link,
    target => "/etc/init/solr.conf",
    require => File["/etc/init/solr.conf"],
  }

  service { "solr":
    enable => true,
    ensure => running,
    #path => "/etc/init/solr.conf",
    provider => "upstart",
    #hasrestart => true,
    #hasstatus => true,
    require => [ File["/etc/init/solr.conf"], File["/etc/init.d/solr"], Package["oracle-java7-installer"] ],
  }
}

include must-have
