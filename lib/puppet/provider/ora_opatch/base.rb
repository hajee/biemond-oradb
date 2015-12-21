require 'easy_type'

Puppet::Type.type(:ora_opatch).provide(:base) do
  include EasyType::Provider

  desc 'Base provider for Oracle patches'

  mk_resource_methods

  confine :true => false # This is NEVER a valid provider. It is just used as a base class

  def self.instances
    fail 'resource list not supported for ora_opatch type'
  end

  def self.prefetch(resources)
    orainst_dir = check_single_orainst_dir(resources)
    all_patches = oracle_homes(resources).collect {|h| patches_in_home(h, os_user_for_home(resources, h), orainst_dir)}.flatten
    resources.keys.each do |patch_name|
      if all_patches.include?(patch_name)
        resources[patch_name].provider = new(:name => name, :ensure => :present)
      end
    end
  end

  def opatch(command, options)
    options = {:failonfail => true, :uid => os_user, :combine => true}.merge(options)
    full_command = "export ORACLE_HOME=#{oracle_product_home_dir}; cd #{oracle_product_home_dir}; #{oracle_product_home_dir}/OPatch/opatch #{command}"
    output = Puppet::Util::Execution.execute(full_command, options)
    Puppet.info output
    fail "Opatch contained an error" unless output=~/OPatch completed|OPatch succeeded|opatch auto succeeded|opatchauto succeeded/
    output
  end

  def opatchauto(command, options)
    options = {:failonfail => true, :combine => true}.merge(options)
    full_command = "export ORACLE_HOME=#{oracle_product_home_dir}; cd #{oracle_product_home_dir}; #{oracle_product_home_dir}/OPatch/opatchauto #{command}"
    output = Puppet::Util::Execution.execute(full_command, options)
    Puppet.info output
    output
  end


  [:patch_id, :os_user, :oracle_product_home_dir, :orainst_dir, :ocmrf_file, :source,:tmp_dir].each do | prop|
    define_method(prop) do
      resource[prop]
    end
  end

  private

  def installed_patches
    orainst = "-invPtrLoc #{resource[:orainst_dir]}/oraInst.loc "
    opatch("lsinventory #{orainst}").scan(/Patch\s.(\d+)\s.*:\sapplied on/).flatten
  end

  def self.patches_in_home(oracle_product_home_dir, os_user, orainst_dir)
    full_command  = "#{oracle_product_home_dir}/OPatch/opatch lsinventory -oh #{oracle_product_home_dir} -invPtrLoc #{orainst_dir}/oraInst.loc"
    raw_list = Puppet::Util::Execution.execute(full_command, :failonfail => true, :uid => os_user)
    Puppet.info raw_list
    patch_ids = raw_list.scan(/Patch\s.(\d+)\s.*:\sapplied on/).flatten
    patch_ids.collect{|p| "#{oracle_product_home_dir}:#{p}"}
  end

  def self.os_user_for_home(resources, home)
    os_users = resources.map{|k,v| v.os_user if v.oracle_product_home_dir == home}.compact.uniq
    fail "db_opatch doesn't support multiple os_users in one oracle_home" if os_users.size > 1
    os_users.first
  end

  def self.check_single_orainst_dir(resources)
    orainst_dir = resources.map{|k,v| v.orainst_dir}.uniq
    fail "db_opatch doesn't support multiple orainst_dir" if orainst_dir.size > 1
    orainst_dir.first
  end

  def self.oracle_homes(resources)
    resources.map{|k,v| v.oracle_product_home_dir}.uniq
  end

end
