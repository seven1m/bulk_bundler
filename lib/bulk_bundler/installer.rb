module BulkBundler
  class Installer
    def initialize(ruby_version:, lockfiles:, verbose: false)
      @ruby_version = ruby_version
      @lockfiles = lockfiles
      @verbose = verbose
      @pool = ThreadPool.new(ENV['THREADS'] ? ENV['THREADS'].to_i : 8)
      at_exit { @pool.shutdown }
    end

    attr_reader :ruby_version

    def go!
      install_needed_regular_gems
      install_needed_git_gems
      puts '> ...done.'
    end

    private

    def gem_cmd
      cmd = "#{ruby_version_path}/bin/gem"
      unless File.exist?(cmd)
        puts "Error: Ruby version #{ruby_version} not found. Install it first."
        exit 1
      end
      cmd
    end

    def install_needed_regular_gems
      by_source = needed_regular_gems.group_by { |name, data| data[:source] }
      by_source.each do |source, gems|
        args = gems.flat_map { |name, data| data[:set].map { |v| "#{name}:#{v}" } }
        return if args.empty?
        puts '> Installing gems...'
        command = "#{gem_cmd} install -b -f --ignore-dependencies --no-document --no-post-install-message -s #{source} #{args.join(' ')}"
        puts command if verbose?
        sh(command)
      end
    end

    def needed_regular_gems
      return @needed_regular_gems if @needed_regular_gems
      puts '> Discovering gems...'
      @needed_regular_gems = regular_gems
      `#{gem_cmd} list -l`.each_line do |line|
        (name, versions) = line.strip.split(' ', 2)
        versions[1...-1].gsub(/default: /, '').split(', ').each do |version|
          version = version.split.first
          if regular_gems[name]
            puts "removing #{name} #{version} from ruby #{ruby_version} list" if verbose?
            @needed_regular_gems[name] = regular_gems[name]
            @needed_regular_gems[name][:set].delete(version)
            @needed_regular_gems.delete(name) if @needed_regular_gems[name][:set].empty?
          end
        end
      end
      @needed_regular_gems
    end

    def regular_gems
      return @regular_gems if @regular_gems
      @regular_gems = {}
      @lockfiles.each do |lockfile|
        gemfile = BulkBundler::GemfileLoader.new(lockfile.sub(/\.lock$/, ''))
        gemfile.load!
        gem_sources = gemfile.gems_by_name
        data = File.read(lockfile)
        special_source_gems = data.scan(/^  ([^ ]+)( \(.+\))?\!$/).map(&:first)
        data.scan(/([^\s]+) \(([0-9\.\-]+)\)/i).each do |name, version|
          next if special_source_gems.include?(name) && !gem_sources[name]
          source = gem_sources[name] || 'https://rubygems.org'
          @regular_gems[name] ||= { source: source, set: Set.new }
          @regular_gems[name][:set] << version
        end
      end
      @regular_gems
    end

    def install_needed_git_gems
      puts '> Checking out gems from git...'
      @pool.setup
      needed_git_gems.each do |name, data|
        url = data[:url]
        data[:set].each do |rev|
          @pool.schedule do
            install_git_gem(name, url, rev)
          end
        end
      end
      @pool.shutdown
    end

    def install_git_gem(name, url, rev)
      name_in_url = url.split('/').last.sub(/\.git$/, '')
      rev_short = rev[0...12]
      name_with_rev = "#{name_in_url}-#{rev_short}"
      path = File.join(git_gems_path, name_with_rev)
      command = "mkdir -p #{git_gems_path} && git clone #{url} #{path} 2>&1; cd #{path} && git fetch origin && git reset --hard #{rev} 2>&1"
      puts command if verbose?
      sh(command)
      dir_was = Dir.pwd
      Dir.chdir(path)
      gemspec_path = "#{path}/#{name}.gemspec"
      gemspec_path = Dir["#{path}/*.gemspec"].first unless File.exist?(gemspec_path)
      gemspec = Gem::StubSpecification.gemspec_stub(gemspec_path, path, git_gems_path).to_spec.to_ruby
      File.write(gemspec_path, gemspec)
      Dir.chdir(dir_was)
    end

    def needed_git_gems
      return @needed_git_gems if @needed_git_gems
      @needed_git_gems = git_gems
      Dir["#{git_gems_path}/*"].each do |existing|
        path = File.split(existing).last
        (_, name_in_url, rev) = path.match(/^(.+)\-([a-f0-9]+)$/).to_a
        next unless path
        @needed_git_gems.each do |name, data|
          next unless data[:url].split('/').last.sub(/\.git$/, '') == name_in_url
          data[:set].delete_if { |r| r.start_with?(rev) }
          @needed_git_gems.delete(name) if data[:set].empty?
        end
      end
      @needed_git_gems
    end

    def git_gems
      return @git_gems if @git_gems
      @git_gems = {}
      @lockfiles.each do |lockfile|
        data = File.read(lockfile)
        lines = data.scan(/GIT.+?\n\n/m).map { |spec| [spec.match(/^    ([^ ]+)/)[1], spec.match(/remote: (.+)/)[1], spec.match(/revision: ([a-f0-9]+)/)[1]] }
        lines.each do |name, url, revision|
          next if url !~ /^https?:/
          @git_gems[name] ||= { url: url, set: Set.new }
          @git_gems[name][:set] << revision
        end
      end
      @git_gems
    end

    def ruby_version_path
      "#{ENV['RBENV_ROOT']}/versions/#{ruby_version}"
    end

    def git_gems_path
      "#{ruby_version_path}/lib/ruby/gems/#{ruby_gem_version}/bundler/gems"
    end

    def ruby_gem_version
      ruby_version.match(/^\d+\.\d+/).to_s + '.0'
    end

    def verbose?
      @verbose
    end

    def sh(command)
      Command.new(command).run
    end
  end
end
