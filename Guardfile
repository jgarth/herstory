# A sample Guardfile
# More info at https://github.com/guard/guard#readme

directories %w(lib spec/herstory)
clearing :on

guard :rspec, cmd: "bin/rspec" do
  require "guard/rspec/dsl"
  dsl = Guard::RSpec::Dsl.new(self)

  # RSpec files
  rspec = dsl.rspec
  watch(rspec.spec_helper) { rspec.spec_dir }
  watch(rspec.spec_support) { rspec.spec_dir }
  watch(%r{spec/[^dummy/].+_spec\.rb})

  # Ruby files
  ruby = dsl.ruby
  dsl.watch_spec_files_for(ruby.lib_files)

  # Rails files
  rails = dsl.rails(view_extensions: %w(erb haml slim))
  dsl.watch_spec_files_for(rails.app_files)

  # Rails config changes
  watch(rails.spec_helper)     { rspec.spec_dir }
end
