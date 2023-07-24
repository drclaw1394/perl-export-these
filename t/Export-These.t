use strict;
use warnings;

use Test::More;

BEGIN {
  my $p= "./t/ModA.pm";
  require $p;
  Module::A->import("sub1", ":group1");
}
print sub1();
print sub3();
#print sub3;
#print sub4;

ok 1;

done_testing;
  #########################################################################
  # our \@EXPORT=qw<@{["@export"]}>;                                      #
  # our \%EXPORT_TAGS=(@{[join ", ",                                      #
  #   map {'"'.$_.'"'=>"[qw<@{$export_tags{$_}}>]"} keys %export_tags]}); #
  #########################################################################
    #######################################################
    # print __LINE__;                                     #
    # print "\n";                                         #
    # my \$ref=*{\\\${@{[$target]}::}{EXPORT_OK}}{ARRAY}; #
    #                                                     #
    # print "EOK: ".join ", ", \@\$ref;                   #
    # print "\n";                                         #
    #######################################################
  ##################################
  # if(\@@{[$target]}::EXPORT_OK){ #
  #                                #
  #   print "EXPORT OK";           #
  #   sleep 1;                     #
  # }                              #
  ##################################

  #push \@@{[$target]}::EXPORT_OK, qw<@{["@export_ok"]}>;
    ########################################################################
    # print STDERR "SELF IMPORT\n";                                        #
    # my \$target=shift;                                                   #
    #                                                                      #
    # no strict "refs";                                                    #
    # for(\@_ ? \@_ : \@EXPORT){                                           #
    # print STDERR "PROCESSING \$_\n";                                     #
    #   my \@syms;                                                         #
    #   if(/^:/){                                                          #
    #     my \$group=\$EXPORT_TAGS{\$_};                                   #
    #     die  "Tag \$_ does not exists" unless \$group;                   #
    #     push \@syms, \@\$group                                           #
    #   }                                                                  #
    #   else {                                                             #
    #     #normal symbol                                                   #
    #     print STDERR "normal symbol: \$_\n";                             #
    #     print STDERR "exportok is: \@EXPORT_OK\n";                       #
    #     my \$t=\$_;                                                      #
    #     my \$found=grep /\$t/, \@EXPORT_OK;                              #
    #                                                                      #
    #     die "\$_ is not exported from ".__PACKAGE__."\n" unless \$found; #
    #     push \@syms, \$_;                                                #
    #   }                                                                  #
    #   *{\$target."::".\$_}=\*{ __PACKAGE__ ."::".\$_} for \@syms;        #
    # }                                                                    #
    ########################################################################
