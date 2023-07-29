package Export::These;

use strict;
use warnings;


use version; our $VERSION=version->declare("v0.1.0");
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

  #Treat args as key value pairs, unless the value is a string.
  #in this case it is the name of a symbol to export
  my $k;my $v;

  no strict "refs";

  # Locate or create the EXPORT, EXPORT_OK and EXPORT_TAGS package variables.
  # These are used to accumulate our exported symbol names across multiple
  # use Export::Terse ...; statements
  # 
  my $export_ok= \@{"@{[$target]}::EXPORT_OK"};
  my $export= \@{"@{[$target]}::EXPORT"};
  my $export_tags= \%{"@{[$target]}::EXPORT_TAGS"};
  while(@_){
    $k=shift;

    die "Expecting symbol name or group name" if ref $k;
    my $r=ref $_[0];
    unless($r){
      push @$export, $k;
      push @$export_ok, $k;
      next
    }
    my $v=shift; 

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

  # Generate the import sub here if it doesn't exist already

  local $"= " ";
  my $exporter=$target;
  my $exist=eval {*{\${$exporter."::"}{import}}{CODE}};
  if($exist){
    return;
  }

  my $res=eval qq|
  package $exporter;
  no strict "refs";


  sub _self_export {

    my \$ref_export_ok= \\\@@{[$exporter]}::EXPORT_OK;
    my \$ref_export= \\\@@{[$exporter]}::EXPORT;
    my \$ref_tags= \\\%@{[$exporter]}::EXPORT_TAGS;

    my \$target=shift;

    no strict "refs";
    for(\@_ ? \@_ : \@\$ref_export){
      my \@syms;
      if(/^:/){
        my \$name= s/^://r;

        my \$group=\$ref_tags->{\$name};
        die  "Tag \$name does not exists" unless \$group;
        push \@syms, \@\$group
      }
      else {
        #non tag symbol
        my \$t=\$_;
        \$t="\\\\\$t" if \$t =~ /^\\\$/;
        my \$found=grep /\$t/, \@\$ref_export_ok;
        die "\$_ is not exported from ".__PACKAGE__."\n" unless \$found;
        push \@syms, \$_;
      }
      
      my \%map=(
        '\$'=>"SCALAR",
        '\@'=>"ARRAY",
        '\%'=>"HASH",
        '\&'=>"CODE"
        );

      for(\@syms){
        my \$prefix=substr(\$_,0,1);
        my \$name=\$_; 
        my \$type=\$map{\$prefix};

        \$name=substr \$_, 1 if \$type;
        \$type//="CODE";
        eval { *{\$target."::".\$name}= *{ \\\${__PACKAGE__ ."::"}{\$name}}{\$type}; };
        die "Could not export \$prefix\$name from ".__PACKAGE__ if \$\@;


      }
    }


  }


  sub import {
    my \$package=shift;
    my \$target=(caller(\$Exporter::ExportLevel))[0];


    _self_export(\$target, \@_);
    
    local \$Exporter::ExportLevel=\$Exporter::ExportLevel+3;
    my \$ref=eval {*{\\\${\$package."::"}{_reexport}}{CODE}};

    if(\$ref){
      \$target=(caller(\$Exporter::ExportLevel))[0];
      _reexport(\$target, \@_);
    }

  }

  1;
  |;
  die $@ unless $res;
}
1;

=head1 NAME

Export::Terse - Terse Symbol (Re)Exporting


=head1 SYNOPSIS

A fine package with subs you want to export

  package My::ModA;

  use Export::These qw<dog cat :colors=>[qw<blue green>]>

  sub dog {...}  
  sub cat {...} 
  sub blue {...} 
  sub green {...}

Another package which would like to reexport the subs:

  package My::ModB;
  use My::ModA;

  use Export::These ":colours"=>"more_colours";

  sub _reexport {
    my ($target, @names)=@_;
    My::ModA::import($target, ":colours") if grep /:colours/, @names;
  }
 
  sub more_colours { ....  }


Use your package like usual:

  use My::ModB qw<:colors dog>

  # subs blue, green and dog  and more_colours imported



=head1 DESCRIPTION

A terse way of specifying symbol exports and an easy way for modules to rexport
symbols to an intrested pacakge:

=over

=item Terse and Implied specification for export/ok

If you list a symbol for export, it is automatically added to 'export_ok'
Likewsise adding a symbol to a tag group, export_ok is then implied too.


=item Simple reexporting of symbols into a target name space

Changing the call mechanism (->import or ::import) gives you control over what
namespace to import to. 


=back

=head1 WHY USE THIS MODULE

This is best illustrated with an example. Suppose you have a server modules,
which uses a configuratoin module to process config data. However the main
program also needs to use the subroutines from the config module. The issues
with this is the consumer of the server moudle has to add more code to actually
work with it.

It also forces the consumer to know which subroutines/data structure are needed
or permitted in the server to actually do the import correctly


This module address this by allowing the Server module to easily reexport what
it thinks a consumer will need to from a sub module.


=head1 USAGE

=head2 Specifying Symbols to Export

    use Export::These ...;

The pragma takes a list of arguments to add to the C<@EXPORT> and C<EXPORT_OK>
variables. The items are taken as a name of a symbol, unless the following
argument in the list is an array ref.


    eg:

      use Export::These qw<sym1 sym2>;


If the item name is "export_ok", then the items in the following array ref are added to the C<@EXPORT_OK> variable.
    

    eg use Export::These (export_ok=>[sym1]);

If the item name is "export", then the items in the following array ref are
added to the C<@EXPORT_OK>  and the C<EXPORT> variables. This is the same as
simply listing the items at the top level.
  
    eg use Export::These (export=>[sym1]);

If the item has anyother name, it is a tag name and the items in the following
array ref are added to the C<%EXPORT_TAGS>  variable:

    eg use Export::These (group1=>["sym1"]);


The list can contain any combination of the above:

    eq use Export::These ("sym1", group1=>["sym2", "sym3"], export_ok=>"sym4");

=head2 Rexporting Symbols

If a subroutine called C<_reexport> exists in your package, it will be called
during import. The first argument is the package name of importer, the
remaining arguments are the names of symbols to import.

In this subroutine, you call import on any packages you want to rexport (assume
they also use L<Export::These>). The key is to call with the :: notation not he
arrow notation

  sub _reexport {
    my ($target, @names)=@_;

    Sub::Module::import($target, ...); 
  }

=head1 COMPARISON TO OTHER MODULES

Reexporting symbols with C<Exporter> is a little combersome.  You either need
to import everything into you module name space (even if you don't need it) and
the reexport from there. While you can import directly into a package, you need
to know at what level in the call stack it is, which is pretty limiting.


There are a few 'Exporter' alternatives on CPAN but making it easy to rexport
symbols is the main difference
