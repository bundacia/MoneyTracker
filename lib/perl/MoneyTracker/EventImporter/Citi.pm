package MoneyTracker::EventImporter::Citi;

###########################################################################
# Finance::Card::Citibank
# Mark Grimes
#
# Check your credit card balances.
# Copyright (c) 2005-8 Mark Grimes (mgrimes@cpan.org).
# All rights reserved. This program is free software; you can redistribute
# it and/or modify it under the same terms as Perl itself.
#
# Parts of this package were inspired by Simon Cozens'
# Finance::Bank::Lloyds module. Thanks Simon!
#
# Jon Keller contributed much of the code to work with multiple accounts.
# Thanks Jon!
#
###########################################################################

use strict;
use warnings;

use Carp;
use WWW::Mechanize;

our $VERSION = '1.70';

my $ua = WWW::Mechanize->new(
    env_proxy  => 1,
    keep_alive => 1,
    timeout    => 30,
);

sub check_balance {
    my ( $class, %opts ) = @_;
    my $self = bless {%opts}, $class;
    my $content;

    if ( $opts{content} ) {

        # If we give it a file, use the file rather than downloading
        open my $fh, "<", $opts{content} or confess;
        $content = do { local $/ = undef; <$fh> };
        close $fh;

    } else {
        croak "Must provide a password" unless exists $opts{password};
        croak "Must provide a username" unless exists $opts{username};

        $ua->get("http://www.citicards.com/cards/wv/home.do")
          or confess "couldn't load the initial page";

        $ua->submit_form(
            form_name => 'LOGIN',
            fields    => {
                'USERNAME'    => $opts{username},
                'PASSWORD'    => $opts{password},
                'NEXT_SCREEN' => '/AccountSummary',
            },
        ) or confess "couldn't submit the login form";

        $content = $ua->content;

        # First account's data is in content, subsequent accounts' data are
        # ajax loaded from .../GetDashboardAccount. Concatenate the two pages
        # and search them together

        $ua->get("https://www.accountonline.com/GetDashboardAccounts")
          or confess "couldn't load GetDashboardAccounts";
        $content .= $ua->content;
    }

    if ( $opts{log} ) {

        # Dump to the filename passed in log
        open( my $fh, ">", $opts{log} ) or confess;
        print $fh $content;
        close $fh;
    }

    # Extract the relevant info into one array
    my @accnts = $content =~ m!
          <span\sclass="prodName"><a\sname="View(\d+)c"></a>([^\n]+?)</span></td>\s*
          </tr>\s*
          <tr>\s*
          <td>&nbsp;(Account\sending\sin:\s*\d+)</td>\s*
          .*?
          Current\sBalance.*?
          </tr>\s*
          <tr>\s*
          <td\s[^>]*><div[^>]*><span\sclass="balNdue">\$([\d,\.]+)</span></div></td>
     !xisg;
    carp "couldn't find any accounts" unless @accnts;

    my @accounts;
    while (@accnts) {
        my ( $position, $name, $account_no, $balance ) = splice @accnts, 0, 4;

        $name       =~ s/&[^;]*;//g;
        $name       =~ s/<[^>]*>//g;
        $name       =~ s/\s+/ /g;
        $account_no =~ s/\s+/ /g;
        $balance    =~ s/,//g;
        $balance *= -1;

        # carp "# Position: $position\n";  # i.e. "1" for the 1st account..."n" for the nth account
        # carp "# Name: $name\n";
        # carp "# Account: $account_no\n";
        # carp "# Balance: $balance\n";

        push @accounts, (

            bless {
                balance    => $balance,
                name       => $name,
                sort_code  => $account_no,
                account_no => $account_no,
                position  => $position, # redundant since just = array index + 1
                statement => undef,
                ## parent => $self,
            },
            "Finance::Card::Citibank::Account"
        );
    }

    return @accounts;
}

package Finance::Card::Citibank::Account;
use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors(
    qw(balance name sort_code account_no position statement));

1;

