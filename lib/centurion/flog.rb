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
      ast = @parser.process(ruby, file)
      return unless ast
      mass[file] = ast.mass
      process ast
    rescue RegexpError, SyntaxError, Racc::ParseError
    end
  end
end
