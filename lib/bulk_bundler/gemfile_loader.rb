module BulkBundler
  class GemfileLoader
    def initialize(filename)
      @default_source = 'https://rubygems.org'
      @current_source = @default_source
      @gems = {}
      @filename = filename
    end

    attr_reader :gems

    def source(s)
      if block_given?
        source_was = @current_source
        @current_source = s
        yield
        @current_source = source_was
      else
        @current_source = @default_source = s
      end
    end

    def gem(name, *args)
      options = args.last.is_a?(Hash) ? args.last : {}
      return if options[:git] || options[:path]
      @gems[@current_source] ||= []
      @gems[@current_source] << name
    end

    def git_source(*); end
    def group(*); yield; end

    def load!
      eval File.read(@filename)
    end

    def gems_by_name
      @by_name = {}
      gems.each do |source, list|
        list.each do |gem|
          @by_name[gem] = source
        end
      end
      @by_name
    end
  end
end
