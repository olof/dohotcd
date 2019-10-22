NAME = dohotcd
PREFIX ?= /usr/local
SYSCONFDIR = /etc/$(NAME)

all:

install:
	install -d $(SYSCONFDIR) $(PREFIX)/sbin
	install dohotcd.pl $(PREFIX)/sbin/$(NAME)
	install config.yml $(SYSCONFDIR)/
