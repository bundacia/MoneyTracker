package MoneyTracker::Error;

use strict;
use Class::MethodMaker
      [
          new => [qw/ -hash new/],
          scalar => [qw/ msg error level code/],
      ];

#######################################
# get_xml
#######################################
sub get_xml
{
    my $self = shift;

    my $xml  = '<MoneyTracker_Error>';
       $xml .= '<msg>'   .($self->msg()   || ''). '</msg>';
       $xml .= '<error><![CDATA[' .($self->error() || ''). ']]></error>';
       $xml .= '<level>' .($self->level() || ''). '</level>';
       $xml .= '<code>'  .($self->code()  || ''). '</code>';
       $xml .= '</MoneyTracker_Error>';
    return $xml;
}
1;
