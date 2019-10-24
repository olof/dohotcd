package App::DoHoT::Statsd;
our @ISA = 'Exporter';
our @EXPORT = qw(report_query report_reply);
use Net::Statsd;

sub limit_dns_level {
	my $input = shift;
	my ($domain) = $input =~ /([^.]+(?:\.[^.]+)?$)/;
	return $domain;
}

sub invert_dns_name {
	my $domain = shift;
	my @name = reverse split /\./, $domain;
	my $name = $name[0];
	if (@name > 1) {
		$name .= ".$name[1]";
	}
}

sub metric_name {
	my $name = shift;
	return "$Net::Statsd::PREFIX.$name" if defined $Net::Statsd::PREFIX;
	return $name;
}

sub incr {
	my $name = shift;
	Net::Statsd::increment(metric_name($name), @_);
}

sub timing {
	my $name = shift;
	Net::Statsd::timing(metric_name($name), @_);
}

sub report_flags {
	my ($prefix, $header) = @_;
	$prefix .= ".flags";
	incr("$prefix.qr") if $header->qr;
	incr("$prefix.aa") if $header->aa;
	incr("$prefix.tc") if $header->tc;
	incr("$prefix.rd") if $header->rd;
	incr("$prefix.ra") if $header->ra;
	incr("$prefix.ad") if $header->ad;
	incr("$prefix.cd") if $header->cd;
	incr("$prefix.do") if $header->do;
}

sub report_header {
	my ($prefix, $header) = @_;
	incr("$prefix.opcode." . $header->opcode);
	incr("$prefix.rcode." . $header->rcode);
	report_flags($prefix, $header);
}

sub report_name {
	my ($prefix, $name) = @_;
	my $stat = invert_dns_name(limit_dns_level($name));
	incr("$prefix.name.$stat");
}

sub report_question {
	my ($prefix, $pkt, $q) = @_;
	incr("$prefix.class." . $q->qclass);
	incr("$prefix.type." . $q->qtype);
	report_name($prefix, $q->qname);
}

sub report_answer {
	my ($prefix, $pkt, $r) = @_;
	incr("$prefix.class." . $r->class);
	incr("$prefix.type." . $r->type);
	report_name($prefix, $r->name);
}

sub report {
	my ($prefix, $pkt) = @_;
	report_header($prefix, $pkt->header);
	timing("$prefix.ancount", $pkt->header->ancount);
	timing("$prefix.qdcount", $pkt->header->qdcount);
}

sub report_query {
	my $pkt = shift;
	return unless defined $Net::Statsd::HOST;
	report('query', $pkt);
	report_question('query', $pkt, $_) for $pkt->question;
	printf STDERR "DEBUG: [%d] query for %s (%s)\n",
		$pkt->header->id, $_->qname, $_->qtype for $pkt->question;
}

sub report_reply {
	my ($pkt, $time) = @_;
	return unless defined $Net::Statsd::HOST;
	report('answer', $pkt);
	report_answer('answer', $pkt, $_) for $pkt->answer;
	printf STDERR "DEBUG: [%d] got %d answer(s): %s\n",
		$pkt->header->id,
		$pkt->header->ancount,
		$pkt->header->rcode;

	# if it's reported as an internal failure, report it separatly
	timing($reply->{__dohot_internal_failure} ?
		'answer.fail_latency' : 'answer.latency',
		$time * 1000
	);
}

1;
