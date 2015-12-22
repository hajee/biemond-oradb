newparam(:source_dir) do
  desc <<-EOT
    The source folder in the zip to use.

    This parameter is only valid when you are using a source zip. It describes the folder in the zip to use as a base
    for running the several Opatch utilities. When you don't specify a value, it
    uses the patch_id.

    example:

        ora_opatch{ "/app/grid/product/12.1/grid:21359755":
          ensure     => present,
          ...
          tmp_dir    => '/tmp/patches'
          source     => '/downloads/p21523260_121020_Linux-x86-64.zip',
          source_dir => '21523260',
        }

    This will run the Opatch command on the folder `/tmp/patches/21523260'

  EOT
end

def source_dir
  if self[:source_dir]
    self[:source_dir]
  else
    self[:patch_id]
  end
end