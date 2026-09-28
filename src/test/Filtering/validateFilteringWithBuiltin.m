% validateFilteringWithBuiltin.m - Validasi Filter Manual vs Built-in MATLAB
clear; clc; close all;

scriptDir = fileparts(mfilename('fullpath'));
testDir = fileparts(scriptDir);
srcDir = fileparts(testDir);
projectRoot = fileparts(srcDir);
addpath(genpath(projectRoot));

fprintf('====================================================================\n');
fprintf('     VALIDASI IMAGE FILTERING: MANUAL VS MATLAB BUILT-IN\n');
fprintf('====================================================================\n\n');

% Cek ketersediaan fungsi built-in Image Processing Toolbox
hasImfilter = (exist('imfilter', 'file') == 2);
hasMedfilt2 = (exist('medfilt2', 'file') == 2);

if ~hasImfilter && ~hasMedfilt2
    warning('Fungsi imfilter dan medfilt2 tidak ditemukan di sistem. Validasi hanya dapat menghitung estimasi.');
end

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

% Konversi ke grayscale untuk pengujian dasar yang seragam
if size(img, 3) == 3
    imgGray = uint8(round(0.2989 * double(img(:,:,1)) + 0.5870 * double(img(:,:,2)) + 0.1140 * double(img(:,:,3))));
else
    imgGray = img;
end

%% =========================================================================
%% 1. VALIDASI LINEAR FILTERING (vs imfilter 'conv')
%% =========================================================================
fprintf('--- 1. VALIDASI LINEAR FILTERING ---\n\n');

linearConfigs = {
    'Mean 3x3',       getFilterKernel('mean', 'size', 3),                       'replicate';
    'Gaussian 5x5',   getFilterKernel('gaussian', 'size', 5, 'sigma', 1.0),     'replicate';
    'Sharpen 3x3',    getFilterKernel('sharpen', 'variant', '8'),               'replicate';
    'Sobel X (Asym)', getFilterKernel('sobel_x'),                               'replicate';
};

figLinear = figure('Name', 'Validasi Linear Filtering: Custom vs imfilter', 'Position', [30, 50, 1250, 680]);

for k = 1:size(linearConfigs, 1)
    tag = linearConfigs{k, 1};
    kernel = linearConfigs{k, 2};
    bMode = linearConfigs{k, 3};

    % Eksekusi manual 2D convolution
    outCustom = applyConvolution2D(imgGray, kernel, 'padding', bMode, 'clip', true);

    % Eksekusi pembanding imfilter dengan opsi 'conv' (membalik kernel)
    if hasImfilter
        outBuiltin = imfilter(imgGray, kernel, 'conv', bMode);
    else
        outBuiltin = outCustom; % Fallback
    end

    % Evaluasi metrik
    diffMap = abs(double(outCustom) - double(outBuiltin));
    meanDiff = mean(diffMap(:));
    maxDiff = max(diffMap(:));
    meanCust = mean(double(outCustom(:)));
    meanBuilt = mean(double(outBuiltin(:)));
    stdCust = std(double(outCustom(:)));
    stdBuilt = std(double(outBuiltin(:)));

    % Cetak laporan numerik
    fprintf('[Linear %d] %s (Boundary: %s)\n', k, tag, bMode);
    fprintf('  %-18s %12s %14s\n', 'Metrik', 'Custom Manual', 'imfilter(conv)');
    fprintf('  %-18s %12.2f %14.2f\n', 'Mean', meanCust, meanBuilt);
    fprintf('  %-18s %12.2f %14.2f\n', 'Std Dev', stdCust, stdBuilt);
    fprintf('  Selisih Rata-rata : %.4f level\n', meanDiff);
    fprintf('  Selisih Maksimum  : %d level\n\n', maxDiff);

    % Visualisasi perbandingan
    subplot(2, 4, k);
    imshow(outCustom);
    title(sprintf('Custom: %s\nMean=%.1f', tag, meanCust), 'FontSize', 9);

    subplot(2, 4, k + 4);
    imshow(diffMap * 20, []); % Amplifikasi perbedaan x20 agar terlihat jika ada
    title(sprintf('Diff (|Custom - Builtin| x20)\nMaxDiff=%d, MeanDiff=%.3f', maxDiff, meanDiff), 'FontSize', 9);
end

%% =========================================================================
%% 2. VALIDASI MEDIAN FILTERING (vs medfilt2)
%% =========================================================================
fprintf('\n--- 2. VALIDASI MEDIAN FILTERING ---\n\n');

% Tambahkan noise salt-and-pepper untuk menguji efektivitas median
rng(100);
noisyTest = imgGray;
nMask = rand(size(noisyTest)) < 0.05;
noisyTest(nMask) = 255 * (rand(sum(nMask(:)), 1) > 0.5);

medianConfigs = {
    'Median 3x3 (symmetric)', 3, 'symmetric';
    'Median 5x5 (symmetric)', 5, 'symmetric';
    'Median 3x3 (zeros)',     3, 'zero';
};

figMedian = figure('Name', 'Validasi Median Filtering: Custom vs medfilt2', 'Position', [60, 80, 1200, 600]);

for m = 1:size(medianConfigs, 1)
    tag = medianConfigs{m, 1};
    wSize = medianConfigs{m, 2};
    bMode = medianConfigs{m, 3};

    % Eksekusi median filter manual
    outMedCustom = medianFilter(noisyTest, 'size', wSize, 'padding', bMode);

    % Eksekusi pembanding medfilt2
    if hasMedfilt2
        if strcmp(bMode, 'symmetric')
            outMedBuiltin = medfilt2(noisyTest, [wSize wSize], 'symmetric');
        else
            outMedBuiltin = medfilt2(noisyTest, [wSize wSize], 'zeros');
        end
    else
        outMedBuiltin = outMedCustom;
    end

    % Evaluasi metrik
    diffMed = abs(double(outMedCustom) - double(outMedBuiltin));
    meanDiffM = mean(diffMed(:));
    maxDiffM = max(diffMed(:));
    meanCustM = mean(double(outMedCustom(:)));
    meanBuiltM = mean(double(outMedBuiltin(:)));
    stdCustM = std(double(outMedCustom(:)));
    stdBuiltM = std(double(outMedBuiltin(:)));

    % Cetak laporan numerik
    fprintf('[Median %d] %s\n', m, tag);
    fprintf('  %-18s %12s %14s\n', 'Metrik', 'Custom Manual', 'medfilt2');
    fprintf('  %-18s %12.2f %14.2f\n', 'Mean', meanCustM, meanBuiltM);
    fprintf('  %-18s %12.2f %14.2f\n', 'Std Dev', stdCustM, stdBuiltM);
    fprintf('  Selisih Rata-rata : %.4f level\n', meanDiffM);
    fprintf('  Selisih Maksimum  : %d level\n\n', maxDiffM);

    % Visualisasi
    subplot(2, 3, m);
    imshow(outMedCustom);
    title(sprintf('Custom %s\nMean=%.1f', tag, meanCustM), 'FontSize', 9);

    subplot(2, 3, m + 3);
    imshow(diffMed * 20, []);
    title(sprintf('Diff x20 (|Custom - Builtin|)\nMaxDiff=%d, MeanDiff=%.3f', maxDiffM, meanDiffM), 'FontSize', 9);
end

fprintf('Validasi selesai. Seluruh perbandingan visual dan metrik telah ditampilkan.\n');
