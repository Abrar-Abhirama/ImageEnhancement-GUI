% testFilteringAPI.m - Pengujian API Spatial Image Filtering
clear; clc; close all;

scriptDir = fileparts(mfilename('fullpath'));
testDir = fileparts(scriptDir);
srcDir = fileparts(testDir);
projectRoot = fileparts(srcDir);
addpath(genpath(projectRoot));

fprintf('=====================================================\n');
fprintf('         PENGUJIAN UNIFIED FILTERING API\n');
fprintf('=====================================================\n\n');

% Muat citra uji
testPath = fullfile(projectRoot, 'test_images');
imgFile = '';
if exist(testPath, 'dir')
    files = dir(fullfile(testPath, '**', '*.png'));
    if ~isempty(files)
        imgFile = fullfile(files(1).folder, files(1).name);
    end
end

if ~isempty(imgFile)
    img = imread(imgFile);
    fprintf('Citra uji: %s\n\n', imgFile);
else
    [X, Y] = meshgrid(1:200, 1:200);
    img = uint8(mod(X + Y, 256));
    fprintf('Menggunakan citra sintetis fallback (200x200).\n\n');
end

% 1. Uji Linear Filtering via API
fprintf('[1] Uji Linear Filtering via applyFilter\n');
[outGaussian, infoG] = applyFilter(img, 'linear', 'kernel', getFilterKernel('gaussian', 'size', 5, 'sigma', 1.2));
fprintf('    Category: %s | Type: %s | Output size: %s\n', infoG.category, infoG.filterType, mat2str(infoG.outputSize));

[outSharpen, infoS] = applyFilter(img, 'sharpen', 'variant', '8');
fprintf('    Category: %s | Type: %s | Output size: %s\n\n', infoS.category, infoS.filterType, mat2str(infoS.outputSize));

% 2. Uji Non-Linear Filtering via API
fprintf('[2] Uji Non-Linear (Median) Filtering via applyFilter\n');
[outMed, infoM] = applyFilter(img, 'median', 'size', 3);
fprintf('    Category: %s | Type: %s | Output size: %s\n\n', infoM.category, infoM.filterType, mat2str(infoM.outputSize));

% 3. Uji Integrasi applyEnhancement
fprintf('[3] Uji Integrasi ke applyEnhancement\n');
resEnhance = applyEnhancement(img, 'median', 'size', 3);
fprintf('    Method: %s\n', resEnhance.method);
fprintf('    Mean before: %.2f | Mean after: %.2f\n', resEnhance.statsBefore.mean, resEnhance.statsAfter.mean);
fprintf('    Std before : %.2f | Std after : %.2f\n\n', resEnhance.statsBefore.std, resEnhance.statsAfter.std);

% Visualisasi
figure('Name', 'Unified Filtering API Results', 'Position', [50, 50, 1100, 600]);

subplot(2, 2, 1);
if ndims(img) == 3, imshow(img); else, imshow(img, []); end
title('Citra Asli', 'FontWeight', 'bold');

subplot(2, 2, 2);
if ndims(outGaussian) == 3, imshow(outGaussian); else, imshow(outGaussian, []); end
title('Linear: Gaussian 5x5 (\sigma=1.2)', 'FontWeight', 'bold');

subplot(2, 2, 3);
if ndims(outSharpen) == 3, imshow(outSharpen); else, imshow(outSharpen, []); end
title('Linear: Sharpening (8-neighbor)', 'FontWeight', 'bold');

subplot(2, 2, 4);
if ndims(outMed) == 3, imshow(outMed); else, imshow(outMed, []); end
title('Non-Linear: Median Filter 3x3', 'FontWeight', 'bold');

fprintf('Seluruh pengujian API filtering selesai dengan sukses.\n');
