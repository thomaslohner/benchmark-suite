$domainname = 'www.invaliddomain.de'

case $::operatingsystem {
  'gentoo': {

    $packages         = ['www-servers/apache','dev-lang/php']
    $apache_service   = 'apache2'
    $user             = 'www'
    $apache_vhost_dir = '/etc/apache/vhost.d'

    file_line { 'apache_keywords':
      path  => '/etc/portage/package.keywords',
      line  => 'www-servers/apache ~amd64',
      match => '^www-servers/apache',
    }
    file_line { 'apache_use':
      path  => '/etc/portage/package.use',
      line  => 'www-servers/apache -threads apache2_mpms_prefork',
      match => '^www-servers/apache',
    }
    file_line { 'apache_tools_keywords':
      path  => '/etc/portage/package.keywords',
      line  => 'app-admin/apache-tools ~amd64',
      match => '^app-admin/apache-tools',
    }
    file_line { 'apr_keywords':
      path  => '/etc/portage/package.keywords',
      line  => 'dev-libs/apr ~amd64',
      match => '^dev-libs/apr',
    }
    file_line { 'php_keywords':
      path  => '/etc/portage/package.keywords',
      line  => 'dev-lang/php ~amd64',
      match => '^dev-lang/php',
    }
    file_line { 'php_use':
      path  => '/etc/portage/package.use',
      line  => 'dev-lang/php -threads apache2 pdo curl mysqli gd',
      match => '^dev-lang/php',
    }


  }
  'ubuntu', 'debian': {

    $packages         = ['apache2', 'apache2-utils', 'php5', 'php5-mysql', 'php5-gd', 'php5-mcrypt', 'php5-curl']
    $apache_service   = 'apache2'
    $user             = 'www-data'
    $apache_vhost_dir = '/etc/apache2/sites-enabled'

    # enable mod_rewrite
    exec {'enable_mod_rwrite':
      command => '/usr/sbin/a2enmod rewrite',
      unless => '/usr/sbin/a2query -m rewrite',
      notify  => Service[$apache_service],
    }

  }
  default: {
    fail("Unknown OS: $::operatingsystem")
  }
}

file_line {'/etc/hosts':
  path => '/etc/hosts',
  line => "^$::ipaddress $domainname $::hostname"
}

# create docroot
file { [ "/var/", "/var/www"]:
  ensure => "directory",
  before => File["/var/www/$domainname/"],
}
file {"/var/www/$domainname/":
  ensure => "directory",
  owner  => "$user",
  before => Service[$apache_service],
}
file { "/var/www/$domainname/index.html":
  content => "<h4>SysEleven Benchmark Suite</h4>",
  require => File["/var/www/$domainname/"],
}
# create apache vhost
file {'apache_vhost':
  path    => "$apache_vhost_dir/$domainname.conf",
  content => template('sys11-benchmark/apache_vhost.conf.erb'),
  notify  => Service[$apache_service],
  require => [Package[$packages],File["/var/www/$domainname/"]],
}

package {$packages:
  ensure => installed,
  before => Service[$apache_service],
}

service {$apache_service:
  ensure  => running,
  enable  => true,
  require => Package[$packages],
}
