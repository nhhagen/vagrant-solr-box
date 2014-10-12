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

  package { "oracle-java8-installer":
    ensure => present,
    require => Exec["apt-get update 2"],
  }

  exec { "accept_license":
    command => "echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections && echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections",
    cwd => "/home/vagrant",
    user => "vagrant",
    path => "/usr/bin/:/bin/",
    require => Package["curl"],
    before => Package["oracle-java8-installer"],
    logoutput => true,
  }

  exec { "check_solr_not_downloaded":
    command => '/bin/false',
    onlyif => '/usr/bin/test -e /vagrant/solr.tgz'
  }

  exec { "check_solr_downloaded":
    command => '/bin/true',
    onlyif => '/usr/bin/test -e /vagrant/solr.tgz'
  }

  exec { "download_solr":
    command => "curl -o /vagrant/solr.tgz -L http://apache.komsys.org/lucene/solr/4.9.0/solr-4.9.0.tgz",
    cwd => "/vagrant",
    user => "vagrant",
    path => "/usr/bin/:/bin/",
    require => [Exec["check_solr_not_downloaded"], Exec["accept_license"]],
    logoutput => true
  }

  exec { "extract_solr":
    command => "tar zx -f /vagrant/solr.tgz --directory=/vagrant/${machine_name}/solr --strip-components 1 --exclude */docs/**",
    cwd => "/vagrant",
    user => "vagrant",
    path => "/usr/bin/:/bin/",
    require => [Exec["check_solr_downloaded"], File["/vagrant/${machine_name}/solr/"]]
  }

  file { "/vagrant/${machine_name}":
    ensure => directory
  }

  file { "/vagrant/${machine_name}/solr/":
    ensure       => directory,
    require      => File["/vagrant/${machine_name}"]
  }


  file { "solr.conf":
    path => "/etc/init/solr.conf",
    content => template("/vagrant/scripts/etc/init/solr.conf.erb"),
    require => Exec["extract_solr"]
  }

  file { "/etc/init.d/solr":
    ensure => link,
    target => "/etc/init/solr.conf",
    require => File["solr.conf"],
  }

  service { "solr":
    enable => true,
    ensure => running,
    #path => "/etc/init/solr.conf",
    provider => "upstart",
    #hasrestart => true,
    #hasstatus => true,
    require => [ File["/etc/init/solr.conf"], File["/etc/init.d/solr"], Package["oracle-java8-installer"] ],
  }
}

include must-have
