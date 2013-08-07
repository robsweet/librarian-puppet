require 'librarian/source/git'
require 'librarian/puppet/source/local'

module Librarian
  module Source
    class Git
      class Repository
        def hash_from(remote, reference)
          branch_names = remote_branch_names[remote]
          if branch_names.include?(reference)
            reference = "#{remote}/#{reference}"
          end

          command = %W(rev-parse #{reference}^{commit} --quiet)
          run!(command, :chdir => true).strip
        end

        # Naming this method 'version' causes an exception to be raised.
        def module_version
          return '0.0.1' unless modulefile?

          metadata  = ::Puppet::ModuleTool::Metadata.new
          begin
            ::Puppet::ModuleTool::ModulefileReader.evaluate(metadata, modulefile)
          rescue ArgumentError, SyntaxError => error
            puts "Warning in "+modulefile+" "+error.to_s
            return '0.0.1'
          end
          metadata.version
        end

        def manifests(source, name)
          if source.send(:repository_cached?)
            source = source.dup
            source.send(:sha=, current_commit_hash)
            [Manifest.new(source, name, module_version)]
          else
            manifest = Manifest.new(source, name, module_version)
            [manifest].compact
          end
        end

        def dependencies
          return {} unless modulefile?

          metadata = ::Puppet::ModuleTool::Metadata.new

          begin
            ::Puppet::ModuleTool::ModulefileReader.evaluate(metadata, modulefile)
          rescue ArgumentError, SyntaxError => error
            puts "Warning in "+modulefile+" "+error.to_s
            return {}
          end

          metadata.dependencies.inject({}) do |h, dependency|
            name = dependency.instance_variable_get(:@full_module_name)
            version = dependency.instance_variable_get(:@version_requirement)
            h.update(name => version)
          end
        end

        def modulefile
          File.join(path, 'Modulefile')
        end

        def modulefile?
          File.exists?(modulefile)
        end
      end
    end
  end

  module Puppet
    module Source
      class Git < Librarian::Source::Git
        include Local

        def cache!
          return vendor_checkout! if vendor_cached?

          if environment.local?
            raise Error, "Could not find a local copy of #{uri} at #{sha}."
          end

          super

          cache_in_vendor(repository.path) if environment.vendor?
        end

        def vendor_tgz
          environment.vendor_source + "#{sha}.tar.gz"
        end

        def vendor_cached?
          vendor_tgz.exist?
        end

        def vendor_checkout!
          repository.path.rmtree if repository.path.exist?
          repository.path.mkpath

          Dir.chdir(repository.path.to_s) do
            %x{tar xzf #{vendor_tgz}}
          end

          repository_cached!
        end

        def cache_in_vendor(tmp_path)
          Dir.chdir(tmp_path.to_s) do
            %x{git archive #{sha} | gzip > #{vendor_tgz}}
          end
        end

        def fetch_version(name, extra)
          cache!
          found_path = found_path(name)
          v = repository.module_version
          v = v.gsub("-",".") # fix for some invalid versions like 1.0.0-rc1

          # if still not valid, use some default version
          unless Gem::Version.correct? v
            debug { "Ignoring invalid version '#{v}' for module #{name}, using 0.0.1" }
            v = '0.0.1'
          end
        end

        def fetch_dependencies(name, version, extra)
          repository.dependencies.map do |k, v|
            v = Requirement.new(v).gem_requirement
            Dependency.new(k, v, forge_source)
          end
        end

        def forge_source
          Forge.from_lock_options(environment, :remote=>"http://forge.puppetlabs.com")
        end

        def manifests(name)
          repository.manifests(self, name)
        end

        def to_s
          short_sha = sha ? sha[0..6] : nil
          path ? "#{uri}##{ref}-#{short_sha}(#{path})" : "#{uri}##{ref}-#{short_sha}"
        end

      end
    end
  end
end
