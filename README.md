# NAME

Export::These - Terse Symbol (Re)Exporting

# SYNOPSIS

A fine package, exporting subroutines,

```perl
package My::ModA;

use Export::These "dog", "cat", ":colors"=>[qw<blue green>];

sub dog {...}  
sub cat {...} 
sub blue {...} 
sub green {...}
1;
```

Another package which would like to reexport the subs from My::ModA:

```perl
 package My::ModB;
 use My::ModA;

 use Export::These ":colors"=>["more_colours"];

 sub _reexport {
   my ($packate, $target, @names)=@_;
   My::ModA->import(":colours") if grep /:colours/, @names;
 }

 sub more_colours { ....  }
 1;
```

Use package like usual:

```perl
use My::ModB qw<:colors dog>

# suburtines blue, green , more_colors and dog  imported
```

# DESCRIPTION

A module to make exporting symbols less verbose and facilitate reexporting of
symbols from dependencies with minimal input from the module author.

By default listing a symbol for export, even in a group/tag, means it will be
automatically marked as 'export\_ok', saving on duplication and managing two
separate lists.

It **DOES NOT** inherit from `Exporter` nor does it utilise the `import`
routine from `Exporter`. It injects its own `import` subroutine into the each
calling package. This injected subroutine adds the desired symbols to the
target package  as you would expect.

If the exporting package has a `_reexport` subroutine, it is called when being
imported. This is the 'hook' location where its safe to call `->import` on
any dependencies modules it might want to export. The symbols from these
packages will automatically be installed into the target package with no extra
configuration needed.

# MOTIVATION

Suppose you have a server module, which uses a configuration module to process
configuration data. However the main program (which imported the server module)
also needs to use the subroutines from the configuration module. The consumer
of the server module has to also add the configuration module as a dependency.

With this module the server can simply reexport the required configuration
routines, injecting the dependency, in stead of hard coding it.

# USAGE

## Specifying Symbols to Export

```perl
use Export::These ...;
```

The pragma takes a list of arguments to add to the `@EXPORT` and `EXPORT_OK`
variables. The items are taken as a name of a symbol or tag, unless the
following argument in the list is an array ref.

```perl
eg:

  use Export::These qw<sym1 sym2>;
```

If the item name is "export\_ok", then the items in the following array ref are
added to the `@EXPORT_OK` variable.

```perl
eg
  use Export::These export_ok=>[qw<sym1>];
```

If the item name is "export", then the items in the following array ref are
added to the `@EXPORT_OK`  and the `EXPORT` variables. This is the same as
simply listing the items at the top level.

```perl
eg 

  use Export::These export=>[qw<sym1>];
  # same as
  # use Export::These qw<sym1>;
```

If the item has another name, it is a tag name and the items in the following
array ref are added to the `%EXPORT_TAGS`  variable and to `@EXPORT_OK`

```perl
eg use Export::These group1=>["sym1"];
```

The list can contain any combination of the above:

```perl
eq use Export::These "sym1", group1=>["sym2", "sym3"], export_ok=>"sym4";
```

## Rexporting Symbols

If a subroutine called `_reexport` exists in the exporting package, it will be
called on (with the -> notation) during import, after the normal symbols have
been processed. The first argument is the package name of exporter, the second
is the package name of the importer (the target), and the remaining arguments
are the names of symbols or tags to import.

In this subroutine, you call `import` on as any packages you want to reexport:

```perl
eg 
use Sub::Module;
use Another::Mod;

sub _reexport {
  my ($package, $target, @names)=@_;

  Sub::Module->import;
  Another::Mod->import(@names);
  ...
}
```

## Conditional Reexporting

If you would only like to require and export on certain conditions, some extra
steps are needed to ensure correct setup of back end variables. Namely the
`$Exporter::ExportLevel` variable needs to be localized and set to 0 inside a
block BEFORE calling the `->import` subroutine on the package.

```perl
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
```

## Reexport Super Class Symbols

Any exported symbols from the inheritance chain can be reexported in the same
manner, as long as they are package subroutines and not methods:

```perl
eg 

  package ModChild;
  parent ModParent;

    # or
    
  class ModChild :isa(ModParent)

  
  sub _reexport {
    my ($package, $target, @names)=@_;
    $package->SUPER::import(@names);
  }
```

# COMPARISON TO OTHER MODULES

[Import::Into](https://metacpan.org/pod/Import%3A%3AInto) Provides clean way to reexport symbols, though you will have to
roll your own 'normal' export of symbols from you own package.

[Import::Base](https://metacpan.org/pod/Import%3A%3ABase) Requires a custom package to group the imports and reexports
them. This is a different approach and might better suit your needs. 

Reexporting symbols with `Exporter` directly is a little cumbersome.  You
either need to import everything into you module name space (even if you don't
need it) and then reexport from there. Alternatively you can import directly
into a package, but you need to know at what level in the call stack it is.
This is exactly what this module addresses.

# REPOSITOTY and BUGS

Please report and feature requests or bugs via the github repo:

[https://github.com/drclaw1394/perl-export-these.git](https://github.com/drclaw1394/perl-export-these.git)

# AUTHOR

Ruben Westerberg, <drclaw@mac.com>

# COPYRIGHT AND LICENSE

Copyright (C) 2023 by Ruben Westerberg

Licensed under MIT

# DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE.
