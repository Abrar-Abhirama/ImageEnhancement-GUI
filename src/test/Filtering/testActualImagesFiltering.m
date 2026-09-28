% testActualImagesFiltering.m - Pengujian Filtering pada Citra Tugas Asli
clear; clc; close all;

scriptDir = fileparts(mfilename('fullpath'));
testDir = fileparts(scriptDir);
srcDir = fileparts(testDir);
projectRoot = fileparts(srcDir);
addpath(genpath(projectRoot));

fprintf('====================================================================\n');
fprintf('     PENGUJIAN IMAGE FILTERING PADA CITRA TUGAS (test_images)\n');
fprintf('====================================================================\n\n');

testPath = fullfile(projectRoot, 'test_images');
if ~exist(testPath, 'dir')
    error('Folder test_images tidak ditemukan pada: %s', testPath);
end

% Daftar skenario uji representatif dari test_images
% Format: {Folder, NamaFile, RekomendasiFilter, Parameter, Rasionalisasi}
testCases = {
    'Kasus 1', 'image_01.png', 'gaussian', {'size', 5, 'sigma', 1.0}, 'Pereduksian derau halus (smoothing) dengan Gaussian';
    'Kasus 2', 'image_01.png', 'median',   {'size', 3},               'Pembersihan derau impuls / bintik dengan Median 3x3';
    'Kasus 2', 'image_02.png', 'median',   {'size', 5},               'Pembersihan derau impuls lebih rapat dengan Median 5x5';
    'Kasus 3', 'image_01.png', 'sharpen',  {'variant', '8'},          'Penajaman kontras detail dan tepi dengan Sharpening';
    'Kasus 4', 'image_01.png', 'sobel',    {},                        'Ekstraksi tepi struktur objek dengan Sobel Edge Detection';
    'Histogram Citra', 'image_01.png', 'mean', {'size', 3},           'Penghalusan seragam dengan Box Mean 3x3';
};

bins = 0:255;
numCases = size(testCases, 1);
resultsTable = cell(numCases, 6);

for k = 1:numCases
    subFolder  = testCases{k, 1};
    fileName   = testCases{k, 2};
    filterType = testCases{k, 3};
    filterArgs = testCases{k, 4};
    rationale  = testCases{k, 5};

    fullFilePath = fullfile(testPath, subFolder, fileName);
    if ~exist(fullFilePath, 'file')
        % Fallback cari sembarang file png di subFolder jika nama spesifik tidak cocok
        fallbackFiles = dir(fullfile(testPath, subFolder, '*.png'));
        if ~isempty(fallbackFiles)
            fullFilePath = fullfile(fallbackFiles(1).folder, fallbackFiles(1).name);
            fileName = fallbackFiles(1).name;
        else
            continue;
        end
    end

    img = imread(fullFilePath);
    isRGB = (ndims(img) == 3 && size(img, 3) == 3);

    % 1. Analisis statistik citra input menggunakan computeImageStats
    statsBefore = computeImageStats(img);

    % 2 & 3. Jalankan filtering yang relevan via applyFilter
    [outImg, filterInfo] = applyFilter(img, filterType, filterArgs{:});

    % 4. Analisis statistik citra output
    statsAfter = computeImageStats(outImg);

    % 5. Hitung histogram input & output menggunakan fungsi histogram custom
    if isRGB
        [hInR, hInG, hInB] = computeHistogram(img);
        [hOutR, hOutG, hOutB] = computeHistogram(outImg);
    else
        [hIn, ~] = computeHistogram(img);
        [hOut, ~] = computeHistogram(outImg);
    end

    % 6. Evaluasi numerik perubahan
    deltaMean = statsAfter.mean - statsBefore.mean;
    deltaStd  = statsAfter.std - statsBefore.std;
    deltaEnt  = statsAfter.entropy - statsBefore.entropy;
    diffImg   = abs(double(outImg) - double(img));
    meanDiff  = mean(diffImg(:));

    % Cetak laporan ke Command Window
    fprintf('[KASUS %d] %s / %s\n', k, subFolder, fileName);
    fprintf('  Rasionalisasi : %s\n', rationale);
    fprintf('  Metode Filter : %s\n', upper(filterType));
    fprintf('  %-15s %12s %12s %12s\n', 'Metrik', 'Sebelum', 'Sesudah', 'Perubahan');
    fprintf('  %s\n', repmat('-', 1, 45));
    fprintf('  %-15s %12.2f %12.2f %+12.2f\n', 'Mean', statsBefore.mean, statsAfter.mean, deltaMean);
    fprintf('  %-15s %12.2f %12.2f %+12.2f\n', 'Std Dev', statsBefore.std, statsAfter.std, deltaStd);
    fprintf('  %-15s %12.2f %12.2f %+12.2f\n', 'Entropy', statsBefore.entropy, statsAfter.entropy, deltaEnt);
    fprintf('  Rata-rata perubahan piksel (|Out - In|): %.2f level\n\n', meanDiff);

    % 7. Visualisasi (2x3 Subplot: Citra Asli, Citra Hasil, Residual/Diff, Hist In, Hist Out)
    fig = figure('Name', sprintf('[%d] %s - %s (%s)', k, subFolder, fileName, filterType), ...
        'Position', [40 + (k-1)*25, 40 + (k-1)*25, 1150, 600]);

    % Subplot 1: Citra Input
    subplot(2, 3, 1);
    if isRGB, imshow(img); else, imshow(img, []); end
    title(sprintf('Input: %s\nMean=%.1f, Std=%.1f', fileName, statsBefore.mean, statsBefore.std), 'FontSize', 10);

    % Subplot 2: Citra Output
    subplot(2, 3, 2);
    if isRGB, imshow(outImg); else, imshow(outImg, []); end
    title(sprintf('Hasil: %s\nMean=%.1f, Std=%.1f', upper(filterType), statsAfter.mean, statsAfter.std), 'FontSize', 10, 'FontWeight', 'bold');

    % Subplot 3: Peta Perbedaan / Komponen yang Difilter (|Out - In|)
    subplot(2, 3, 3);
    imshow(uint8(min(255, diffImg * 3)), []);
    title(sprintf('Perubahan (|Out - In| x3)\nMeanDiff = %.2f', meanDiff), 'FontSize', 10);

    % Subplot 4: Histogram Input
    subplot(2, 3, 4);
    if isRGB
        bar(bins, hInR, 'r', 'FaceAlpha', 0.4, 'EdgeColor', 'none'); hold on;
        bar(bins, hInG, 'g', 'FaceAlpha', 0.4, 'EdgeColor', 'none');
        bar(bins, hInB, 'b', 'FaceAlpha', 0.4, 'EdgeColor', 'none'); hold off;
        legend('R', 'G', 'B', 'Location', 'northwest');
    else
        bar(bins, hIn, 'FaceColor', [0.3 0.3 0.3], 'EdgeColor', 'none');
    end
    xlim([0 255]); grid on;
    xlabel('Intensitas'); ylabel('Frekuensi');
    title('Histogram Input', 'FontSize', 9);

    % Subplot 5: Histogram Output
    subplot(2, 3, 5);
    if isRGB
        bar(bins, hOutR, 'r', 'FaceAlpha', 0.4, 'EdgeColor', 'none'); hold on;
        bar(bins, hOutG, 'g', 'FaceAlpha', 0.4, 'EdgeColor', 'none');
        bar(bins, hOutB, 'b', 'FaceAlpha', 0.4, 'EdgeColor', 'none'); hold off;
        legend('R', 'G', 'B', 'Location', 'northwest');
    else
        bar(bins, hOut, 'FaceColor', [0.2 0.4 0.8], 'EdgeColor', 'none');
    end
    xlim([0 255]); grid on;
    xlabel('Intensitas'); ylabel('Frekuensi');
    title(sprintf('Histogram Output (%s)', filterType), 'FontSize', 9);

    % Subplot 6: Teks Ringkasan Analisis
    subplot(2, 3, 6);
    axis off;
    summaryText = {
        sprintf('\\bfKasus:\\rm %s / %s', subFolder, fileName);
        sprintf('\\bfFilter:\\rm %s', upper(filterType));
        sprintf('\\bfTujuan:\\rm %s', rationale);
        '';
        '\\bfPengaruh Filter:';
        sprintf('  \\bullet Mean: %.2f \\rightarrow %.2f (\\Delta: %+.2f)', statsBefore.mean, statsAfter.mean, deltaMean);
        sprintf('  \\bullet Std Dev: %.2f \\rightarrow %.2f (\\Delta: %+.2f)', statsBefore.std, statsAfter.std, deltaStd);
        sprintf('  \\bullet Entropi: %.2f \\rightarrow %.2f (\\Delta: %+.2f)', statsBefore.entropy, statsAfter.entropy, deltaEnt);
        sprintf('  \\bullet Rata-rata Modifikasi: %.2f level', meanDiff);
    };
    text(0.05, 0.5, summaryText, 'FontSize', 10, 'Interpreter', 'tex');
end

fprintf('Pengujian seluruh citra tugas selesai. Seluruh jendela visualisasi telah ditampilkan.\n');
