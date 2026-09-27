scriptDir = fileparts(mfilename('fullpath'));
testDir = fileparts(scriptDir);
srcDir = fileparts(testDir);
projectRoot = fileparts(srcDir);
addpath(genpath(projectRoot));

testPath = fullfile(projectRoot, 'test_images');

testPairs = {
    fullfile('Histogram Citra', 'image_01.png'), fullfile('Histogram Citra', 'image_02.png'), 'Histogram Citra (01 -> 02)';
    fullfile('Histogram Citra', 'image_03.png'), fullfile('Histogram Citra', 'image_04.png'), 'Histogram Citra (03 -> 04)';
    fullfile('Kasus 1', 'image_01.png'),         fullfile('Kasus 1', 'image_02.png'),         'Kasus 1 (01 -> 02)';
};

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

fprintf('Konfigurasi: Custom (256-level) vs imhistmatch(input, ref, 256)\n\n');

bins = 0:255;

for k = 1:size(validPairs, 1)
    pathIn  = validPairs{k, 1};
    pathRef = validPairs{k, 2};
    tag     = validPairs{k, 3};

    rawIn  = imread(pathIn);
    rawRef = imread(pathRef);

    if size(rawIn, 3) == 3
        inImg = rgb2grayLocal(rawIn);
    else
        inImg = rawIn;
    end

    if size(rawRef, 3) == 3
        refImg = rgb2grayLocal(rawRef);
    else
        refImg = rawRef;
    end

    % Custom Implementation (256-level discrete nearest-neighbor CDF mapping)
    outCustom = histogramMatching(inImg, refImg);

    % MATLAB imhistmatch with 256 bins explicitly (apples-to-apples)
    outBuiltin = imhistmatch(inImg, refImg, 256);

    % Histogram & CDF
    [hIn, ~]      = computeHistogram(inImg);
    [hRef, ~]     = computeHistogram(refImg);
    [hCustom, ~]  = computeHistogram(outCustom);
    [hBuiltin, ~] = computeHistogram(outBuiltin);

    [cdfIn, ~]      = computeCDF(inImg);
    [cdfRef, ~]     = computeCDF(refImg);
    [cdfCustom, ~]  = computeCDF(outCustom);
    [cdfBuiltin, ~] = computeCDF(outBuiltin);

    % Metrics
    meanIn      = mean(double(inImg(:)));
    meanRef     = mean(double(refImg(:)));
    meanCustom  = mean(double(outCustom(:)));
    meanBuiltin = mean(double(outBuiltin(:)));

    stdIn      = std(double(inImg(:)));
    stdRef     = std(double(refImg(:)));
    stdCustom  = std(double(outCustom(:)));
    stdBuiltin = std(double(outBuiltin(:)));

    distCustom  = sum(abs(cdfCustom - cdfRef));
    distBuiltin = sum(abs(cdfBuiltin - cdfRef));

    diffPixels  = abs(double(outCustom) - double(outBuiltin));
    meanDiff    = mean(diffPixels(:));
    maxDiff     = max(diffPixels(:));

    uniqueIn      = numel(unique(inImg(:)));
    uniqueRef     = numel(unique(refImg(:)));
    uniqueCustom  = numel(unique(outCustom(:)));
    uniqueBuiltin = numel(unique(outBuiltin(:)));

    % Numeric Report
    fprintf('[UJI %d] %s\n', k, tag);
    fprintf('  %-18s %8s %8s %10s %14s\n', 'Metrik', 'Input', 'Ref', 'Custom', 'imhistmatch256');
    fprintf('  %-18s %8.1f %8.1f %10.1f %14.1f\n', 'Mean',    meanIn, meanRef, meanCustom, meanBuiltin);
    fprintf('  %-18s %8.1f %8.1f %10.1f %14.1f\n', 'Std Dev', stdIn, stdRef, stdCustom, stdBuiltin);
    fprintf('  %-18s %8d %8d %10d %14d\n', 'Unique Levels', uniqueIn, uniqueRef, uniqueCustom, uniqueBuiltin);
    fprintf('  CDF dist ke Ref : Custom=%.3f | imhistmatch256=%.3f\n', distCustom, distBuiltin);
    fprintf('  Selisih Piksel  : Rata-rata=%.2f level | Maksimum=%d level\n\n', meanDiff, maxDiff);

    % Visual Comparison (2 rows x 4 cols)
    figure('Name', sprintf('[%d] Custom vs imhistmatch(256) - %s', k, tag), ...
        'Position', [30 + (k-1)*30, 30 + (k-1)*30, 1250, 620]);

    subplot(2, 4, 1); imshow(inImg);      title(sprintf('Input\n(unique=%d)', uniqueIn));
    subplot(2, 4, 2); imshow(refImg);     title(sprintf('Referensi\n(unique=%d)', uniqueRef));
    subplot(2, 4, 3); imshow(outCustom);  title(sprintf('Custom Output\n(unique=%d)', uniqueCustom));
    subplot(2, 4, 4); imshow(outBuiltin); title(sprintf('imhistmatch(256)\n(unique=%d)', uniqueBuiltin));

    subplot(2, 4, 5);
    bar(bins, hIn, 'FaceColor', [0.8 0.2 0.2], 'EdgeColor', 'none');
    xlim([0 255]); grid on; xlabel('Intensitas'); ylabel('Freq'); title('Hist Input');

    subplot(2, 4, 6);
    bar(bins, hRef, 'FaceColor', [0.2 0.7 0.2], 'EdgeColor', 'none');
    xlim([0 255]); grid on; xlabel('Intensitas'); ylabel('Freq'); title('Hist Referensi');

    subplot(2, 4, 7);
    bar(bins, hCustom, 'FaceColor', [0.2 0.3 0.9], 'EdgeColor', 'none');
    xlim([0 255]); grid on; xlabel('Intensitas'); ylabel('Freq'); title('Hist Custom');

    subplot(2, 4, 8);
    bar(bins, hBuiltin, 'FaceColor', [0.6 0.2 0.8], 'EdgeColor', 'none');
    xlim([0 255]); grid on; xlabel('Intensitas'); ylabel('Freq'); title('Hist imhistmatch(256)');
end

fprintf('Validasi selesai.\n');

function gray = rgb2grayLocal(rgb)
    gray = uint8(round(0.2989 * double(rgb(:,:,1)) + 0.5870 * double(rgb(:,:,2)) + 0.1140 * double(rgb(:,:,3))));
end
