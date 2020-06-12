#!/usr/bin/env perl
use strict;
use DBI;

my $cache_dir = $ENV{CACHE} || './cache';
my $data_dir  = $ENV{DATA} || './cache';

$ENV{DSN} ||= "dbi:SQLite:dbname=$data_dir/metadb.sqlite3";
my $dbh = DBI->connect($ENV{DSN}, '', '', { AutoCommit => 1, RaiseError => 1 })
  or die "Can't connect to the database";

$dbh->begin_work;

build_packages($dbh);
build_packages_history($dbh);

$dbh->commit;

sub build_packages {
    my $dbh = shift;
    populate_table($dbh, 'packages', "$cache_dir/02packages.details.txt");
}

sub build_packages_history {
    my $dbh = shift;
    populate_table($dbh, 'packages_history', "$cache_dir/packages.txt", 1);
}

sub populate_table {
    my($dbh, $name, $file, $persistent) = @_;

    if ( ! -e $file ) {
        warn "---> Skip $name from $file - file missing\n";
        return;
    }

#    print "---> Populating $name from $file\n";
    
    $dbh->do("DROP TABLE IF EXISTS $name") if not $persistent;

    $dbh->do(<<SQL);
CREATE TABLE IF NOT EXISTS $name (
  package varchar(128),
  version varchar(16),
  distfile varchar(128)
)
SQL
    $dbh->do("CREATE INDEX IF NOT EXISTS idx_$name ON $name(package)");

    $dbh->do("CREATE UNIQUE INDEX IF NOT EXISTS idux_$name ON $name(package,distfile)") if $persistent;

    my $insert = $dbh->prepare_cached("INSERT OR IGNORE INTO $name VALUES (?, ?, ?)");

    open my $fh, "<", $file or die "$file: $!";
    while (<$fh>) {
        if ($. == 1 && !/\Q02packages.details.txt\E/) {
            seek($fh,0,0);
            last;
        }
        chomp;
        last if /^\s*$/;
    }
    
    my $i;
    while (<$fh>) {
        chomp;
        my($pkg, $version, $dist) = split /\s+/;
        $insert->execute($pkg, $version, $dist);
        warn $i, "\n" if ++$i % 100000 == 0;
    }

#    print "Imported $i packages.\n";
}



