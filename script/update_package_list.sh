#!/bin/bash

export CACHE=/app/cache
export DATA=/app/data
mkdir -p $CACHE $DATA

TS=`date +%s`

(cd $CACHE && wget -q ${CPAN_MIRROR:-http://www.cpan.org/}modules/02packages.details.txt.gz -N)

gunzip -c $CACHE/02packages.details.txt.gz > $CACHE/02packages.details.txt.$TS
ln -f $CACHE/02packages.details.txt.$TS $CACHE/02packages.details.txt
ln -f $CACHE/02packages.details.txt.$TS $CACHE/packages.txt.$TS
ln -f $CACHE/packages.txt.$TS $CACHE/packages.txt

export DSN=dbi:SQLite:dbname=$DATA/metadb.sqlite3

script/update_database.pl

rm $(ls $CACHE/packages.txt.* $CACHE/02packages.details.txt.* | grep -Ev ".$TS")
