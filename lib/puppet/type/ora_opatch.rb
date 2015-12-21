require 'pathname'
$:.unshift(Pathname.new(__FILE__).dirname)
$:.unshift(Pathname.new(__FILE__).dirname.parent.parent + 'easy_type' + 'lib')
require 'easy_type'

module Puppet
  #
  Type.newtype(:ora_opatch) do
    include EasyType

    desc 'This resource allows you to manage opatch patches on a specific database home.'

    ensurable

    validate do
      fail "Source is a required attribute for #{name}." unless source
    end

    set_command([:opatch, :opatchauto])

    on_create  do | command_builder |
      source = extract_source
      provider.apply_patch(source, command_builder)
      remove_unzipped_file(source, command_builder)
    end

    on_modify  do | command_builder |
      fail "Internal error. A patch is either there ot not. It cannot be modified."
    end

    on_destroy  do | command_builder |
      #
      # Only the opatchauto requires the source to be extracted
      # The other providers use stored information.
      #
      source = extract_source if self[:provider] == :opatchauto
      provider.remove_patch(source, command_builder)
      remove_unzipped_file(source, command_builder)
    end

    map_title_to_attributes(:name, :oracle_product_home_dir, :patch_id) do
      /^((.*):(.*))$/
    end

    parameter :name
    parameter :patch_id
    parameter :os_user
    parameter :oracle_product_home_dir
    parameter :orainst_dir
    parameter :ocmrf_file
    parameter :source
    parameter :tmp_dir
    parameter :source_folder

    def opatch(command, options = {})
      provider.opatch(command, options)
    end

    def opatchauto(command, options = {})
      provider.opatchauto(command, options)
    end

    def is_puppet_url?(url)
      url.scan(/^puppet:\/\/.*$/) != []
    end

    def extract_source
      if is_puppet_url?(source)
        fetched_source = fetch_source(source)
      else
        fetched_source = source
      end
      fetched_source = unzip(fetched_source) if is_zipfile?(fetched_source)
    end

    def is_zipfile?(file)
      Pathname(file).extname.downcase == '.zip'
    end

    def fetch_source(file)
      fail "puppet url's not (yet) supported."
    end

    def check_source_dir(parent)
      patch_source_dir = Dir.glob("#{parent}/**/#{source_folder}").first
      fail "#{source} doesn't contain folder #{source_folder}" unless patch_source_dir
      patch_source_dir
    end

    def unzip(file)
      Puppet.info "Unzipping source #{source} to #{tmp_dir}"
      environment = {}
      environment[:PATH] = '/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin'
      Puppet::Util::Execution.execute("unzip -o #{file} -d #{tmp_dir}", :failonfail => true, :uid => os_user, :custom_environment => environment )
      Puppet.info "Done Unzipping source #{source} to #{tmp_dir}"
      check_source_dir(tmp_dir)
    end

    def remove_unzipped_file(source, command_builder)
      command_builder.after("-rf #{tmp_dir}",:rm)
    end

  end
end
