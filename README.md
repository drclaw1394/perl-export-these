# NAME

Export::Terse - Terse Symbol (Re)Exporting

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
   my ($target, @names)=@_;
   My::ModA->import(":colours") if grep /:colours/, @names;
 }

 sub more_colours { ....  }
 1;
```

Use your package like usual:

```perl
use My::ModB qw<:colors dog>

# suburtines blue, green , more_colors and dog  imported
```

# DESCRIPTION

An terse approach to specifying symbol exports and an easy way to reexport
symbols from dependencies. 

Some key features:

- Terse and Implied Specification for export/ok

    Listing a symbol for export, even in a group/tag, means it is automatically
    marked as 'export\_ok'.  Less repetition, less typing.  

- Simple reexporting of symbols into a target name space

    A module author can implement a `_reexport` package subroutine, with any
    number of import calls `->import` of other modules. The routine is only
    executed after necessary setup is complete and is safe to use with `Exporter`
    type modules.

This module **DOES NOT** inherit from `Exporter` nor does it utilise the
`import` routine from `Exporter`.  It injects its own import subroutine into
the calling package. This injected subroutine adds the desired symbols to the
target package similar to `Exporter` and also calls the `_reexport`
subroutine, if the package has one defined.

# WHY USE THIS MODULE

This is best illustrated with an example. Suppose you have a server module,
which uses a configuration module to process configuration data. However the
main program also needs to use the subroutines from the configuration module.
The issues with this is the consumer of the server module has to add more code
to actually work with it.

It also forces the consumer to know which subroutines/data structure are needed
or permitted in the server to actually do the import correctly.

This module address this by allowing the Server module to easily reexport what
it knows a consumer will need to from a sub module.

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
  use Export::These (export_ok=>[qw<sym1>]);
```

If the item name is "export", then the items in the following array ref are
added to the `@EXPORT_OK`  and the `EXPORT` variables. This is the same as
simply listing the items at the top level.

```perl
eg 

  use Export::These (export=>[qw<sym1>]);
  # same as
  # use Export::These qw<sym1>;
```

If the item has another name, it is a tag name and the items in the following
array ref are added to the `%EXPORT_TAGS`  variable and to `@EXPORT_OK`

```perl
eg use Export::These (group1=>["sym1"]);
```

The list can contain any combination of the above:

```perl
eq use Export::These ("sym1", group1=>["sym2", "sym3"], export_ok=>"sym4");
```

## Rexporting Symbols

If a subroutine called `_reexport` exists in your package, it will be called
during import, after the normal symbols have been processed. The first argument
is the package name of importer (the target), the remaining arguments are the
names of symbols or tags to import.

In this subroutine, you call `import` on as any packages you want to reexport:

```perl
eg 
use Sub::Module;
use Another::Mod;

sub _reexport {
  my ($target, @names)=@_;

  Sub::Module->import;
  Another::Mod->import(@names);
  ...
}
```

## Conditional Rexporting

If you would only like to require and export on certain conditions, some extra
steps are required to ensure the dependencies modules are correctly required:

```perl
sub _reexport {

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

# COMPARISON TO OTHER MODULES

Reexporting symbols with `Exporter` directly is a little cumbersome.  You
either need to import everything into you module name space (even if you don't
need it) and the reexport from there. Alternatively you can import directly into a
package, you need to know at what level in the call stack it is, which is
pretty limiting.

There are a few 'Exporter' alternatives on CPAN but making it easy to reexport
symbols is the main benefit of this module.

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
