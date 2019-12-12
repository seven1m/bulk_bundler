module BulkBundler
  class Command
    def initialize(command)
      @command = command
    end

    def run
      cmd = IO.popen("#{@command} 2>&1")
      $stdout.write(cmd.getc) until cmd.eof?
      cmd.close
      raise 'error' unless $? == 0
    end
  end
end
