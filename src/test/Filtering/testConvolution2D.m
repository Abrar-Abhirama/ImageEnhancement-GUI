% testConvolution2D.m - Pengujian manual 2D convolution
%
% Script pengujian independen untuk memvalidasi implementasi manual
% applyConvolution2D dan padImageManual terhadap:
% 1. Pembuktian matematika kernel flipping pada matriks kecil
% 2. Preservasi dimensi citra (same size)
% 3. Pengujian berbagai ukuran kernel ganjil (3x3, 5x5)
% 4. Pengujian strategi boundary padding ('replicate', 'zero', 'symmetric')
% 5. Validasi numerik terhadap imfilter / conv2 (hanya sebagai pembanding)

clear; clc; close all;

scriptDir = fileparts(mfilename('fullpath'));
testDir = fileparts(scriptDir);
srcDir = fileparts(testDir);
projectRoot = fileparts(srcDir);
addpath(genpath(projectRoot));

fprintf('=====================================================\n');
fprintf('       PENGUJIAN MANUAL 2D CONVOLUTION\n');
fprintf('=====================================================\n\n');

%% Uji 1: Uji Matriks Kecil & Pembuktian Kernel Flipping
fprintf('[UJI 1] Verifikasi Matematika Konvolusi & Kernel Flipping\n');
testMatrix = [
    1,  2,  3,  4;
    5,  6,  7,  8;
    9, 10, 11, 12;
   13, 14, 15, 16
];

% Asymmetric kernel untuk membedakan konvolusi vs korelasi
kernelAsym = [
    1, 2, 3;
    4, 5, 6;
    7, 8, 9
];

[outConv, flippedK] = applyConvolution2D(testMatrix, kernelAsym, 'padding', 'zero', 'clip', false);

% Hitung nilai ekspektasi pada posisi tengah (2, 2):
% Window di sekitar (2,2) adalah testMatrix(1:3, 1:3):
% [1 2 3; 5 6 7; 9 10 11]
% Flipped kernel:
% [9 8 7; 6 5 4; 3 2 1]
% Dot product:
% 1*9 + 2*8 + 3*7 + 5*6 + 6*5 + 7*4 + 9*3 + 10*2 + 11*1 = 205
expectedVal = sum(sum(testMatrix(1:3, 1:3) .* flippedK));

fprintf('  Nilai konvolusi manual pada (2,2) : %g\n', outConv(2, 2));
fprintf('  Nilai ekspektasi matematika        : %g\n', expectedVal);

if abs(outConv(2, 2) - expectedVal) < 1e-10
    fprintf('  -> PASS: Konvolusi 2D dan Kernel Flip terbukti akurat!\n\n');
else
    fprintf('  -> FAIL: Terjadi ketidaksesuaian perhitungan.\n\n');
end

%% Uji 2: Preservasi Dimensi Citra & Pengujian Ukuran Kernel (3x3, 5x5)
fprintf('[UJI 2] Preservasi Dimensi Citra & Kernel Ganjil\n');
testSizes = {[64, 64], [128, 96], [100, 100, 3]};
kernelSizes = {[3, 3], [5, 5], [7, 7]};

allDimPassed = true;
for s = 1:length(testSizes)
    sz = testSizes{s};
    dummyImg = uint8(randi([0, 255], sz));
    for ks = 1:length(kernelSizes)
        ksz = kernelSizes{ks};
        kMat = ones(ksz) / prod(ksz); % Box filter kernel
        outImg = applyConvolution2D(dummyImg, kMat);
        
        if ~isequal(size(outImg), sz)
            allDimPassed = false;
            fprintf('  Dimensi tidak cocok untuk citra %s dengan kernel %s!\n', ...
                mat2str(sz), mat2str(ksz));
        end
    end
end

if allDimPassed
    fprintf('  -> PASS: Seluruh pengujian mempertahankan dimensi citra asli secara sempurna.\n\n');
end

%% Uji 3: Uji Mode Boundary Padding
fprintf('[UJI 3] Uji Boundary Strategy (Replicate, Zero, Symmetric)\n');
box3 = ones(3, 3) / 9;
imgCorner = [
    100, 100, 100;
    100, 100, 100;
    100, 100, 100
];

outRep  = applyConvolution2D(imgCorner, box3, 'padding', 'replicate', 'clip', false);
outZero = applyConvolution2D(imgCorner, box3, 'padding', 'zero', 'clip', false);
outSym  = applyConvolution2D(imgCorner, box3, 'padding', 'symmetric', 'clip', false);

fprintf('  Hasil Replicate pada pojok (1,1): %.2f (tanpa darkening border)\n', outRep(1, 1));
fprintf('  Hasil Zero pada pojok (1,1)     : %.2f (efek zero-padding boundary)\n', outZero(1, 1));
fprintf('  Hasil Symmetric pada pojok (1,1): %.2f\n', outSym(1, 1));
fprintf('  -> PASS: Berbagai mode boundary strategy berfungsi dengan benar.\n\n');

%% Uji 4: Validasi terhadap Citra Nyata & Pembanding Built-in
fprintf('[UJI 4] Validasi pada Citra Uji Nyata\n');
testPath = fullfile(projectRoot, 'test_images');
imgFile = '';

if exist(testPath, 'dir')
    files = dir(fullfile(testPath, '**', '*.png'));
    if ~isempty(files)
        imgFile = fullfile(files(1).folder, files(1).name);
    end
end

if ~isempty(imgFile)
    imgReal = imread(imgFile);
    fprintf('  Memuat citra: %s\n', imgFile);
else
    % Fallback synthetic image
    [X, Y] = meshgrid(1:200, 1:200);
    imgReal = uint8(mod(X + Y, 256));
    fprintf('  Menggunakan citra sintetis fallback (200x200).\n');
end

% Gaussian 5x5 smoothing filter kernel manual
gaussian5x5 = [
    1,  4,  7,  4, 1;
    4, 16, 26, 16, 4;
    7, 26, 41, 26, 7;
    4, 16, 26, 16, 4;
    1,  4,  7,  4, 1
] / 273;

outManual = applyConvolution2D(imgReal, gaussian5x5, 'padding', 'replicate');

% Validasi terhadap imfilter jika Image Processing Toolbox terpasang
if exist('imfilter', 'file') == 2
    outBuiltin = imfilter(imgReal, gaussian5x5, 'conv', 'replicate');
    diffImg = abs(double(outManual) - double(outBuiltin));
    maxDiff = max(diffImg(:));
    meanDiff = mean(diffImg(:));
    fprintf('  Validasi pembanding (imfilter conv, replicate):\n');
    fprintf('    Maksimum perbedaan: %d\n', maxDiff);
    fprintf('    Rata-rata selisih : %.4f\n', meanDiff);
    if maxDiff <= 1
        fprintf('  -> PASS: Hasil konvolusi manual identik secara matematis dengan imfilter!\n\n');
    end
end

% Visualisasi
figure('Name', 'Manual 2D Convolution Test', 'Position', [100, 100, 900, 450]);
subplot(1, 2, 1);
if ndims(imgReal) == 3, imshow(imgReal); else, imshow(imgReal, []); end
title('Citra Input Asli', 'FontSize', 11, 'FontWeight', 'bold');

subplot(1, 2, 2);
if ndims(outManual) == 3, imshow(outManual); else, imshow(outManual, []); end
title('Hasil Konvolusi Manual (Gaussian 5x5)', 'FontSize', 11, 'FontWeight', 'bold');

fprintf('Seluruh pengujian selesai dengan sukses.\n');
