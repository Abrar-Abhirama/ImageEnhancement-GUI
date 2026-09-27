% startup.m pada root project
rootPath = fileparts(mfilename('fullpath'));
srcPath = fullfile(rootPath, 'src');

if exist(srcPath, 'dir')
    addpath(genpath(srcPath));
    run(fullfile(srcPath, 'startup.m'));
else
    error('Folder src tidak ditemukan pada %s', rootPath);
end
