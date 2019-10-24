package App::DoHoT::DNS;
use warnings;
use strict;
use AnyEvent::Handle::UDP;
use Time::HiRes qw(gettimeofday tv_interval);
use App::DoHoT::Statsd;

sub new {
	my $class = shift;
	my $args = { @_ };
	return AnyEvent::Handle::UDP->new(
		bind => [$args->{address}, $args->{port}],
		on_recv => sub {
			my ($data, $ae, $client) = @_;
			my $t0 = [gettimeofday()];

			my ($pkt, $size) = Net::DNS::Packet->new(\$data);
			report_query($pkt);

			$args->{on_query}->($pkt, $pkt->header->id, $size, sub {
				my $reply = shift;
				$ae->push_send($reply->data, $client);
				report_reply($reply, tv_interval($t0));
			});
		},
	);
}

1;
