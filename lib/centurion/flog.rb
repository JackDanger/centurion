require 'flog'

module Centurion
  class Flog < ::Flog
    attr_accessor :source, :filename

    def initialize source, filename
      @source   = source
      @filename = filename
      super()
    end

    def meter
      flog_source source, __FILE__
      each_by_score do |class_method, score, call_list|
        yield({
          :total      => total,
          :average    => average,
          :method     => class_method,
          :score      => score,
          :call_list  => call_list.sort_by { |k,v| -v }.inject({}) {|h,(k,v)| h[k]=v;h}
        })
      end
    end

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
end
