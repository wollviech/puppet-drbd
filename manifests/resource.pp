# define drbd::resource
#
# Defines a DRBD resource
#
# Parameters:
#	string $device:
#		Which drbd (/dev/drbdX) device to use
#	struct drbd_host_struct $host_a:
#	struct drbd_host_struct $host_b:
#		Host struct for a given host
#
# struct drbd_host_struct is a hash with the following values
#	host:: Hostname (as returned by plain +hostname+ command)
#	disk:: Path to the data disk
#	ip:: IP on which the sync listener should use (firewall rule will be generated automagically)
#	port:: Port in which the sync-listener should use
#	meta_disk:: Path to the metadata disk
#
# Usage example:
#	$node_mnemosyne = {
#		host => 'mnemosyne',
#		disk => '/dev/Data/pxe',
#		ip => 10.10.10.10,
#		port => '7788',
#		meta_disk => '/dev/Data/pxe-meta [0]',
#	}
#
#	$node_moneta = {
#		host => 'moneta',
#		disk => '/dev/Data/pxe',
#		ip => 10.10.10.20,
#		port => '7788',
#		meta_disk => '/dev/Data/pxe-meta [0]',
#	}
#
#	drbd::resource{'pxe':
#		device => '/dev/drbd0',
#		host_a => $node_mnemosyne,
#		host_b => $node_moneta,
#	}
#	
define drbd::resource (
	$device,
	$host_a,
	$host_b
){

	require drbd::params

	$a_host = $host_a['host']
	$a_disk = $host_a['disk']
	$a_ip = $host_a['ip']
	$a_port = $host_a['port']
	$a_meta_disk = $host_a['meta_disk']

	$b_host = $host_b['host']
	$b_disk = $host_b['disk']
	$b_ip = $host_b['ip']
	$b_port = $host_b['port']
	$b_meta_disk = $host_b['meta_disk']
	
	file{"${drbd::params::config_snipplet_path}/${name}.res":
		ensure => present,
		owner => 'root',
		group => 'root',
		mode => 644,
		content => template("drbd/drbd_resource.erb"),
	}

	$firewallrule = "${drbd::params::firewallpath}/drbd-${name}"
	file {$firewallrule:
		checksum => md5,
		ensure => file,
		group => 'root',
		owner => 'root',
		mode => '644',
		require => Package['komstuff'],
		content => template("drbd/drbd_iptables.erb"),
	}
	
	exec { "activate-firewall-drbd-${name}":
		command => "/sbin/iptables-restore --noflush < '${firewallrule}'",
		refreshonly => true,
		onlyif => "test -f '${firewallrule}'"
	}

	File[$firewallrule] ~> Exec["activate-firewall-drbd-${name}"]

}
	

