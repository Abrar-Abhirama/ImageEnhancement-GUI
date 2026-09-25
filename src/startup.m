% Dapatkan path ke folder src
if exist(fileparts(mfilename('fullpath')), 'dir')
    srcPath = fileparts(mfilename('fullpath'));
else
    srcPath = pwd;
end

% Tambahkan subfolder ke path
addpath(genpath(srcPath));

fprintf('Image Enhancement Toolbox initialized.\n');
fprintf('Source path: %s\n', srcPath);
fprintf('\n');

% List folder yang ditambahkan
fprintf('Subfolders added:\n');
fprintf('  - enhancement/\n');
fprintf('  - analysis/\n');
fprintf('  - utils/\n');
fprintf('  - test/\n');
fprintf('\n');

% Cek apakah test_images ada
projectRoot = fileparts(srcPath);
testPath = fullfile(projectRoot, 'test_images');

if exist(testPath, 'dir')
    fprintf('Test images found: %s\n', testPath);
else
    fprintf('Note: test_images folder not found at: %s\n', testPath);
end

fprintf('\nReady to use! Contoh:\n');
fprintf('  img = imread(''test_images/Kasus 1/image_01.png'');\n');
fprintf('  result = intensityTransform(img, ''power'', ''gamma'', 0.5);\n');
fprintf('\n');