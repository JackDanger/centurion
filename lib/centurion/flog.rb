require 'flog'
module Centurion
  class Flog

    attr_accessor :file, :commit

    def initialize file, commit
      @file   = file
      @commit = commit
    end

    def meter
      whip = ::Flog.new
      whip.flog file
      whip.each_by_score do |class_method, score, call_list|
        Centirion.insert({
          :file       => file,
          :total      => whip.total,
          :average    => whip.average,
          :method     => class_method,
          :name       => "#{file}##{method}",
          :score      => score,
          :sha        => commit[:sha],
          :time       => commit[:time],
          :author     => commit[:author],
          :call_list  => Hash[call_list.sort_by { |k,v| -v }.map]
        })
      end
    end
  end
end
