cfgdir		  = $(datadir)/vyatta-cfg/templates
opdir		  = $(datadir)/vyatta-op/templates
share_perl5dir	  = $(datarootdir)/perl5/Vyatta
bin_sudo_usersdir = $(bindir)/sudo-users
curverdir	  = $(sysconfdir)/config-migrate/current

curver_DATA = cfg-version/upnp@1

sbin_SCRIPTS = scripts/system/vyatta-upnp.pl

bin_sudo_users_SCRIPTS = scripts/vyatta-restart-upnp

share_perl5_DATA  = lib/Vyatta/Upnp.pm

cpiop = find  . ! -regex '\(.*~\|.*\.bak\|.*\.swp\|.*\#.*\#\)' -print0 | cpio -0pd

install-exec-hook:
	mkdir -p $(DESTDIR)$(cfgdir)
	cd templates; $(cpiop) $(DESTDIR)$(cfgdir)
	mkdir -p $(DESTDIR)$(opdir)
	cd templates-op; $(cpiop) $(DESTDIR)$(opdir)
