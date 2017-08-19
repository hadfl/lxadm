package LXadm::Images;

use strict;
use warnings;

use Data::Dumper;
use JSON;
use File::Path qw(make_path);
use File::Basename qw(dirname);
use File::stat;
use Time::localtime;
use Digest::SHA;

use FindBin;
my ($BASEDIR)   = dirname($FindBin::RealBin);

# constants/programs
my $IMGURL     = 'https://images.joyent.com/images';
my $MAX_AGE    = 24 * 60 * 60;
my $CURL       = '/usr/bin/curl';
my $PKG        = '/usr/bin/pkg';
my $CACHE_PATH = "/var$BASEDIR/cache";
my @DUMPSET    = (
    {
        name  => 'UUID',
        len   => 10,
        key   => [ qw(uuid) ],
        trans => sub { my $str = shift; return substr $str, length ($str) - 8; }
    },
    {
        name  => 'Name',
        len   => 16,
        key   => [ qw(name) ],
    },
    {
        name  => 'Version',
        len   => 10,
        key   => [ qw(version) ],
    },
    {
        name  => 'Kernel',
        len   => 10,
        key   => [ qw(tags kernel_version) ],
    },
    {
        name  => 'Description',
        len   => 50,
        key   => [ qw(description) ],
        trans => sub { return (shift =~ /^[^\s]+\s+(.+\.)\s+Built/)[0]; }
    },
);

# globals
my $images = [];

# private methods
my $checkLXpkg = sub {
    my $cmd = "$PKG list system/zones/brand/lx > /dev/null";
    system ($cmd) and die "ERROR: LX brand not installed. run 'pkg install system/zones/brand/lx'\n";
};

my $getHashValue = sub {
    my $value = shift;
    my $item  = shift;

    $value = $value->{$_} for (@{$item->{key}});

    return $value;
};

my $getImageByUUID = sub {
    my $self = shift;
    my $uuid = shift;

    my $imgs = [ grep { $_->{uuid} =~ /$uuid/ } @{$self->listImages} ];

    @$imgs < 1 and die "ERROR: image UUID containing '$uuid' not found.\n";
    @$imgs > 1 and die "ERROR: more than one image uuid contains '$uuid'.\n";

    return $imgs->[0];
};

my $getFile = sub {
    my $fileName = shift;
    my $url      = shift;

    print "downloading file...\n";
    my @cmd = ($CURL, '-o', "$CACHE_PATH/$fileName", $url);
    system (@cmd) && die "ERROR: cannot download url '$url'.\n";
};

my $checkChecksum = sub {
    my $fileName = shift;
    my $checksum = shift;

    print "checking checksum of '$fileName'...\n";
    if (Digest::SHA->new('sha1')->addfile("$CACHE_PATH/$fileName")->hexdigest
        eq $checksum) {

        return 1;
    }
    print "checksum not ok...\n";
    return 0;
};

my $downloadFile = sub {
    my $fileName = shift;
    my $url      = shift;
    my $opts     = { @_ };

    # check if cache directory exists
    -d "$CACHE_PATH" || make_path("$CACHE_PATH") || do {
        die "ERROR: cannot create directory $CACHE_PATH\n";
    };

    print "checking cache for '$fileName'...\n";
    my $freshDl = 0;
    -f "$CACHE_PATH/$fileName" || do {
        print "file not found in cache...\n";
        $getFile->($fileName, $url);
        $freshDl = 1;
    };

    # check if cache file has a max_age property and redownload if expired
    exists $opts->{max_age} && !$freshDl
        && (time - stat("$CACHE_PATH/$fileName")->mtime > $opts->{max_age})
        && $getFile->($fileName, $url);

    # check checksum if sha1 option is set
    exists $opts->{sha1} && do {
        return if $checkChecksum->($fileName, $opts->{sha1});
        $getFile->($fileName, $url);
        $checkChecksum->($fileName, $opts->{sha1}) || die "ERROR: chechsum mismatch for downloaded file\n";
    };
};

# constructor
sub new {
    my $class = shift;
    my $self = { @_ };

    $checkLXpkg->();

    return bless $self, $class;
}

# public methods
sub cachePath {
    return $CACHE_PATH;
}

sub fetchImages {
    my $self  = shift;
    my $force = shift;

    $downloadFile->('index.json', $IMGURL, (max_age => ($force ? -1 : $MAX_AGE)));
    open my $index, '<', "$CACHE_PATH/index.json" or die "ERROR: cannot open 'index.json': $!\n";
    my $imgs = JSON->new->decode(do { local $/; <$index>; });
    ref $imgs eq 'ARRAY' or die "ERROR: 'index.json' invalid\n";

    # filter so we only get lx-datasets
    $images = [ grep { $_->{type} eq 'lx-dataset' } @$imgs ];
}

sub listImages {
    my $self = shift;
    my $uuid = shift;

    @$images || $self->fetchImages;

    # check if UUID matches a unique item
    defined $uuid && return $self->$getImageByUUID($uuid);

    return $images;
}

sub dumpImages {
    my $self     = shift;
    my $uuid_len = shift;

    my $imgs = $self->listImages;

    print $_->{name} . (' ' x ($_->{len} - length ($_->{name}))) for (@DUMPSET);
    print "\n";
    for my $img (@$imgs) {
        for my $item (@DUMPSET) {
            my $tmpStr = exists $item->{trans} ? $item->{trans}->($getHashValue->($img, $item))
                : $getHashValue->($img, $item);

            $tmpStr = length ($tmpStr) > $item->{len} ? substr ($tmpStr, 0, $item->{len})
                : $tmpStr . (' ' x ($item->{len} - length ($tmpStr)));

            print $tmpStr;
        }
        print "\n";
    }
}

sub downloadImage {
    my $self = shift;
    my $uuid = shift;

    # get image by UUID
    my $img = $self->$getImageByUUID($uuid);

    $downloadFile->("$img->{uuid}.gz", "$IMGURL/$img->{uuid}/file", ( sha1 => $img->{files}->[0]->{sha1} ));

    return $img;
}

1;

__END__

=head1 NAME

LXadm::Images - lxadm images class

=head1 SYNOPSIS

use LXadm::Images;

=head1 DESCRIPTION

downloads and verifies lx zone images

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

