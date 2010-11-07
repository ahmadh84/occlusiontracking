function [status] = remote_ldof(im1_filepath, im2_filepath)
% Computes LDOF on a remote machine

    username = 'ahumayun';
    passwd = 'DID_YOU_THINK_I_WILL_COMMIT_MY_PWD_ON_GIT!';
    address = 'newgate.cs.ucl.ac.uk';
    matlab_path = '/opt/matlabR2010b/bin/matlab';

    putty_path = 'C:/Progra~2/PuTTY/';
    
    % get path
    [status out] = system([putty_path 'plink -pw ' passwd ' ' username '@' address ' pwd']);
    userpath = strtrim(out);
    
    % create temporary dir
    fprintf('--> Transferring files to %s for LDOF\n', address);
    
    temp_dir = ['temp' num2str(round(rand*100000))];
    [status out] = system([putty_path 'plink -pw ' passwd ' ' username '@' address ' mkdir ' userpath '/thesis/' temp_dir]);
    if(status ~= 0) status = 1; return; end
    
    % transfer the images
    [status out] = system([putty_path 'pscp -pw ' passwd ' "' im1_filepath '" ' username '@' address ':' userpath '/thesis/' temp_dir]);
    if(status ~= 0) status = 2; return; end
    [status out] = system([putty_path 'pscp -pw ' passwd ' "' im2_filepath '" ' username '@' address ':' userpath '/thesis/' temp_dir]);
    if(status ~= 0) status = 2; return; end
    
    % transfer script
    [status out] = system([putty_path 'pscp -pw ' passwd ' "remoteexec/compute_ldof.m" ' username '@' address ':' userpath '/thesis/' temp_dir]);
    if(status ~= 0) status = 2; return; end
    
    % run matlab remotely
    fprintf('--> Computing LDOF on %s\n', address);
    [status out] = system([putty_path 'plink -pw ' passwd ' ' username '@' address ' "cd ' userpath '/thesis/' temp_dir '; ' matlab_path ' -nojvm -nodisplay -nosplash -r compute_ldof"']);
    if(status ~= 0) status = 3; return; end
    
    % scp back the ldof file
    fprintf('--> Transferring LDOF from %s\n', address);
    dest_dir = fileparts(im1_filepath);
    [status out] = system([putty_path 'pscp -pw ' passwd ' ' username '@' address ':' userpath '/thesis/' temp_dir '/largedispof.mat "' dest_dir '"' ]);
    if(status ~= 0) status = 4; return; end
    
    % delete path
    [status out] = system([putty_path 'plink -pw ' passwd ' ' username '@' address ' rm -rf ' userpath '/thesis/' temp_dir]);
    if(status ~= 0) status = 5; return; end
end