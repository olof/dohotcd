Based on a [blog post series][blog] about doing DoH over Tor. Not
production quality yet, working on it :).

## Installation

First time installation, preparations; run the following as root:

```
apt-get install libanyevent-perl \
                libanyevent-handle-udp-perl \
		libanyevent-http-perl
adduser --system --home /var/lib/dohotcd dohotcd
```

When updating, run the following as root; assuming systemd is
used as init manager:

```
make install
cp dohotcd.service /etc/systemd/system
systemctl enable dohotcd.service
systemctl start dohotcd.service
```

The dohotcd user is referenced from the systemd service file.

[blog]: https://blog.3.14159.se/posts/2019/10/22/dns-over-https-over-tor
