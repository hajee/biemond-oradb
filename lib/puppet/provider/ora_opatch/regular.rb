require 'easy_type'

Puppet::Type.type(:ora_opatch).provide(:regular, :parent => :base) do
  include EasyType::Provider

  desc 'Apply Oracle regular OPatches'

  #
  # This is bit of a hack. id is always root, but we need to declare a default provider
  #
  defaultfor :id => 'root'  

  def apply_patch( source_dir, command_builder)
    ocmrf   = ocmrf_file.nil? ? '' : " -ocmrf #{ocmrf_file}"
    command_builder.add "apply -silent #{ocmrf} -oh #{oracle_product_home_dir} #{source_dir}", :uid => os_user
  end

  def remove_patch(source_dir, command_builder)
    command_builder.add "rollback -id #{patch_id} -silent -oh #{oracle_product_home_dir}", :uid => os_user
  end

end
