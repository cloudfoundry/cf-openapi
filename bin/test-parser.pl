#!/usr/bin/env perl

use v5.20;
use strict;
use warnings;
use Mojo::DOM;
use Mojo::File;
use Data::Dumper;

# Read HTML file
my $html = Mojo::File->new('specs/capi/3.195.0.html')->slurp;
my $dom = Mojo::DOM->new($html);

# Find first endpoint as a test
my $found = 0;
for my $h4 ($dom->find('h4')->each) {
    if ($h4->attr('id') && $h4->attr('id') eq 'definition') {
        # Found a definition
        my $def_p = $h4->next;
        if ($def_p && $def_p->tag eq 'p') {
            my $code = $def_p->at('code.prettyprint');
            if ($code) {
                say "Found endpoint: " . $code->text;
                $found++;
                last if $found >= 5;  # Just show first 5
            }
        }
    }
}

say "\nTotal definitions found (first 5): $found";