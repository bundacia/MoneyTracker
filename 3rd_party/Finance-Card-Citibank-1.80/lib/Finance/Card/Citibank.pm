package Finance::Card::Citibank;

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
use HTML::TreeBuilder::XPath;
use HTML::Element;

our $VERSION = '1.80';

my $ua = WWW::Mechanize->new(
    env_proxy  => 1,
    keep_alive => 1,
    timeout    => 30,
);

sub get_activity {
    my ( $class, %opts ) = @_;
    my $self = bless {%opts}, $class;
    my $content;

    if ( $opts{content} ) {

        # If we give it a file, use the file rather than downloading
        open my $fh, "<", $opts{content} or confess;
        $content = do { local $/ = undef; <$fh> };
        close $fh;

    }
    else {
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
        # ajax loaded from .../GetDashboardNonDefaultAccounts.do. Concatenate
        # the two pages and search them together

        $ua->get(
"https://www.accountonline.com/cards/svc/GetDashboardNonDefaultAccounts.do"
        ) or confess "couldn't load GetDashboardNonDefaultAccounts";
        $content .= $ua->content;
    }

    if ( $opts{log} ) {

        # Dump to the filename passed in log
        open( my $fh, ">", $opts{log} ) or confess;
        print $fh $content;
        close $fh;
    }

    my @activity;

    my $tree = HTML::TreeBuilder::XPath->new;
    $tree->parse_content($content) or confess "Couldn't parse content";
    my @accnts = $tree->findnodes('//div[@class="card_link"]/a');
    for my $accnt (@accnts) {

        my $href = $accnt->findvalue('@href');

        $ua->get(
            "https://www.accountonline.com".$href
        ) or confess "couldn't load AccountActivity";

        my $tree = HTML::TreeBuilder::XPath->new;
        $tree->parse_content($ua->content) or confess "Couldn't parse content";

        push @activity, map {{
            amount      => $_->findvalue('./td[@class="trans-tot"]'       ),
            description => $_->findvalue('./td[3]'                        ),
            date        => $_->findvalue('./td[@class="transaction-date"]'),
        }} $tree->findnodes('//tbody[@transdate]/tr[@class="top-row"]');

    }
    return wantarray ? @activity : \@activity;

}

1;

__END__

# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Finance::Card::Citibank - Check your Citigroup credit card accounts from Perl

=head1 SYNOPSIS

  use Finance::Card::Citibank;
  my @accounts = Finance::Card::Citibank->check_balance(
      username => "xxxxxxxxxxxx",
      password => "12345",
  );

  foreach (@accounts) {
      printf "%20s : %8s / %8s : USD %9.2f\n",
      $_->name, $_->sort_code, $_->account_no, $_->balance;
  }
  
=head1 DESCRIPTION

This module provides a rudimentary interface to Citigroup online
at C<https://www.citibank.com/us/cards/index.jsp>. 
You will need either C<Crypt::SSLeay> or C<IO::Socket::SSL> installed 
for HTTPS support to work. C<WWW::Mechanize> is required.  
=head1 CLASS METHODS

=head2 check_balance()

  check_balance( usename => $u, password => $p )

Return an array of account objects, one for each of your bank accounts.

=head1 OBJECT METHODS

  $ac->name
  $ac->sort_code
  $ac->account_no

Return the account name, sort code and the account number. The sort code is
just the name in this case, but it has been included for consistency with 
other Finance::Bank::* modules.

  $ac->balance

Return the account balance as a signed floating point value.

=head1 WARNING

This warning is verbatim from Simon Cozens' C<Finance::Bank::LloydsTSB>,
and certainly applies to this module as well.

This is code for B<online banking>, and that means B<your money>, and
that means B<BE CAREFUL>. You are encouraged, nay, expected, to audit
the source of this module yourself to reassure yourself that I am not
doing anything untoward with your banking data. This software is useful
to me, but is provided under B<NO GUARANTEE>, explicit or implied.

=head1 THANKS

Simon Cozens for C<Finance::Bank::LloydsTSB>. The interface to this module,
some code and the pod were all taken from Simon's module.

Jon Keller added the ability to pull multiple accounts.

=head1 AUTHOR

Mark Grimes <mgrimes@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-8 by mgrimes

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
