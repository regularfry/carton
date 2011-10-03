# carton #

Carton is a static ruby application builder, which will compile
pure-ruby applications, which may depend on pure-ruby gems, into a
single static binary which can be distributed without any accompanying
infrastructure.

It uses rvm to fetch and build ruby, interfaces with bundler to handle
gem dependencies, and will play nicely with your existing pure-ruby
projects.

## Installation ##

First install [rvm](http://rvm.beginrescueend.com). Then:

    rvm install ruby-1.8.7-p302
    gem install bundler carton

## How to  ##

### Hello World ###

To build a project with carton, you need to specify the entry point
for the application (typically a file under `bin/`), and the output
filename. The simplest possible session might look like this:


    $ cat bin/myapp1
    puts "Hello world"
    
    $ carton -i bin/myapp1 -o dist/myapp1
    <lots of build output>
    dist/myapp1 built
    
    $ dist/myapp1
    Hello world

### lib/ ###
    
If you want to include more than one file in your application, you can
supply a glob of files to include, and a load path.  By default,
carton will pick up and use all ruby files under lib/. That is, there
is a default load path of `lib`, and a default glob of `lib/**/*.rb`:

    $ cat bin/myapp2
    require 'thing'
    Thing.run
    
    $ cat lib/thing.rb
    module Thing
      def self.run
        puts "I am a Thing!"
      end
    end
    
    $ carton -i bin/myapp2 -o dist/myapp2
    <lots of build output>
    dist/myapp2 built
    
    $ dist/myapp2
    I am a Thing!
    
If you have source files which you need to include which is *not*
under `lib`, then you can specify it with the `-l` switch:

    $ cat bin/myapp3
    require 'src/wandering_thing'
    WanderingThing.run

    $ cat src/wandering_thing.rb
    module WanderingThing
      def self.run
        puts "I have wandered!"
      end
    end
      
    $ carton -i bin/myapp3 -o dist/myapp3 -l src/**/*.rb
    <lots of build output>
    dist/myapp3 built
    
    $ dist/myapp3
    I have wandered!

### $LOAD_PATH ###
 
If your application needs `$LOAD_PATH` set to other than the default,
you can use the `-L` switch:

    $ cat bin/myapp4
    require 'wandering_thing' # Note the lack of 'src'
    WanderingThing.run

    $ cat src/wandering_thing.rb
    module WanderingThing
      def self.run
        puts "Here I am"
      end
    end
      
    $ carton -i bin/myapp4 -o dist/myapp4 -l src/**/*.rb -L src
    <lots of build output>
    dist/myapp4 built
    
    $ dist/myapp4
    Here I am!

### build/ ###

By default, carton does its compilation in the `build/` directory. You
can change this with the `-b` flag:

    $ carton -i bin/myapp5 -o dist/myapp5 -b mybuild
    <snip>
    dist/myapp5 built
    
    $ ls mybuild 
    app.db app.o app.sql carton_boot.o extinit.o
    libamalgalite3.a libcrypto.a lib.db lib.o librubycode.a
    libruby-static.a lib.sql libssl.a libz.a ruby

You may want to change this if build/ is already being used by your
application.

### Gemfile ###

If there is a Gemfile in your project's root, carton will use it to
package any named gems into the application.

    $ cat Gemfile
    source "http://rubygems.org"
    gem "json_pure"
    
    $ cat bin/myapp6
    require 'json'
    puts [:hello,:world].to_json
    
    $ carton -i bin/myapp6 -o dist/myapp6
    <lots of build output>
    dist/myapp6 built
    
    $ dist/myapp6
    ["hello","world"]
    

Gem extensions are compiled into the final binary.


## How it works ##

The premise of carton is simple: to take ruby files and, instead of
reading them from the filesystem when they are required, read
them from an in-memory database.

Amalgalite provides the SQLite3 wrapper necessary to build ruby files
into a suitable data structure, and it also supplies a replacement for
the `require` method. Carton uses amalgalite to build SQLite3
databases containing your project's ruby files, ruby's stdlib, and the
contents of your gem dependencies, which are dumped to sql and then
converted into static archives which can be directly linked into a
bootstrap file, carton\_boot.c. During its initialisation,
carton\_boot.c loads the SQL from these buffers into SQLite in-memory
databases, and ruby's `require` method is then hijacked by amalgalite
to load from these rather than the filesystem.

An inevitable consequence of this mechanism is that code from the
[amalgalite](http://github.com/copiousfreetime/amalgalite) project
*will be included* as part of any binary you build.  If you distribute
that binary to anyone else, you are bound by amalgalite's
[license](http://github.com/copiousfreetime/amalgalite/blob/master/LICENSE).

## What doesn't work ##

- Anything involving the `\_\_FILE\_\_` constant.  This is unlikely
  ever to work, and you probably shouldn't be using it in a library
  anyway.
- `require 'rubygems'`.  Just no.  'Nuff said.
- Any ruby version other than 1.8.7-p302. To be honest, other ruby
  versions *may* work, I just haven't tried them yet.

## Credits ##

None of this would have been possible without Jeremy Hinegardner's
work on [crate](http://github.com/copiousfreetime/crate) and
[amalgalite](http://github.com/copiousfreetime/amalgalite). carton\_boot.c
is a very slightly modified version of crate\_boot.c, and almost all of
the cleverness involved in the require mechanism is down to
amalgalite.

Once you've taken out that original work, the pile of bugs that
remains is entirely [Alex Young](mailto:alex@bytemark.co.uk)'s fault.
