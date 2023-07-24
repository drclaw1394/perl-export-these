package Module::A;
use Export::These qw<sub1 sub2>;
use Export::These group1=>["sub3"];

###########################################
# sub _re_import {                        #
#   my ($target, @args)=@_;               #
#   print "re import at mod a @args\n";   #
#   require "./t/ModB.pm";                #
#   Module::B::import($target,":group1"); #
# }                                       #
###########################################

sub sub1 {
"Sub1";
}
sub sub2 {
"Sub2";
}
sub sub3 {
"Sub3";
}
1;
