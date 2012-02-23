# Define: drbd::kern_module
#
# This definition allows loading or blacklisting a kernel module
#
# Parameters:
#	$name:		Name of the kernel module
#	$ensure:	Either "absent" or "present"
#
define drbd::kernel_module ($ensure) {
    $modulesfile = $operatingsystem ? { 
		/Ubuntu|debian/ => "/etc/modules", 
		default => "/etc/rc.modules"
	}
    case $operatingsystem {
        redhat,centos,fedora: { file { "/etc/rc.modules": ensure => file, mode => 755 } }
    }
    case $ensure {
        present: {

            exec { "insert_module_${name}":
                command => $operatingsystem ? {
                    /Ubuntu|Debian/ => "/bin/echo '${name}' >> '${modulesfile}'",
                    default => "/bin/echo '/sbin/modprobe ${name}' >> '${modulesfile}' ",
                },
                unless => $operatingsystem ? {
                    /Ubuntu|Debian/ => "/bin/grep -qFx '${name}' '${modulesfile}'",
                    default => "/bin/grep -q '^/sbin/modprobe ${name}\$' '${modulesfile}'",
                }
            }

        }


        absent: {
            exec { "/sbin/modprobe -r ${name}": 
				onlyif => "/bin/grep -q '^${name} ' '/proc/modules'" 
			}

            exec { "remove_module_${name}":
                command => $operatingsystem ? {
                    /Ubuntu|Debian/ => "/usr/bin/perl -ni -e 'print unless /^\\Q${name}\\E\$/' '${modulesfile}'",
                    default => "/usr/bin/perl -ni -e 'print unless /^\\Q/sbin/modprobe ${name}\\E\$/' '${modulesfile}'",
                },
                onlyif => $operatingsystem ? {
                    /Ubuntu|Debian/ => "/bin/grep -qFx '${name}' '${modulesfile}'",
                    default => "/bin/grep -q '^/sbin/modprobe ${name}\$' '${modulesfile}'"
                }
            }
        }

        default: { err ( "unknown ensure value ${ensure}" ) }
    }
}
