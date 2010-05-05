#!/usr/bin/perl
#
# Module: upnp-interface-config.pl
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
# This code was originally developed by Vyatta, Inc.
# Portions created by Vyatta are Copyright (C) 2008-2010 Vyatta, Inc.
# All Rights Reserved.
# 
# Author: Kiall Mac Innes
# Date: May 2010
# Description: Script to configure UPNP IGD (linux-igd).
# 
# **** End License ****
#

use Getopt::Long;
use POSIX;

use lib '/opt/vyatta/share/perl5';
use Vyatta::Config;
use Vyatta::Upnp;

use warnings;
use strict;

my $config = new Vyatta::Config;

my ($setup, $update, $stop, $inbound_interface);

GetOptions(
    "setup!"    => \$setup,
    "update!"   => \$update,
    "stop!"     => \$stop,
    "dev=s"     => \$inbound_interface,
);

if ($setup) {
	exit 0;
}

if ($update) {
	my $outbound_interface = $config->returnValue("service upnp listen-on $inbound_interface outbound-interface");	
	restart_daemon($inbound_interface, $outbound_interface);
	exit 0;
}

if ($stop) {
	stop_daemon($inbound_interface);
	exit 0;
}

exit 1;

# end of file

