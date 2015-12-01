require 'easy_type'

Puppet::Type.type(:ora_opatch).provide(:auto, :parent => :base) do

  def context
    "export ORACLE_HOME=#{oracle_product_home_dir}; cd #{oracle_product_home_dir}; "
  end

  def apply_patch( source_dir, command_builder)
    ocmrf   = ocmrf_file.nil? ? '' : " -ocmrf #{ocmrf_file}"
    "auto #{source_dir} #{ocmrf} -oh #{oracle_product_home_dir}"
  end

  def remove_patch(source_dir, command_builder)
    "auto -rollback #{source_dir} #{ocmrf} -oh #{oracle_product_home_dir}"
  end

end
