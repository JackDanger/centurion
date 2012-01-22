require 'flog'

class ::Flog < SexpProcessor
  def flog_source(ruby, file)
    warn "** flogging #{file}" if option[:verbose]

    ast = @parser.process(ruby, file)
    return unless ast
    mass[file] = ast.mass
    process ast
  rescue RegexpError, SyntaxError, Racc::ParseError => e
    if e.inspect =~ /<%|%>/ or ruby =~ /<%|%>/ then
      warn "#{e.inspect} at #{e.backtrace.first(5).join(', ')}"
      warn "\n...stupid lemmings and their bad erb templates... skipping"
    else
      warn "ERROR: parsing ruby file #{file}"
      unless option[:continue] then
        warn "ERROR! Aborting. You may want to run with --continue."
        raise e
      end
      warn "#{e.class}: #{e.message.strip} at:"
      warn "  #{e.backtrace.first(5).join("\n  ")}"
    end
  end
end

module Centurion
  class Flog

    attr_accessor :source, :filename, :commit

    def initialize source, filename, commit
      @source   = source
      @filename = filename
      @commit   = commit
    end

    def meter
      whip = ::Flog.new
      whip.flog_source source, __FILE__
      whip.each_by_score do |class_method, score, call_list|
        yield({
          :file       => filename,
          :total      => whip.total,
          :average    => whip.average,
          :method     => class_method,
          :score      => score,
          :sha        => commit.sha,
          :time       => commit.date.to_i,
          :author     => commit.author.to_s,
          :parent     => commit.parents.first.sha.to_s,
          :call_list  => call_list.sort_by { |k,v| -v }.inject({}) {|h,(k,v)| h[k]=v;h}
        })
      end
    end
  end
end
