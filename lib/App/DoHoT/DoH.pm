package App::DoHoT::DoH;
use warnings;
use strict;
use AnyEvent::HTTP;
use Net::DNS::Packet;

my $DNS_MIME_TYPE = 'application/dns-message';

sub query_handler {
	my %args = (
		http_user_agent => '',
		http_timeout => 5,
		http_concurrent => 5,
		http_keep_alive_timeout => 30,
		@_,
	);

	AnyEvent::HTTP::set_proxy($args{proxy});
	(
		$AnyEvent::HTTP::TIMEOUT,
		$AnyEvent::HTTP::MAX_PER_HOST,
		$AnyEvent::HTTP::PERSISTENT_TIMEOUT
	) = @args{qw(
		http_timeout
		http_concurrent
		http_keep_alive_timeout
	)};

	return sub {
		my ($query, $id, $qlen, $on_done) = @_;
		http_post $args{upstream}, $query->data,
			headers => {
				Accept => $DNS_MIME_TYPE,
				'Content-Type' => $DNS_MIME_TYPE,
				'Content-Length' => $qlen,
				'User-Agent' => $args{http_user_agent},
			},
			tls_ctx => 'high',
			persistent => 1,
			sub {
				my ($data, $headers) = @_;
				my $type = $headers->{'content-type'};
				my $reply;

				if (defined $data and $type eq $DNS_MIME_TYPE) {
					$reply = Net::DNS::Packet->new(\$data);
				} else {
					$reply = $query->reply;
					$reply->header->rcode('SERVFAIL');
					$reply->{__dohot_internal_failure} = 1;
				}

				$on_done->($reply);
			};
	}
}

1;
