#!/usr/bin/perl
use strict;
use warnings;
use AnyEvent;
use AnyEvent::Handle::UDP;
use AnyEvent::HTTP;
use Net::DNS::Packet;
use YAML;

my $config_file = $ENV{DOHOTCD_CONFIG} // '/etc/dohotcd/config.yml';
my $config = Load($config_file);

sub required_setting {
	my ($cfg, $name) = @_;
	return if defined $cfg->{$name};
	die("ERROR! dohotcd: Missing setting in $config_file: $name!\n");
}
required_setting($config, $_) for qw(uri proxy port address);

AnyEvent::HTTP::set_proxy($config->{proxy});
$AnyEvent::HTTP::USERAGENT = $config->{http_user_agent} // '';
$AnyEvent::HTTP::TIMEOUT = $config->{http_timeout} // 5;
$AnyEvent::HTTP::MAX_PER_HOST = $config->{http_concurrent} // 5;
$AnyEvent::HTTP::PERSISTENT_TIMEOUT = $config->{http_keep_alive_timeout} // 30;

my $named = AnyEvent::Handle::UDP->new(
	bind => [$config->{address}, $config->{port}],
	on_recv => sub {
		# Called when a new UDP packet has been received, forward
		# dns query to the configured HTTP endpoint, $uri.
		my ($data, $ae, $client) = @_;
		my ($pkt, $qlen) = Net::DNS::Packet->new(\$data);
		http_post $config->{uri}, $pkt->data,
			headers => {
				Accept => 'application/dns-message',
				'Content-Type' => 'application/dns-message',
				'Content-Length' => $qlen,
			},
			tls_ctx => 'high',
			persistent => 1,
			sub {
				# Called when HTTP query completes, send
				# back response payload to our client
				my ($data, $headers) = @_;
				my $pkt = Net::DNS::Packet->new(\$data);
				$ae->push_send($pkt->data, $client)
			};
	},
);

my $w = AnyEvent->condvar;
$w->recv;
