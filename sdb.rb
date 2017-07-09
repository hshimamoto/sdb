#!/usr/bin/env ruby
# vim: set sw=2 sts=2:

require "json"
require 'pp'

$dbfile = "database.sdb"

# Usage
#  sdb <command> [opt] [params]
#   command
#   - edit

cmd = ARGV[0]
exit 1 unless cmd

class SDBCONFIG
  def initialize
    @cfg = {}
    begin
      File.open(".sdbconfig") { |f|
	@cfg = JSON.load(f)
      }
    rescue
    end
    @cfg["database"] = $dbfile unless @cfg["database"]
  end
  def database
    @cfg["database"]
  end
end

class SDB
  def initialize
    @cfg = SDBCONFIG.new
    @db = @cfg.database
    @obj
    begin
      File.open(@db) { |f|
	@obj = JSON.load(f)
      }
    rescue
      puts "No database: #{@db}"
      exit
    end
    parse
    @dirty = false
  end
  def save
    return unless @dirty
    File.open(@db, "w") { |f|
      JSON.dump(@obj, f)
    }
  end
  def parse
    # "name" is the primary key
    k = ["name"]
    @obj.each { |e|
      k.concat(e.keys)
    }
    @keys = k.uniq
  end
  # implement commands
  def method_missing(method, *args)
    # unknown command
    puts "unknown command: #{method}"
  end
  def edit(args)
    #pp args
    path = args[0]
    unless path then
      puts "need file path to edit"
      exit 1
    end
    # determine fields
    k = ['name']
    begin
      # if file exists, get headers
      hdr = ""
      File.open(path) { |f|
	hdr = f.readline
      }
      if hdr =~ /^# (.+)/ then
	k = $1.split(/\t/)
      else
	puts "invalid file #{path}"
	exit 1
      end
    rescue
      k = @keys
    end
    # update file
    hdr = "# " + k.join("\t")
    begin
      File.open(path, "w") { |f|
	f.puts(hdr)
	@obj.each { |e|
	  cols = []
	  k.each { |i|
	    if e[i] then
	      cols << e[i]
	    else
	      cols << ''
	    end
	  }
	  f.puts(cols.join("\t"))
	}
      }
    rescue
      puts "unable to write file #{path}"
      exit 1
    end
    system("vim #{path}")
    # update database
    begin
      # if file exists, get headers
      hdr = ""
      lines = []
      File.open(path) { |f|
	hdr = f.readline
	lines = f.readlines
      }
      if hdr =~ /^# (.+)/ then
	k = $1.split(/\t/)
      else
	puts "invalid file #{path}"
	exit 1
      end
      #pp lines
      upd = []
      lines.each { |l|
	next if l =~ /^#/
	vs = l.chomp.split(/\t/)
	idx = 0
	o = {}
	vs.each { |v|
	  o[k[idx]] = v
	  idx += 1
	}
	pp o
	orig = nil
	@obj.each { |e|
	  if o["name"] == e["name"] then
	    @keys.each { |k|
	      o[k] = e[k] unless o[k]
	    }
	  end
	}
	pp o
	upd << o
      }
      @obj = upd
      @dirty = true
    rescue
      puts "unable to reload file #{path}"
      exit 1
    end
  end
  def dump(args)
    # dump header
    hdr = "# " + @keys.join("\t")
    puts hdr
    @obj.each { |e|
      cols = []
      @keys.each { |k|
        cols << e[k]
      }
      puts cols.join("\t")
    }
  end
end

sdb = SDB.new
sdb.send(cmd, ARGV[1 .. -1])
sdb.save
