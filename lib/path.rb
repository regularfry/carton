# encoding: utf-8

class Path
  def initialize(str)
    @path=str.to_s
  end

  def /(*others)
    self.class.new( File.join( @path, *(others.map{|o| o.to_s}) ) )
  end

  def expand
    self.class.new( File.expand_path( @path ) )
  end

  def to_s; to_str; end
  def to_str; @path; end


  def dirname; File.dirname( @path ); end
  def basename; File.basename( @path ); end

  def dir; self.class.new( self.dirname ); end
  def mkdir_p; FileUtils.mkdir_p( @path ); self; end

  def [](glob)
    Dir[self / glob].map{|d| self.class.new( d )}
  end

  def chdir(&blk)
    Dir.chdir( @path, &blk )
  end

  def mv(other)
    new_path = self.class.new(other)
    FileUtils.mv @path, new_path
    return new_path
  end

  def rm_rf
    FileUtils.rm_rf @path
    self
  end

  def exists?; File.exists?( @path ); end
  def file?; File.file?( @path ); end
  def directory?; File.directory?( @path ); end

  def <=>(other)
    return @path <=> other.to_s
  end

  def write(data)
    self.dir.mkdir_p
    File.open( @path, "wb"){|f| f.write( data )}
  end

  def read; File.read( @path ); end

  def touch
    self.dir.mkdir_p
    FileUtils.touch( @path )
    self
  end

  def method_missing(sym, *args, &blk)
    @path.__send__(sym, *args, &blk)
  end
end

def Path(str)
  Path.new(str.to_s)
end
