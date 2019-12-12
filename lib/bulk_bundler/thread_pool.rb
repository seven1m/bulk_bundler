require 'thread'

# The ThreadPool class below is Copyright © 2012, Kim Burgestrand kim@burgestrand.se
# Licensed under X11 License
# https://www.burgestrand.se/code/ruby-thread-pool/
# some modifications have been made for this program
module BulkBundler
  class ThreadPool
    def initialize(size)
      @size = size
      @jobs = Queue.new
      Thread.abort_on_exception = true
    end

    def setup
      @pool = Array.new(@size) do |i|
        Thread.new do
          Thread.current[:id] = i
          catch(:exit) do
            loop do
              job, args = @jobs.pop
              job.call(*args)
            end
          end
        end
      end
    end

    def schedule(*args, &block)
      @jobs << [block, args]
    end

    def shutdown
      return unless @pool
      @size.times do
        schedule { throw :exit }
      end
      @pool.map(&:join)
    end
  end
end
