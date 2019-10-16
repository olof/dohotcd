#!/usr/bin/perl
use strict;
use warnings;
use AnyEvent;
use AnyEvent::Handle::UDP;
use AnyEvent::HTTP;
use Net::DNS::Packet;

my $uri = 'https://1.1.1.1/dns-query';
my $proxy = 'http://127.0.0.1:8118';

AnyEvent::HTTP::set_proxy($proxy);

my $named = AnyEvent::Handle::UDP->new(
	bind => ['::1', 5354],
	on_recv => sub {
		# Called when a new UDP packet has been received, forward
		# dns query to the configured HTTP endpoint, $uri.
		my ($data, $ae, $client) = @_;
		my ($pkt, $qlen) = Net::DNS::Packet->new(\$data);
		http_post $uri, $pkt->data,
			headers => {
				Accept => 'application/dns-message',
				'User-Agent' => '',
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
