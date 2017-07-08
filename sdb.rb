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

class SDB
  def initialize
    db = $dbfile
    @obj
    begin
      File.open(db) { |f|
	@obj = JSON.load(f)
      }
    rescue
      puts "No database: #{db}"
      exit
    end
    parse
    @dirty = false
  end
  def save
    return unless @dirty
    File.open(db, "w") { |f|
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
    pp args
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
