% testMedianFilter.m - Pengujian Filter Median Manual
clear; clc; close all;

scriptDir = fileparts(mfilename('fullpath'));
testDir = fileparts(scriptDir);
srcDir = fileparts(testDir);
projectRoot = fileparts(srcDir);
addpath(genpath(projectRoot));

fprintf('=====================================================\n');
fprintf('          PENGUJIAN MANUAL MEDIAN FILTER\n');
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
    imgClean = imread(imgFile);
    fprintf('Citra uji: %s\n', imgFile);
else
    [X, Y] = meshgrid(1:200, 1:200);
    imgClean = uint8(mod(X + Y, 256));
    fprintf('Menggunakan citra sintetis fallback (200x200).\n');
end

% Tambahkan noise salt-and-pepper secara manual
noisyImg = imgClean;
rng(42);
noiseDensity = 0.08;
maskSalt = rand(size(noisyImg, 1), size(noisyImg, 2)) < (noiseDensity / 2);
maskPepper = rand(size(noisyImg, 1), size(noisyImg, 2)) >= (noiseDensity / 2) & ...
             rand(size(noisyImg, 1), size(noisyImg, 2)) < noiseDensity;

for ch = 1:size(noisyImg, 3)
    channel = noisyImg(:, :, ch);
    channel(maskSalt) = 255;
    channel(maskPepper) = 0;
    noisyImg(:, :, ch) = channel;
end

% Jalankan median filter manual 3x3 dan 5x5
fprintf('Menjalankan median filter manual (3x3)...\n');
out3x3 = medianFilter(noisyImg, 'size', 3);

fprintf('Menjalankan median filter manual (5x5)...\n');
out5x5 = medianFilter(noisyImg, 'size', 5);

% Validasi pembanding dengan medfilt2 jika tersedia
if exist('medfilt2', 'file') == 2
    if size(noisyImg, 3) == 1
        ref3x3 = medfilt2(noisyImg, [3 3], 'symmetric');
    else
        ref3x3 = zeros(size(noisyImg), 'uint8');
        for c = 1:3
            ref3x3(:, :, c) = medfilt2(noisyImg(:, :, c), [3 3], 'symmetric');
        end
    end
    outManualSym = medianFilter(noisyImg, 'size', 3, 'padding', 'symmetric');
    diffMed = abs(double(outManualSym) - double(ref3x3));
    fprintf('Validasi terhadap medfilt2 (mode symmetric):\n');
    fprintf('  Rata-rata selisih: %.4f level\n', mean(diffMed(:)));
    fprintf('  Maksimum selisih : %d level\n\n', max(diffMed(:)));
end

% Visualisasi hasil
figure('Name', 'Hasil Pengujian Median Filter', 'Position', [80, 80, 1100, 500]);

subplot(1, 4, 1);
if ndims(imgClean) == 3, imshow(imgClean); else, imshow(imgClean, []); end
title('Citra Asli (Bersih)', 'FontWeight', 'bold');

subplot(1, 4, 2);
if ndims(noisyImg) == 3, imshow(noisyImg); else, imshow(noisyImg, []); end
title('Citra Ber-noise (Salt & Pepper)', 'FontWeight', 'bold');

subplot(1, 4, 3);
if ndims(out3x3) == 3, imshow(out3x3); else, imshow(out3x3, []); end
title('Median Filter Manual 3x3', 'FontWeight', 'bold');

subplot(1, 4, 4);
if ndims(out5x5) == 3, imshow(out5x5); else, imshow(out5x5, []); end
title('Median Filter Manual 5x5', 'FontWeight', 'bold');

fprintf('Pengujian selesai dengan sukses.\n');
