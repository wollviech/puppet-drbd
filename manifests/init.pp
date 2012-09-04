# Class: drbd
#
# Installs and manages drbd on a host
#
# See http://www.drbd.org/users-guide/ for explanation of certain parameter values
#
# Parameters:
#	bool $usage_count (default: yes):
#		Whether to participate in the usage count statistics
#	enum $protocol [A|B|C] (default: C):
#		Which sync-protocol to use
#	int $wfc_timeout (default: 120):
#		How long to wait for peer in seconds
#	string $sync_rate (default: 500M):
#		Set maximum sync speed
#	string $disable_disk_flush (default: undef):
#		Whether to disable forced disk flushes (aka barriers)
#	bool $enable_peer_authentication (default: true):
#		Whether to enable peer authentication.
#	string $hmac_algorithm (default: sha512):
#		HMAC algorithm for peer authentication
#	string $shared_secret (default: bruahahah32312):
#		Shared secret for peer authentication. Note that it is _strongly_ recommended not to use the default
#	bool $pacemaker_integration (default: false):
#		Whether to enable pacemaker integration
#	bool $nagios_integration (default: false):
#		Whether to enable nagios integration via snmpd
#	bool $enable_storagebased_fencing (default: true):
#		Whether storage based fencing for pacemaker should be enabled.
#		Setting will be ignored if $pacemaker_integration != true
#	
# Dependencies:
#	- define kern_module (if $enable_peer_authentication is true)
#		(Dependency provided inline as drbd::kernel_module)
#	- pd::nagios::plugins::check_drbd, if $nagios_integration is true
#
# Usage examples:
#	class {'::drbd':
#		shared_secret => '<hidden>',
#		sync_rate => '80M',
#		pacemaker_integration => true,
#		nagios_integration => true,
#	}
#
#
class drbd (
	$usage_count = 'yes', # Participate in usage count statistics
	$protocol = 'C', # Which Protocol should the syncer use?
	$wfc_timeout = '120', # How long to wait for peer in seconds
	$sync_rate = '500M', # Maximum sync speed
	$disable_disk_flush = undef, # Disable disk flushes
	$enable_peer_authentication = true,
	$hmac_algorithm = 'sha512', #HMAC Algorthim for peer authentication
	$shared_secret = 'bruahahah32312', #Shared secret for peer authentication
	$pacemaker_integration = false,
	$nagios_integration = false,
	$enable_storagebased_fencing = true
){

	require drbd::params

	if ($enable_peer_authentication) {
		drbd::kernel_module{"${hmac_algorithm}_generic":
			ensure => present
		}
	}

	$template_storagebased_fencing = $pacemaker_integration and $enable_storagebased_fencing

	# Set defaults for file generation
	File{ mode => 644, owner => 'root', group => 'root' }

	package{$drbd::params::packagename:
		ensure => installed,
	}

	file{$drbd::params::config_snipplet_path:
		ensure => directory,
		require => Package[$drbd::params::packagename],
	}

	file{$drbd::params::configfile:
		ensure => present,
		require => Package[$drbd::params::packagename],
		content => template("drbd/drbd.conf.erb"),
	}
		

	file {$drbd::params::global_config_file:
		ensure => present,
		require => File[$drbd::params::configfile],
		content => template("drbd/global_defaults.conf.erb"),
	}

	# Move default config out of the way, if it exists
	exec {'drbd-move-default-config':
		command => "mv '${drbd::params::dist_default_config}' '${drbd::params::config_snipplet_path}/example.conf'",
		onlyif => "test -f '${drbd::params::dist_default_config}'",
	}

	$drbd_enable = $pacemaker_integration ? { 
		false => true,
		default => false,
	}

	service{$drbd::params::servicename:
		ensure => undef,
		enable => $drbd_enable,
		hasstatus => true,
		hasrestart => true,
		require => [ 
			Package[$drbd::params::packagename], 
			File[$drbd::params::configfile],
			File[$drbd::params::global_config_file],
		]
	}

	if ($enable_peer_authentication) {
		Drbd::Kernel_module["${hmac_algorithm}_generic"] -> Service[$drbd::params::servicename]
	}

	if ($nagios_integration) {
		include pd::nagios::plugins::check_drbd
	}
}
