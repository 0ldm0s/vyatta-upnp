#
# Module: Vyatta::Upnp.pm
# 
# **** License ****
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
# 
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# This code was originally developed by Managed I.T.
# Portions created by Managed I.T. are Copyright (C) 2010 Managed I.T.
# All Rights Reserved.
# 
# Author: Kiall Mac Innes
# Date: May 2010
# Description: Common UPNP definitions/funcitions
# 
# **** End License ****
#
package Vyatta::Upnp;
use strict;
use warnings;

our @EXPORT = qw(
    start_daemon
    restart_daemon
    stop_daemon
    is_running
    upnp_setup
    upnp_write_files
);
use base qw(Exporter);
use File::Basename;
use POSIX;

use Vyatta::Config;
use Vyatta::Misc;
use Vyatta::IpTables::Mgr;

my $upnp_init = '/etc/init.d/linux-igd';
my $upnp_default = '/etc/default/linux-igd';
my $upnp_conf = '/etc/upnpd.conf';
my $upnp_pid = '/var/run/linux-igd.pid';

sub is_running {
    my ($pid_file) = @_;

    if (-f $pid_file) {
        my $pid = `cat $pid_file`;
        $pid =~ s/\s+$//;  # chomp doesn't remove nl
        my $ps = `ps -p $pid -o comm=`;
        if (defined($ps) && $ps ne "") {
            return $pid;
        } 
    }
    return 0;
}

sub set_upnp_default {
    my ( $extiface, $intiface ) = @_;
    open (my $f, '>', $upnp_default)
        or die("$0:  Error!  Unable to open $upnp_default for output: $!\n");
    print $f <<EOF;
# Defaults for linux-igd initscript
# sourced by /etc/init.d/linux-igd
# installed at /etc/default/linux-igd by the maintainer scripts

# Options for upnpd

# External interface name.  If undefined then upnpd will not be started.
EXTIFACE=$extiface

# Internal interface name.  If undefined then upnpd will not be started.
INTIFACE=$intiface

# Options for initscript

# Setup multicast route ?
# "yes" = add/del route to 224.0.0.0 through internal interface when starting/stopping daemon,
# "no" or unset = leave as-is, I will configure multicast routing by another method.
#ALLOW_MULTICAST=yes

# Options for start-stop-daemon

# User or user:group to run upnpd as, if not root.  This user will need
# suitable capabilities (I believe this is CAP_NET_ADMIN; untested).
# If undefined then upnpd will run as root.
#UPNPD_USER=\$NAME:\$NAME

# Supplementary group to run as (beyond those normally defined for
# UPNPD_USER).  If undefined then upnpd will run with the groups defined
# for the user, or if UPNPD_USER is also undefined then as gid=root.
#UPNPD_GROUP=\$NAME

# Chroot directory (you need to maintain the chroot yourself with a program
# like 'jailer').  If undefined then upnpd will not be chrooted before starting.
#CHROOT_DIR=/var/chroot/\$NAME
EOF
    close ($f);
}

sub set_upnp_conf {
    my ( $upstream_bitrate, $downstream_bitrate ) = @_;
    open (my $f, '>', $upnp_conf)
        or die("$0:  Error!  Unable to open $upnp_conf for output: $!\n");
    print $f <<EOF;
# To change the interfaces used edit:
#   /etc/default/linux-igd

#
# The full path and name of the iptables executable,
# (enclosed in quotes).
#
iptables_location = "/sbin/iptables"

#
# Daemon debug level. Messages are logged via syslog to debug.
# 0 - no debug messages
# 1 - log errors
# 2 - log errors and basic info
# 3 - log errors and verbose info
# default = 0
debug_mode = 2

#
# Should the daemon create rules in the forward chain, or not.
# This is necessary if your firewall has a drop or reject
# policy in your forward chain.
# allowed values: yes,no
# default = no
create_forward_rules = yes

#
# Should the daemon insert or append rules in the forward chain.
# Normally you will want to insert rules at the beginning of the
# forward chain, so that they apply before any drop or reject rules
# later in the chain.
# This option only applies if "create_forward_rules = yes".
#
# As an experiment, this setting now also affects the PREROUTING chain
# in the same way.  If this causes you problems please let me (Debian
# maintainer) know through the BTS.
#
# Tip: If you need to insert rules somewhere in the middle of the PREROUTING
# or FORWARD chains, instead of first or last, then you should create a
# new empty chain, e.g forwardUPnP, and set forward_chain_name to that
# chain. Then insert a rule to jump to forwardUPnP in the appropriate place
# in the PREROUTING or FORWARD chain. (The value of forward_rules_append
# probably won't matter much in that case.)
#
# allowed values: yes,no
# default = no
forward_rules_append = no

#
# The name of the chain to put the forward rules in.
# This option only applies if "create_forward_rules = yes".
# allowed values: a-z, A-Z, _, -
# default = FORWARD
#
forward_chain_name = FORWARD

#
# The name of the chain to put prerouting rules in.
# allowed values: a-z, A-Z, _, -
# default = PREROUTING
prerouting_chain_name = UPNP

#
# The internet line upstream bit rate reported from
# the daemon. Value in bits per second
# default = 0
upstream_bitrate = $upstream_bitrate

#
# The internet line downstream bit rate reported from
# the daemon. Value in bits per second
# default = 0
downstream_bitrate = $downstream_bitrate

#
# The default duration of port mappings, used when the client
# doesn't specify a duration.
# Can have the following values:
# 0 - no default duration specified
# seconds | HH:MM - duration from the time of addition
# \@seconds | \@HH:MM - expire mapping at the specified time of day
# default = 0
#duration = 86400 # One day from time of addition
duration = 0

# The name of the igd device xml description document
# default = gatedesc.xml
description_document_name = gatedesc.xml

# The path to the xml documents
# Do not include the trailing "/"
# default = /etc/linuxigd
# WARNING! The make install does put the xml files
# in /etc/linuxigd, if you change this variable
# you have to make sure the xml docs are in the
# right place
xml_document_path = /etc/linuxigd

# The UPnP port to listen on.
# default = 0 (first free UPnP port, starting with 49152)
listenport = 0

# paranoid forwarding option
# 0, allow all forwarding
# 1, only allow internal hosts to forward to themselves.
# default = 0
paranoid = 0

# libupnp debug log file name
#  Note, if this file is enabled then linux-igd debug entries will also be
#  written to it as well as to syslog (see debug_mode, above)
upnp_log_filename = "";
# libupnp debug logging level
#  UPNP_CRITICAL
#  UPNP_PACKET
#  UPNP_INFO
#  UPNP_ALL
upnp_log_level = UPNP_CRITICAL
EOF
    close ($f);
}

sub upnp_write_files {
    my $vc = new Vyatta::Config();

    $vc->setLevel('service upnp');
    my $intiface = $vc->returnValue('listen-on');
    my $extiface = $vc->returnValue('outbound-interface');
    my $upstream_bitrate = $vc->returnValue('upstream-bitrate');
    my $downstream_bitrate = $vc->returnValue('downstream-bitrate');

    if (! defined $upstream_bitrate) {
        $upstream_bitrate = 512;
    }
    if (! defined $downstream_bitrate) {
        $downstream_bitrate = 512;
    }

    set_upnp_default($extiface, $intiface);
    set_upnp_conf($upstream_bitrate * 1000, $downstream_bitrate * 1000);
}

sub upnp_setup {
    my $index = ipt_find_chain_rule('iptables', 'nat',
                                    'VYATTA_PRE_DNAT_HOOK', 'UPNP');
    if (! defined $index) {
        system("iptables -t nat -N UPNP");
        system("iptables -t nat -I VYATTA_PRE_DNAT_HOOK 1 -j UPNP");
    }
    exit 0;
}

sub start_daemon {
    upnp_write_files();
    restart_daemon();
}

sub stop_daemon {
    system("$upnp_init stop >&/dev/null");
}

sub restart_daemon {
    system("$upnp_init restart >&/dev/null");
}

1;

