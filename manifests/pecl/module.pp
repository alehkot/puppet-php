# Define: php::pecl::module
#
# Installs the defined php pecl component
#
# Variables:
# $use_package (default="yes") - Tries to install pecl module with the relevant package
#                If set to "no" it installs the module via pecl command
# $preferred_state (default="stable") - Define which preferred state to use when installing Pear modules via pecl
#                command line (when use_package=no)
# $auto_answer (default="\n") - The answer(s) to give to pecl prompts for unattended installs
#
# Usage:
# php::pecl::module { packagename: }
# Example:
# php::pecl::module { Crypt-CHAP: }
#
define php::pecl::module (
  $service         = $php::service,
  $ensure          = present,
  $use_package     = 'yes',
  $manage_ini      = false,
  $preferred_state = 'stable',
  $auto_answer     = '\\n' ) {

  include php

  case $use_package {
    yes: {
      package { "php-${name}":
        name => $operatingsystem ? {
          ubuntu  => "php5-${name}",
          debian  => "php5-${name}",
          default => "php-${name}",
          },
        ensure => $ensure,
        notify => Service[$service],
      }
    }
    default: {
      exec { "pecl-${name}":
        command => "printf \"${auto_answer}\" | pecl -d preferred_state=${preferred_state} install ${name}",
        unless  => "pecl info ${name}",
        require => Package["php-pear"],
        #FIXME: Implement ensure => absent,
      }
      if $manage_ini == true {
        augeas { "php_ini-${name}":
          incl    => $php::config_file,
          lens    => 'Php.lns',
          changes => $ensure ? {
            present => [ "set 'PHP/extension[. = \"${name}.so\"]' ${name}.so" ],
            absent  => [ "rm 'PHP/extension[. = \"${name}.so\"]'" ],
          },
          notify => Service[$service],
        }
      }
    }
  } # End Case
}
