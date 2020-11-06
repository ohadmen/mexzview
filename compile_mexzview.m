function compile_mexzview(zview_install_dir)
if ~exist('zview_install_dir','var')
    zview_install_dir ='C:\Program Files\zview';
end
cmd = sprintf("mex -v COMPFLAGS='$COMPFLAGS /std:c++17' zview_module.cpp -I'%s' -L'%s' -l'zview_inf'",zview_install_dir ,zview_install_dir );
eval(cmd);
end