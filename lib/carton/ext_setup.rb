# encoding: utf-8

require 'path'

module Carton
  
  # Handler for ruby/ext/Setup, for enabling extensions and 
  # static options prior to a build
  class ExtSetup
    def initialize(filename)
      @filename=Path(filename)
    end

    def enable(*exts)
      exts.each do |ext|
        quoted_ext = ext.gsub(%r{/}, '\\/')
        system "sed -i 's/^\##{quoted_ext}$/#{quoted_ext}/' #{@filename}"
      end
    end


    def enabled
      result = []
      raise "#{@filename} doesn't exist!" unless @filename.exists?
      @filename.read.lines.each do |line|
        next if line =~ /\Aoption/
        next if line.strip.length == 0
        next if line =~ /\A#/

        result << line.strip
      end
      result
    end

    def static!
      enable("option nodynamic")
    end


    def extinit_c
      c = <<-C
#include "ruby.h"
#define init(func, name) {void func _((void)); ruby_init_ext(name, func);}
      
void ruby_init_ext _((const char *name, void (*init)(void)));
void Init_ext _((void))
{
      C
      enabled.each do |name|
        c << "init(Init_#{name.split("/").last}, \"#{name}.so\");\n"
      end
      c << "}\n"
    end

  end # class ExtSetup


end # module Carton
