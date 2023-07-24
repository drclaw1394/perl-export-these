package Export::These;

use strict;
use warnings;

use constant DEBUG=>1;

# injects a import subroutine in to the package/class namespace (first arg)
#
# use Export::These qw<a list of  scalars to export>;
#
# use Export::These {
#                     ok=>[],
#                     export=>[],
#                     tags=>[],
#               }
#
sub import {
  # Bootstrap...
  # If the first argument is the name of this package, then we know its called
  # with a ->
  # In this case we use the package information from caller to  export 'like normal'
  #
  # Otherwise call is with  :: and an explicit target package was given. This  makes re-exporting very simple
  #
  my $package=shift;
  my $target=$package eq __PACKAGE__ ? caller: $package;
  print "EXPORT: @_\n";
  print "Length: ".@_."\n";

  #Treat args as key value pairs, unless the value is a string.
  #in this case it is the name of a symbol to export
  my $k;my $v;

  no strict "refs";

  #my $export_ok= $target
  my $export_ok= \@{"@{[$target]}::EXPORT_OK"};
  my $export= \@{"@{[$target]}::EXPORT"};
  my $export_tags= \%{"@{[$target]}::EXPORT_TAGS"};
  #my $export;
  #my $export_tags;

  while(@_){
    $k=shift;
    DEBUG and print STDERR "\nProcessing key: $k\n";

    die "Expecting symbol name or group name" if ref $k;
    if(@_){
      my $r=ref $_[0];
      unless($r){
        DEBUG and print STDERR "value argument is scalar..next\n";
        push @$export, $k;
        push @$export_ok, $k;
        next
      }
      my $v=shift; 
      DEBUG and print STDERR "value argument is a REF.. continue\n";

      for($k){
        if(/export_ok$/ and $r eq "ARRAY"){
          push @$export_ok, @$v;
        }
        elsif(/export$/ and $r eq "ARRAY"){
          push @$export, @$v;
          push @$export_ok, @$v;
        }
        elsif($r eq "ARRAY"){
          #Assume key is a tag name
          push $export_tags->{$k}->@*, @$v;
          push @$export_ok, @$v;
        }
        else {
          die "Unkown export grouping: $k";
        }
      }
    }
  }

  # Generate the import sub here if it doesn't exist already

  local $"= " ";
  my $exporter=$target;
  print STDERR "About to eval for exporter $exporter\n";
  my $res=eval qq|
  print STDERR "exporter IS $exporter\n";
  package $exporter;
  no strict "refs";


  sub _self_import {

    print STDERR "\n\nSELF IMPORT\n";
    my \$ref_export_ok= \\\@@{[$exporter]}::EXPORT_OK;
    my \$ref_export= \\\@@{[$exporter]}::EXPORT;
    my \$ref_tags= \\\%@{[$exporter]}::EXPORT_TAGS;

    my \$target=shift;

    no strict "refs";
    for(\@_ ? \@_ : \@\$ref_export){
      print STDERR "PROCESSING \$_\n";
      my \@syms;
      if(/^:/){
        my \$name= s/^://r;

        my \$group=\$ref_tags->{\$name};
        die  "Tag \$name does not exists" unless \$group;
        push \@syms, \@\$group
      }
      else {
        #normal symbol
        print STDERR "normal symbol: \$_\n";
        print STDERR "exportok is: \@\$ref_export_ok\n";
        my \$t=\$_;
        my \$found=grep /\$t/, \@\$ref_export_ok;

        die "\$_ is not exported from ".__PACKAGE__."\n" unless \$found;
        push \@syms, \$_;
      }
      *{\$target."::".\$_}=\*{ __PACKAGE__ ."::".\$_} for \@syms;
    }

      print "END OF IMPORT\n";

  }


  sub import {
    no strict "refs";
    print STDERR "package is: ".__PACKAGE__."\n";

    my \$package=shift;
    my \$target=\$package eq __PACKAGE__ ? caller: \$package;
    
    print STDERR "target is: \$target\n";
    print "PACKAGE: ".__PACKAGE__;



    print "IMPORTING INTO \$target";
    _self_import(\$target, \@_);

    eval {_re_import(\$target, \@_)};

  }
  1;
  |;
  print "SDFSDFSDFDF\n";
  die $@ unless $res;
}
1;

=head1 NAME

Export::These - Terse Symbol (Re-)exporting

=head1 SYNOPSIS

A fine package with sub you want to export

  package My::Great::Pack;

  use Export::These qw<dog cat :colors=>[qw<blue green>]>

  sub dog {...}  
  sub cat {...} 
  sub blue {...} 
  sub green {...}
  

Use your package like usual

  use My::Great::Pack qw<:colors dog>

  # subs blue, green and dog imported

=head1 DESCRIPTION

A very small module performing three specific goals:

=over

=item Terse and implied specification of exports

I don't like having to repeat a symbol in a tag group or is ok to export. That
is implied.

=item Dead simple reexporting of symbols non caller namespaces

Simply chaning the call mechanism (->import or ::import) give you control over what namespace to import to. Makes 

=item Backwards compatitable with the Exporter::import

=back

