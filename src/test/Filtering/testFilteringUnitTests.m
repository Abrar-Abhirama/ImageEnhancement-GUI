% testFilteringUnitTests.m - Unit Test Image Filtering Manual
clear; clc; close all;

scriptDir = fileparts(mfilename('fullpath'));
testDir = fileparts(scriptDir);
srcDir = fileparts(testDir);
projectRoot = fileparts(srcDir);
addpath(genpath(projectRoot));

fprintf('=====================================================\n');
fprintf('       UNIT TEST MANUAL IMAGE FILTERING\n');
fprintf('=====================================================\n\n');

totalTests = 0;
passedTests = 0;

%% -------------------------------------------------------------------------
%% 1. LINEAR FILTERING: MEAN FILTER 3x3 PADA MATRIKS KECIL
%% -------------------------------------------------------------------------
totalTests = totalTests + 1;
fprintf('[TEST %d] Linear Filtering: Mean Filter 3x3 (Verifikasi Numerik)\n', totalTests);

% Matriks uji manual 5x5
imgTestLinear = [
    10, 20, 30, 40, 50;
    15, 25, 35, 45, 55;
    20, 30, 40, 50, 60;
    25, 35, 45, 55, 65;
    30, 40, 50, 60, 70
];

% Neighborhood 3x3 di sekitar posisi tengah (3, 3):
% [25 35 45; 30 40 50; 35 45 55] -> sum = 360 -> mean = 360 / 9 = 40.0
expectedMean_3_3 = 40.0;

outMean = applyFilter(imgTestLinear, 'mean', 'size', 3, 'padding', 'replicate');
actualMean_3_3 = outMean(3, 3);

fprintf('  Posisi (3,3): Ekspektasi = %.2f | Aktual = %.2f\n', expectedMean_3_3, actualMean_3_3);
assert(abs(double(actualMean_3_3) - expectedMean_3_3) < 1e-10, 'Mean filter 3x3 gagal.');
fprintf('  -> PASS: Mean filter 3x3 terbukti akurat secara numerik.\n\n');
passedTests = passedTests + 1;

%% -------------------------------------------------------------------------
%% 2. LINEAR FILTERING: SHARPENING & EDGE DETECTION (MATRIKS MANUAL)
%% -------------------------------------------------------------------------
totalTests = totalTests + 1;
fprintf('[TEST %d] Linear Filtering: Sharpening (Verifikasi Nilai Manual)\n', totalTests);

% Matriks dengan transisi intensitas di tengah
imgStep = [
    20, 20, 20;
    20, 50, 20;
    20, 20, 20
];

% Sharpening kernel (4-neighbor): [0 -1 0; -1 5 -1; 0 -1 0]
% Pada posisi (2,2): 5*50 - 4*20 = 250 - 80 = 170
expectedSharp = 170;
outSharp = applyFilter(imgStep, 'sharpen', 'variant', '4', 'padding', 'replicate');
actualSharp = outSharp(2, 2);

fprintf('  Sharpen center (2,2): Ekspektasi = %d | Aktual = %d\n', expectedSharp, actualSharp);
assert(actualSharp == expectedSharp, 'Sharpening filter gagal.');
fprintf('  -> PASS: Sharpening kernel meningkatkan kontras sesuai perhitungan matematis.\n\n');
passedTests = passedTests + 1;

totalTests = totalTests + 1;
fprintf('[TEST %d] Linear Filtering: Edge Detection Sobel & Laplacian\n', totalTests);

% Citra biner step edge vertikal: kolom 1-2 bernilai 10, kolom 3-5 bernilai 100
imgEdge = [
    10, 10, 100, 100, 100;
    10, 10, 100, 100, 100;
    10, 10, 100, 100, 100;
    10, 10, 100, 100, 100;
    10, 10, 100, 100, 100
];

% Flat region (kolom 1 dan kolom 5) harus memiliki respons tepi mendekati 0
outSobel = applyFilter(imgEdge, 'sobel', 'padding', 'replicate');
outLaplace = applyFilter(imgEdge, 'laplacian', 'variant', '4', 'padding', 'replicate');

flatResponseSobel = outSobel(3, 1);
edgeResponseSobel = outSobel(3, 2);
flatResponseLaplace = outLaplace(3, 1);
edgeResponseLaplace = outLaplace(3, 2);

fprintf('  Sobel: Flat region = %d | Edge region = %d\n', flatResponseSobel, edgeResponseSobel);
fprintf('  Laplacian: Flat region = %d | Edge region = %d\n', flatResponseLaplace, edgeResponseLaplace);
assert(flatResponseSobel == 0, 'Sobel pada area datar harus bernilai 0.');
assert(edgeResponseSobel > 0, 'Sobel pada tepi harus menghasilkan respons kuat.');
assert(flatResponseLaplace == 0, 'Laplacian pada area datar harus bernilai 0.');
assert(edgeResponseLaplace > 0, 'Laplacian pada tepi harus menghasilkan respons.');
fprintf('  -> PASS: Edge detection mendeteksi transisi tepi dan bernilai 0 di area datar.\n\n');
passedTests = passedTests + 1;

%% -------------------------------------------------------------------------
%% 3. VERIFIKASI PRESERVASI DIMENSI CITRA
%% -------------------------------------------------------------------------
totalTests = totalTests + 1;
fprintf('[TEST %d] Preservasi Dimensi Citra (Grayscale & RGB)\n', totalTests);

sizesToTest = {[15, 23], [40, 40], [25, 30, 3]};
dimPass = true;

for s = 1:length(sizesToTest)
    targetSize = sizesToTest{s};
    dummy = uint8(randi([0, 255], targetSize));
    
    outLin = applyFilter(dummy, 'gaussian', 'size', 5);
    outMed = applyFilter(dummy, 'median', 'size', 3);
    
    if ~isequal(size(outLin), targetSize) || ~isequal(size(outMed), targetSize)
        dimPass = false;
        break;
    end
end

assert(dimPass, 'Dimensi citra output tidak cocok dengan input.');
fprintf('  -> PASS: Dimensi citra 2D dan 3D RGB selalu dipertahankan identik.\n\n');
passedTests = passedTests + 1;

%% -------------------------------------------------------------------------
%% 4. MEDIAN FILTERING: ELIMINASI OUTLIER / IMPULSE NOISE
%% -------------------------------------------------------------------------
totalTests = totalTests + 1;
fprintf('[TEST %d] Median Filtering: Eliminasi Outlier Tunggal (Salt Noise)\n', totalTests);

% Matriks homogen 5x5 bernilai 15 dengan satu outlier ekstrem bernilai 255 di tengah
imgOutlier = 15 * ones(5, 5, 'uint8');
imgOutlier(3, 3) = 255; % Noise outlier

% Window 3x3 di sekitar (3,3): delapan buah 15 dan satu buah 255
% Sorted: [15, 15, 15, 15, 15, 15, 15, 15, 255] -> median index ke-5 adalah 15
outlierFiltered3x3 = applyFilter(imgOutlier, 'median', 'size', 3);
valCenter = outlierFiltered3x3(3, 3);

fprintf('  Nilai sebelum filter pada (3,3): %d\n', imgOutlier(3, 3));
fprintf('  Nilai sesudah filter pada (3,3): %d (Ekspektasi: 15)\n', valCenter);
assert(valCenter == 15, 'Median filter gagal mengeliminasi outlier tunggal.');
fprintf('  -> PASS: Outlier berhasil dihilangkan sepenuhnya ke nilai latar (15).\n\n');
passedTests = passedTests + 1;

%% -------------------------------------------------------------------------
%% 5. MEDIAN FILTERING: PENGUJIAN BERBAGAI UKURAN WINDOW GANJIL (3x3 vs 5x5)
%% -------------------------------------------------------------------------
totalTests = totalTests + 1;
fprintf('[TEST %d] Median Filtering: Variasi Ukuran Window Ganjil (3x3 & 5x5)\n', totalTests);

% Matriks dengan kluster derau 2x2 pada background bernilai 30
imgCluster = 30 * ones(7, 7, 'uint8');
imgCluster(3:4, 3:4) = 240; % Kluster 4 piksel noise

% Window 3x3 pada (3,3): mencakup 4 piksel noise (240) dan 5 piksel background (30)
% Sorted 9 elemen: [30, 30, 30, 30, 30, 240, 240, 240, 240] -> Median (ke-5) tetap 30!
outCluster3 = applyFilter(imgCluster, 'median', 'size', 3);
valCluster3 = outCluster3(3, 3);

% Window 5x5 pada (3,3): mencakup 4 piksel noise (240) dan 21 piksel background (30)
% Sorted 25 elemen: 21 buah 30, 4 buah 240 -> Median (ke-13) tetap 30!
outCluster5 = applyFilter(imgCluster, 'median', 'size', 5);
valCluster5 = outCluster5(3, 3);

fprintf('  Kluster 2x2 Noise (nilai 240):\n');
fprintf('    Window 3x3 pada (3,3) = %d (Ekspektasi: 30)\n', valCluster3);
fprintf('    Window 5x5 pada (3,3) = %d (Ekspektasi: 30)\n', valCluster5);

assert(valCluster3 == 30, 'Window 3x3 gagal mengatasi kluster noise.');
assert(valCluster5 == 30, 'Window 5x5 gagal mengatasi kluster noise.');
fprintf('  -> PASS: Pengujian berbagai ukuran window ganjil berhasil dengan benar.\n\n');
passedTests = passedTests + 1;

%% -------------------------------------------------------------------------
%% RINGKASAN HASIL
%% -------------------------------------------------------------------------
fprintf('=====================================================\n');
fprintf('HASIL UNIT TEST: %d / %d PASSED\n', passedTests, totalTests);
fprintf('=====================================================\n');
