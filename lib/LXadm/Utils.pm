package LXadm::Utils;

use strict;
use warnings;

use Text::ParseWords qw(shellwords);

my $DLADM    = '/usr/sbin/dladm';
my $IFCONFIG = '/usr/sbin/ifconfig';
my $TEST     = '/usr/bin/test';

# constructor
sub new {
    my $class = shift;
    my $self = { @_ };

    return bless $self, $class
}

# private methods
my $numeric = sub {
    return shift =~ /^\d+$/;
};

my $alphanumeric = sub {
    return shift =~ /^[-\w]+$/;
};

# public methods
sub regexp {
    my $self = shift;
    my $rx = shift;
    my $msg = shift;

    return sub {
        my $value = shift;
        return $value =~ /$rx/ ? undef : "$msg ($value)";
    }
}

sub elemOf {
    my $self = shift;
    my $elems = [ @_ ];

    return sub {
        my $value = shift;
        return (grep { $_ eq $value } @$elems) ? undef
            : 'expected a value from the list: ' . join(', ', @$elems);
    }
}

sub getVNicOver {
    my $self    = shift;
    my $nicName = shift;

    #use string for 'link,over,vid' as perl will warn otherwise
    my @cmd = ($DLADM, qw(show-vnic -p -o), 'link,over');

    open my $vnics, '-|', @cmd or die "ERROR: cannot get vnics\n";

    while (<$vnics>){
        chomp;
        my @nicProps = split ':', $_, 2;
        next if $nicProps[0] ne $nicName;

        return $nicProps[1];
    };

    return undef;
};

sub nicName {
    my $self = shift;

    return sub {
        my ($nicName, $nic) = @_;

        my @cmd;

        # check if VNIC exists
        return undef if $self->getVNicOver($nicName);

        #only reach here if vnic does not exist
        #get first physical link if over is not given
        exists $nic->{over} || do {
            @cmd = ($DLADM, qw(show-phys -p -o link));

            open my $nics, '-|', @cmd or die "ERROR: cannot get nics\n";

            chomp($nic->{over} = <$nics>);
            close $nics;
        };

        @cmd = ($DLADM, qw(create-vnic -l), $nic->{over}, $nicName);
        print STDERR "-> vnic '$nicName' does not exist. creating it...\n";
        system(@cmd) && die "ERROR: cannot create vnic '$nicName'\n";

        return undef;
    }
}

sub purgeVnic {
    my $self = shift;
    my $config = shift;

    for my $nic (@{$config->{net}}){
        my @cmd = ($DLADM, qw(delete-vnic), $nic->{physical});
        system(@cmd) && die "ERROR: cannot delete vnic '$nic->{physical}'\n";
    }
}

1;

__END__

=head1 NAME

LXadm::Utils - lxadm helper module

=head1 SYNOPSIS

use LXadm::Utils;

=head1 DESCRIPTION

methods to check lxadm configuration

=head1 FUNCTIONS

=head2 boolean

checks if the argument is boolean

=head2 numeric

checks if the argument is numeric

=head2 alphanumeric

checks if the argument is alphanumeric

=head2 get_vnic_over

gets the physical nic of a vnic

=head2 nic_name

checks if a vnic exists, tires to create it if not

=head2 serial_name

checks if serial_name is not one of the reserved names

=head2 purge_vnic

deletes all vnic attached to the config

=head1 COPYRIGHT

Copyright 2017 OmniOS Community Edition (OmniOSce) Association.

=head1 LICENSE

This program is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation, either version 3 of the License, or (at your option)
any later version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
this program. If not, see L<http://www.gnu.org/licenses/>.

=head1 AUTHOR

S<Dominik Hassler E<lt>hadfl@cpan.orgE<gt>>,

=head1 HISTORY

2016-12-13 had Initial Version

=cut
