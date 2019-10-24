Based on a [blog post series][blog] about doing DoH over Tor. Not
production quality yet, working on it :).

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

## TODO

* Try to make use of http/2
* Add tests
* Add support for sysvinit

[blog]: https://blog.3.14159.se/posts/2019/10/22/dns-over-https-over-tor
