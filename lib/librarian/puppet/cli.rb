require 'librarian/helpers'

require 'librarian/cli'
require 'librarian/puppet'

module Librarian
  class Cli < Thor
    autoload :ManifestPresenter, "librarian/puppet/cli/manifest_presenter"
  end
end

module Librarian
  module Puppet
    class Cli < Librarian::Cli

      module Particularity
        def root_module
          Puppet
        end
      end

      include Particularity
      extend Particularity

      source_root Pathname.new(__FILE__).dirname.join("templates")

      def init
        copy_file environment.specfile_name

        if File.exists? ".gitignore"
          gitignore = File.read('.gitignore').split("\n")
        else
          gitignore = []
        end

        gitignore << ".tmp/" unless gitignore.include? ".tmp/"
        gitignore << "modules/" unless gitignore.include? "modules/"

        File.open(".gitignore", 'w') do |f|
          f.puts gitignore.join("\n")
        end
      end

      desc "install", "Resolves and installs all of the dependencies you specify."
      option "quiet", :type => :boolean, :default => false
      option "verbose", :type => :boolean, :default => false
      option "line-numbers", :type => :boolean, :default => false
      option "clean", :type => :boolean, :default => false
      option "strip-dot-git", :type => :boolean
      option "path", :type => :string
      option "destructive", :type => :boolean, :default => false
      option "local", :type => :boolean, :default => false
      def install
        ensure!
        clean! if options["clean"]
        unless options["destructive"].nil?
          environment.config_db.local['destructive'] = options['destructive'].to_s
        end
        if options.include?("strip-dot-git")
          strip_dot_git_val = options["strip-dot-git"] ? "1" : nil
          environment.config_db.local["install.strip-dot-git"] = strip_dot_git_val
        end
        if options.include?("path")
          environment.config_db.local["path"] = options["path"]
        end

        environment.config_db.local['mode'] = options['local'] ? 'local' : nil

        resolve!
        install!
      end

      desc "package", "Cache the puppet modules in vendor/puppet/cache."
      option "quiet", :type => :boolean, :default => false
      option "verbose", :type => :boolean, :default => false
      option "line-numbers", :type => :boolean, :default => false
      option "clean", :type => :boolean, :default => false
      option "strip-dot-git", :type => :boolean
      option "path", :type => :string
      option "destructive", :type => :boolean, :default => false
      def package
        environment.vendor!
        install
      end

      desc "outdated", "Lists outdated dependencies."
      option "verbose", :type => :boolean, :default => false
      option "line-numbers", :type => :boolean, :default => false
      def outdated
        ensure!
        resolution = environment.lock
        resolution.manifests.sort_by(&:name).each do |manifest|
          source = manifest.source
          source_manifest = source.manifests(manifest.name).first
          if source.class == Librarian::Puppet::Source::Git
            next if manifest.version == source_manifest.version && manifest.source.sha == source_manifest.source.sha
          else
            next if manifest.version == source_manifest.version
          end

          source_sha = source
          if manifest.source.class == Librarian::Puppet::Source::Git
            sha = " #{manifest.source.sha[0..6]}"
            source_sha = " #{source_manifest.source.sha[0..6]}"
          end
          say "#{manifest.name} (#{manifest.version}#{sha} -> #{source_manifest.version}#{source_sha})"
        end
      end


      def version
        say "librarian-puppet v#{Librarian::Puppet::VERSION}"
      end
    end
  end
end
