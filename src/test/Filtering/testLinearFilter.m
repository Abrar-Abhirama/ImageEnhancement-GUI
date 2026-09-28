% testLinearFilter.m - Pengujian Filter Linier Manual
clear; clc; close all;

scriptDir = fileparts(mfilename('fullpath'));
testDir = fileparts(scriptDir);
srcDir = fileparts(testDir);
projectRoot = fileparts(srcDir);
addpath(genpath(projectRoot));

fprintf('=====================================================\n');
fprintf('         PENGUJIAN LINEAR FILTERING MANUAL\n');
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
    [X, Y] = meshgrid(1:256, 1:256);
    img = uint8(mod(X + Y, 256));
    fprintf('Menggunakan citra sintetis fallback (256x256).\n\n');
end

% Daftar filter yang diuji
filterTests = {
    'mean',      {'size', 5},             'Mean Filter 5x5 (Smoothing)';
    'gaussian',  {'size', 5, 'sigma', 1}, 'Gaussian Filter 5x5 (Smoothing)';
    'sharpen',   {'variant', '8'},        'Sharpening Filter (Penajaman)';
    'sobel',     {},                      'Sobel Filter (Deteksi Tepi)';
    'laplacian', {'variant', '8'},        'Laplacian Filter (Deteksi Tepi)';
};

numTests = size(filterTests, 1);
fig = figure('Name', 'Hasil Linear Filtering Manual', 'Position', [50, 50, 1200, 700]);

% Tampilkan citra asli
subplot(2, 3, 1);
if ndims(img) == 3, imshow(img); else, imshow(img, []); end
title('Citra Asli', 'FontSize', 11, 'FontWeight', 'bold');

for i = 1:numTests
    fType = filterTests{i, 1};
    fParams = filterTests{i, 2};
    fDesc = filterTests{i, 3};

    % Eksekusi filtering linier manual
    [outImg, info] = linearFilter(img, fType, fParams{:});

    % Tampilkan hasil
    subplot(2, 3, i + 1);
    if ndims(outImg) == 3, imshow(outImg); else, imshow(outImg, []); end
    title(fDesc, 'FontSize', 10, 'FontWeight', 'bold');

    fprintf('[%d/%d] %s selesai.\n', i, numTests, fDesc);
end

fprintf('\nSeluruh pengujian filter linier selesai.\n');
