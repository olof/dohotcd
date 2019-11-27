Based on a [blog post][blog] about tunneling DNS-over-HTTPS name
resolution over Tor for the purpose of anonymity. Not production
quality yet, working on it :).

## Prerequisites

* Install tor, privoxy and unbound

(Note that dohotcd itself is agnostic to the software you use,
you can replace tor, privoxy and unbound with something else.)

```
apt-get install tor privoxy unbound
```

* Configure privoxy to forward proxied requests over tor

Make sure the following is in /etc/privoxy/config:

```
forward-socks5t   /               127.0.0.1:9050    .
```

* Make sure you use your unbound as local resolver (check
  /etc/resolv.conf)

## Installation

First time installation, preparations; run the following as root:

```
apt-get install libanyevent-perl \
                libanyevent-handle-udp-perl \
                libanyevent-http-perl \
                libnet-dns-perl \
                libyaml-perl
adduser --system --home /var/lib/dohotcd dohotcd
```

To install the software, run the following (it assumes the use of
systemd as init manager):

```
perl Makefile.PL
```

and, then as root:

```
make install
cp config.yml /etc/dohotcd/config.yml
cp dohotcd.service /etc/systemd/system
systemctl enable dohotcd.service
systemctl start dohotcd.service
```

The dohotcd user is referenced from the systemd service file.

### Configure unbound

I use the following unbound configuration:

```
server:
    do-not-query-localhost: no
    serve-expired: yes

forward-zone:
    name: .
    forward-addr: ::1@5354
```

serve-expired is kind of nice, because of the increased query
times we see by tunneling over Tor, we can speed up our name
resolution (from the perspective of the querying application) a
bit by cheating through serving cached item even after they have
expired. The expired item is served to the client immediately but
is also queried asynchronously and the cache will be updated as
the recursive response arrives.

## TODO

* Try to make use of http/2
* Add tests
* Add support for sysvinit

[blog]: http://blog.3.14159.se/posts/2019/11/27/dns-over-https-over-tor
