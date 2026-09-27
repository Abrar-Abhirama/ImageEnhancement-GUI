scriptDir = fileparts(mfilename('fullpath'));
testDir = fileparts(scriptDir);
srcDir = fileparts(testDir);
projectRoot = fileparts(srcDir);
addpath(genpath(projectRoot));

testPath = fullfile(projectRoot, 'test_images');

% Daftar pasangan citra uji
testPairs = {
    fullfile('Histogram Citra', 'image_01.png'), fullfile('Histogram Citra', 'image_02.png'), 'Histogram Citra (01 -> 02)';
    fullfile('Histogram Citra', 'image_03.png'), fullfile('Histogram Citra', 'image_04.png'), 'Histogram Citra (03 -> 04)';
    fullfile('Kasus 1', 'image_01.png'),         fullfile('Kasus 1', 'image_02.png'),         'Kasus 1 (01 -> 02)';
};

% Fallback jika path spesifik tidak ditemukan
validPairs = {};
for i = 1:size(testPairs, 1)
    pIn  = fullfile(testPath, testPairs{i, 1});
    pRef = fullfile(testPath, testPairs{i, 2});
    if exist(pIn, 'file') && exist(pRef, 'file')
        validPairs(end+1, :) = {pIn, pRef, testPairs{i, 3}};
    end
end

if isempty(validPairs)
    allFiles = dir(fullfile(testPath, '**', '*.png'));
    if length(allFiles) >= 2
        for i = 1:2:min(6, length(allFiles)-1)
            validPairs(end+1, :) = { ...
                fullfile(allFiles(i).folder, allFiles(i).name), ...
                fullfile(allFiles(i+1).folder, allFiles(i+1).name), ...
                sprintf('Pasangan %d (%s -> %s)', round((i+1)/2), allFiles(i).name, allFiles(i+1).name) ...
            };
        end
    end
end

numTests = size(validPairs, 1);
fprintf('Menjalankan pengujian Histogram Matching pada %d pasangan citra...\n\n', numTests);

bins = 0:255;

for k = 1:numTests
    pathIn  = validPairs{k, 1};
    pathRef = validPairs{k, 2};
    tag     = validPairs{k, 3};

    imgInRaw  = imread(pathIn);
    imgRefRaw = imread(pathRef);

    % Gunakan grayscale untuk perbandingan histogram 1 dimensi
    if size(imgInRaw, 3) == 3
        imgIn = rgb2grayLocal(imgInRaw);
    else
        imgIn = imgInRaw;
    end

    if size(imgRefRaw, 3) == 3
        imgRef = rgb2grayLocal(imgRefRaw);
    else
        imgRef = imgRefRaw;
    end

    % 1. Eksekusi Histogram Matching
    [imgOut, info] = histogramMatching(imgIn, imgRef);

    % 2. Hitung histogram ketiga citra
    [hIn, ~]  = computeHistogram(imgIn);
    [hRef, ~] = computeHistogram(imgRef);
    [hOut, ~] = computeHistogram(imgOut);

    % 3. Evaluasi numerik jarak CDF
    [cdfIn, ~]  = computeCDF(imgIn);
    [cdfRef, ~] = computeCDF(imgRef);
    [cdfOut, ~] = computeCDF(imgOut);

    distBefore = sum(abs(cdfIn - cdfRef));
    distAfter  = sum(abs(cdfOut - cdfRef));
    pctReduction = ((distBefore - distAfter) / distBefore) * 100;

    fprintf('[UJI %d] %s\n', k, tag);
    fprintf('  Mean   : Input=%.1f | Ref=%.1f | Output=%.1f\n', ...
        mean(double(imgIn(:))), mean(double(imgRef(:))), mean(double(imgOut(:))));
    fprintf('  Std Dev: Input=%.1f | Ref=%.1f | Output=%.1f\n', ...
        std(double(imgIn(:))), std(double(imgRef(:))), std(double(imgOut(:))));
    fprintf('  Jarak CDF ke Ref: %.2f -> %.2f (Penurunan: %.1f%%)\n\n', ...
        distBefore, distAfter, pctReduction);

    % 4. Visualisasi (2x3 subplot: Citra & Histogram)
    fig = figure('Name', sprintf('Histogram Matching - %s', tag), 'Position', [50 + (k-1)*40, 50 + (k-1)*40, 1150, 650]);

    % Baris 1: Citra
    subplot(2, 3, 1); imshow(imgIn);  title(sprintf('Input (%s)', tag));
    subplot(2, 3, 2); imshow(imgRef); title('Referensi (Target)');
    subplot(2, 3, 3); imshow(imgOut); title('Output (Matched)');

    % Baris 2: Histogram
    subplot(2, 3, 4);
    bar(bins, hIn, 'FaceColor', [0.8 0.2 0.2], 'EdgeColor', 'none');
    xlim([0 255]); grid on;
    xlabel('Intensitas'); ylabel('Frekuensi'); title('Histogram Input');

    subplot(2, 3, 5);
    bar(bins, hRef, 'FaceColor', [0.2 0.7 0.2], 'EdgeColor', 'none');
    xlim([0 255]); grid on;
    xlabel('Intensitas'); ylabel('Frekuensi'); title('Histogram Referensi');

    subplot(2, 3, 6);
    bar(bins, hOut, 'FaceColor', [0.2 0.3 0.9], 'EdgeColor', 'none');
    xlim([0 255]); grid on;
    xlabel('Intensitas'); ylabel('Frekuensi'); title('Histogram Output');
end

fprintf('Pengujian citra selesai. Seluruh visualisasi telah ditampilkan.\n');

function gray = rgb2grayLocal(rgb)
    gray = uint8(round(0.2989 * double(rgb(:,:,1)) + 0.5870 * double(rgb(:,:,2)) + 0.1140 * double(rgb(:,:,3))));
end
