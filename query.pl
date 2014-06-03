#!/usr/bin/perl

#########################################################
# API Documentation: http://open.fda.gov/api/reference/ #
#########################################################

use strict;
use warnings;
use LWP::UserAgent;
use HTTP::Request;
use JSON;
use Data::Dumper;
use Scalar::Util qw(looks_like_number);
use Term::ANSIScreen qw(cls);

################################################
# Set up some basics we'll need for everything #
################################################

my $apikey;
open( my $fh, "<", "apikey.txt" ) or die "Can't find file for your API Key: $!";
while (<$fh>) {
    chomp( $apikey = $_ );
}
close $fh;
my $clear_screen = cls();

sub main {
    my $skip  = 0;
    my $limit = 25;
    my $count = "";
    menu( $skip, $limit, $count );
}

sub menu {
    my ( $skip, $limit, $count ) = @_;

    print $clear_screen;
    print "1) Search a generic drug name\n";
    print "2) Search a brand drug name\n";
    print "3) Search for a side effect\n";
    print "4) Quit\n";
    print "\n";
    print "What would you like to do? (Please only enter the number) ";
    chomp( my $choice = <> );

    if ( defined $choice and length $choice and looks_like_number($choice) ) {
        if ( $choice == 1 ) {
            print "\nWhat name do you want to search? ";
            chomp( my $gname = <> );
            generic_name( $skip, $limit, $count, $gname );
        }
        elsif ( $choice == 2 ) {
            print "\nWhat name do you want to search? ";
            chomp( my $bname = <> );
            brand_name( $skip, $limit, $count, $bname );
        }
        elsif ( $choice == 3 ) {
            print "\nWhat side effect do you want to look for? (Separate multiple terms with a plus (+) symbol)\n";
            chomp( my $sideEffects = <> );
            print "\n";
            side_effects( $skip, $limit, $count, $sideEffects );
        }
        elsif ( $choice == 4 ) {
            print "Bye now!\n";
            exit 0;
        }
        else {
            print "\nPlease choose a number\n";
            menu();
        }
    }
    else {
        print "\nPlease choose a number\n";
        menu();
    }
}

sub generic_name {
    my ( $skip, $limit, $count, $name ) = @_;

    my $type   = 1;
    my $search = "patient.drug.openfda.generic_name:\"$name\"";

    craft_request( $type, $skip, $limit, $count, $search );

}

sub brand_name {
    my ( $skip, $limit, $count, $name ) = @_;

    my $type   = 2;
    my $search = "patient.drug.openfda.brand_name:\"$name\"";

    craft_request( $type, $skip, $limit, $count, $search );

}

sub side_effects {
    my ( $skip, $limit, $count, $sideEffects ) = @_;

    my $type   = 3;
    my $search = "(patient.reaction.reactionmeddrapt:$sideEffects)";

    craft_request( $type, $skip, $limit, $count, $search );

}

sub craft_request {
    my ( $type, $skip, $limit, $count, $search ) = @_;

    my $ua       = new LWP::UserAgent;
    my $url      = "https://api.fda.gov/drug/event.json?api_key=$apikey&search=$search&count=$count&limit=$limit&skip=$skip";
    my $request  = HTTP::Request->new( "GET" => $url );
    my $response = $ua->request($request);
    my $json_obj = JSON->new->utf8->decode( $response->content );

    print_results( $type, $json_obj );

}

sub print_results {
    my ( $type, $json_obj ) = @_;

    if ( $type == 1 ) {
        print "\nThe brand name(s) for this drug is/are: ";
        foreach my $result ( @{ $json_obj->{results} } ) {
            foreach my $drug ( @{ $result->{patient}->{drug} } ) {
                if ( defined @{ $drug->{openfda}->{brand_name} } and length @{ $drug->{openfda}->{brand_name} } ) {
                    print @{ $drug->{openfda}->{brand_name} };
                    print "\n";
                }
            }
        }
        print "\n";
    }
    elsif ( $type == 2 ) {
        print "\nThe generic name(s) for this drug is/are: ";
        foreach my $result ( @{ $json_obj->{results} } ) {
            foreach my $drug ( @{ $result->{patient}->{drug} } ) {
                if ( defined @{ $drug->{openfda}->{generic_name} } and length @{ $drug->{openfda}->{generic_name} } ) {
                    print @{ $drug->{openfda}->{generic_name} };
                    print "\n";
                }
            }
        }
        print "\n";
    }
    elsif ( $type == 3 ) {
        print "\nThe first 25 drugs with this side effect are:\n";
        foreach my $result ( @{ $json_obj->{results} } ) {
            foreach my $drug ( @{ $result->{patient}->{drug} } ) {
                if ( defined @{ $drug->{openfda}->{generic_name} } and length @{ $drug->{openfda}->{generic_name} } ) {
                    print @{ $drug->{openfda}->{generic_name} };
                    print "\n";
                }
            }
        }
        print "\n";
    }

    <STDIN>;
    main();
}

main();
