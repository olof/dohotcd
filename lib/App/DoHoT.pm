package App::DoHoT;
use strict;
use warnings;

require Exporter;
our @ISA = 'Exporter';
our @EXPORT = 'main';

use AnyEvent;
use YAML qw(LoadFile);
use App::DoHoT::DNS;
use App::DoHoT::DoH;
use Net::Statsd;

my $DEFAULT_CONFIG = '/etc/dohotcd/config.yml';

sub load_config {
	my $config_file = shift;
	my $config = LoadFile($config_file);
	my $missing = join ', ', grep { not defined $config->{$_} }
		qw(upstream proxy port address);
	die("ERROR! dohotcd: Missing settings in $config_file: $missing!\n")
		if $missing;
	return $config;
}

sub main {
	my $config = load_config($ENV{DOHOTCD_CONFIG} // $DEFAULT_CONFIG);
	if ($config->{statsd} and $config->{statsd}->{host}) {
		$Net::Statsd::PREFIX = $config->{statsd}->{prefix} // '';
		$Net::Statsd::HOST = $config->{statsd}->{host};
		$Net::Statsd::PORT = $config->{statsd}->{port} // 8125;
	}
	my $named = App::DoHoT::DNS->new(
		%$config,
		on_query => App::DoHoT::DoH::query_handler(%$config),
	);
	say STDERR "Listening on $config->{address} port $config->{port}";
	my $w = AnyEvent->condvar;
	$w->recv;
}

1;
