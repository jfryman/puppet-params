# puppet-params

## Overview

Opinionated Module Development requires helpers within Puppet. This
module contains a single function that assists in bridging the gap with
data-driven infrastructure and a simplified module design that I discuss
in my talk [Refactoring Puppet](https://speakerdeck.com/jfryman/refactoring-puppet)

This module allow a streamlined module structure with complex data
structures to be passed around, keeping delegation of responsibilities
within a single module without outrageously large parameter lists.

The goal is to separate logic of the module from the data that drives
the module... a true MVC style approach.

*TL;DR*: Think API for a Puppet Module.

## How It Works
For each paramterized class, you can simply construct a data structure
that contains all of your options in `$<module>::params::defaults`. The
function requires a `defaults` hash to exist.

You then define all of your defaults for each part of the module in this
data structure. If at any time you need to modify parts of the data
structure at runtime, you can supply either the entire data structure or
parts of the data structure on initialization, and `params()` will handle
the merge of the hash for use within Puppet.

## Code Example
```
# modules/ntp/manifests/init.pp
class ntp (
  $options = ntp::params::defaults,
) {

  class { 'ntp::package':
    options => params($options, $name),
  }
  -> class { 'ntp::config':
    options => params($options, $name),
  }
  ~> class { 'ntp::service':
    options => params($options, $name),
  }
  -> Class['ntp']
}

# modules/ntp/manifests/params.pp
class ntp::params {
  $defaults = {
    package => {
      lsbdistid => {
        debian => {
          name => ['ntp'],
        },
        centos => {
          name => ['ntpd'],
        }
      version => 'latest',
    },
    config => {
      servers => ['pool.ntp.org'],
    },
  }
}

class ntp::package(
  $options = undef,
) {
  package { $options[package][operatingsystem][name]:
    ensure => $options[package][version],
  }
}
```
