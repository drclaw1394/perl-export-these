package Export::These;

use strict;
use warnings;

our $VERSION="v0.1.0";

sub import {
  my $package=shift;
  my $exporter=caller;

  #Treat args as key value pairs, unless the value is a string.
  #in this case it is the name of a symbol to export
  my ($k, $v);

  no strict "refs";

  # Locate or create the EXPORT, EXPORT_OK and EXPORT_TAGS package variables.
  # These are used to accumulate our exported symbol names across multiple
  # use Export::Terse ...; statements
  # 
  my $export_ok= \@{"@{[$exporter]}::EXPORT_OK"};
  my $export= \@{"@{[$exporter]}::EXPORT"};
  my $export_tags= \%{"@{[$exporter]}::EXPORT_TAGS"};

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
  my $exist=eval {*{\${$exporter."::"}{import}}{CODE}};
  if($exist){
    return;
  }

  my $res=eval qq|
  package $exporter;
  no strict "refs";


  sub _self_export {
    shift;

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

    $exporter->_self_export(\$target, \@_);
    
    local \$Exporter::ExportLevel=\$Exporter::ExportLevel+3;
    my \$ref=eval {*{\\\${\$package."::"}{_reexport}}{CODE}};

    if(\$ref){
      $exporter->_reexport(\$target, \@_);
    }

  }

  1;
  |;
  die $@ unless $res;
}
1;


=head1 NAME

Export::These - Terse Symbol (Re)Exporting


=head1 SYNOPSIS

A fine package, exporting subroutines,

  package My::ModA;

  use Export::These "dog", "cat", ":colors"=>[qw<blue green>];

  sub dog {...}  
  sub cat {...} 
  sub blue {...} 
  sub green {...}
  1;

Another package which would like to reexport the subs from My::ModA:

  package My::ModB;
  use My::ModA;

  use Export::These ":colors"=>["more_colours"];

  sub _reexport {
    my ($packate, $target, @names)=@_;
    My::ModA->import(":colours") if grep /:colours/, @names;
  }
 
  sub more_colours { ....  }
  1;


Use package like usual:

  use My::ModB qw<:colors dog>

  # suburtines blue, green , more_colors and dog  imported



=head1 DESCRIPTION

Simplifies exporting of package symbols and reexporting symbols from
dependencies with less work.

Some key features:

=over

=item Terse and Implied Specification for export/ok

Listing a symbol for export, even in a group/tag, means it is automatically
marked as 'export_ok'.  Less repetition, less typing.  

=item Simple reexporting of symbols into a target name space

A module author can implement a C<_reexport> package subroutine, with any
number of import calls C<-E<gt>import> of other modules. The routine is only
executed after necessary setup is complete and is safe to use with C<Exporter>
type modules.

=back

This module B<DOES NOT> inherit from C<Exporter> nor does it utilise the
C<import> routine from C<Exporter>.  It injects its own import subroutine into
the calling package. This injected subroutine adds the desired symbols to the
target package similar to C<Exporter> and also calls the C<_reexport>
subroutine, if the package has one defined.

=head1 WHY USE THIS MODULE

This is best illustrated with an example. Suppose you have a server module,
which uses a configuration module to process configuration data. However the
main program also needs to use the subroutines from the configuration module.
The issues with this is the consumer of the server module has to add more code
to actually work with it.

It also forces the consumer to know which subroutines/data structure are needed
or permitted in the server to actually do the import correctly.


This module address this by allowing the Server module to easily reexport what
it knows a consumer will need to from a sub module.


=head1 USAGE

=head2 Specifying Symbols to Export

    use Export::These ...;

The pragma takes a list of arguments to add to the C<@EXPORT> and C<EXPORT_OK>
variables. The items are taken as a name of a symbol or tag, unless the
following argument in the list is an array ref.

    eg:

      use Export::These qw<sym1 sym2>;


If the item name is "export_ok", then the items in the following array ref are
added to the C<@EXPORT_OK> variable.
    

    eg
      use Export::These (export_ok=>[qw<sym1>]);


If the item name is "export", then the items in the following array ref are
added to the C<@EXPORT_OK>  and the C<EXPORT> variables. This is the same as
simply listing the items at the top level.
  
    eg 

      use Export::These (export=>[qw<sym1>]);
      # same as
      # use Export::These qw<sym1>;


If the item has another name, it is a tag name and the items in the following
array ref are added to the C<%EXPORT_TAGS>  variable and to C<@EXPORT_OK>

    eg use Export::These (group1=>["sym1"]);


The list can contain any combination of the above:

    eq use Export::These ("sym1", group1=>["sym2", "sym3"], export_ok=>"sym4");


=head2 Rexporting Symbols

If a subroutine called C<_reexport> exists in your package, it will be called
on (with the -> notation) during import, after the normal symbols have been
processed. The first argument is the package name of exporter, the second is
package name of the importer (the target), and the remaining arguments are the
names of symbols or tags to import.

In this subroutine, you call C<import> on as any packages you want to reexport:

  eg 
  use Sub::Module;
  use Another::Mod;

  sub _reexport {
    my ($package, $target, @names)=@_;

    Sub::Module->import;
    Another::Mod->import(@names);
    ...
  }

=head2 Conditional Rexporting

If you would only like to require and export on certain conditions, some extra
steps are required to ensure the dependencies modules are correctly required:

  sub _reexport {
    my ($package, $target, @names)=@_;

    if(SOME_CONDITION){
      {
        # In an localised block, reset the export level
        local $Exporter::ExportLevel=0;
        require Sub::Module;
        require Another::Module;
      }

      Sub::Module->import;
      Another::Mod->import(@names);

    }
  }

=head2 Reexport Inhertited  Symbols

Any exported symbols from the inheritance chain can be reexported in the same
manner:

  eg 
  parent ModParent;

  sub _reexport {
    my ($package, $target, @names)=@_;
    $package->SUPER::import(@names);
  }


=head1 COMPARISON TO OTHER MODULES

L<Import::Into> Provides clean way to reexport symbols, though you will have to
roll your own 'normal' export of symbols from you own package.

L<Import::Base> Requires a custom package to group the imports and rexports
them. This is a different approach and might better suit your needs. 


Reexporting symbols with C<Exporter> directly is a little cumbersome.  You
either need to import everything into you module name space (even if you don't
need it) and then reexport from there. Alternatively you can import directly
into a package, but you need to know at what level in the call stack it is.
This is exactly what this module addresses.


There are a few 'Exporter' alternatives on CPAN but making it easy to reexport
symbols is the main benefit of this module.

=head1 REPOSITOTY and BUGS

Please report and feature requests or bugs via the github repo:

L<https://github.com/drclaw1394/perl-export-these.git>

=head1 AUTHOR

Ruben Westerberg, E<lt>drclaw@mac.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2023 by Ruben Westerberg

Licensed under MIT

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE.

=cut

