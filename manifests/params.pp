class drbd::params{

	$packagename = $operatingsystem ? {
		/Ubuntu|Debian/ => 'drbd8-utils',
		default => 'drbd'
	}

	$servicename = 'drbd'

	$configfile = '/etc/drbd.conf'
	$config_snipplet_path = '/etc/drbd.d'
	$dist_default_config = "/etc/drbd.d/global_common.conf"
	$global_config_file = "${config_snipplet_path}/global_defaults.conf"
	$firewallpath = '/etc/iptables.d'

}
