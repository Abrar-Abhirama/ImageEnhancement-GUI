scriptDir = fileparts(mfilename('fullpath'));
testDir = fileparts(scriptDir);
srcDir = fileparts(testDir);
projectRoot = fileparts(srcDir);

fprintf('Project root: %s\n', projectRoot);
addpath(genpath(projectRoot));

fprintf('=== PENGUJIAN HISTOGRAM EQUALIZATION ===\n\n');

testPath = fullfile(projectRoot, 'test_images');
if exist(testPath, 'dir')
    imgFiles = dir(fullfile(testPath, '**', '*.png'));
    imgFiles = [imgFiles; dir(fullfile(testPath, '**', '*.jpg'))];
    if ~isempty(imgFiles)
        fprintf('Load: %s\n', imgFiles(1).name);
        img = imread(fullfile(imgFiles(1).folder, imgFiles(1).name));
    else
        img = createTestImage();
    end
else
    img = createTestImage();
end

isRGB = (size(img, 3) == 3);
fprintf('Ukuran: %dx%d, Tipe: %s\n\n', size(img,1), size(img,2), ternary(isRGB,'RGB','Grayscale'));

fprintf('--- Statistik Sebelum Equalization ---\n');
if isRGB
    rChannel = img(:, :, 1);
    gChannel = img(:, :, 2);
    bChannel = img(:, :, 3);
    fprintf('R: Min=%d, Max=%d, Mean=%.1f\n', min(rChannel(:)), max(rChannel(:)), mean(double(rChannel(:))));
    fprintf('G: Min=%d, Max=%d, Mean=%.1f\n', min(gChannel(:)), max(gChannel(:)), mean(double(gChannel(:))));
    fprintf('B: Min=%d, Max=%d, Mean=%.1f\n', min(bChannel(:)), max(bChannel(:)), mean(double(bChannel(:))));
else
    fprintf('Min=%d, Max=%d, Mean=%.1f\n', min(img(:)), max(img(:)), mean(double(img(:))));
end

modes = {
    'global',  'Global (setiap channel independen)';
    'hsv',     'HSV (equalize V channel saja)';
    'ycbcr',   'YCbCr (equalize Y channel saja)';
};

numModes = size(modes, 1);

fig1 = figure('Name', 'Histogram Equalization - Results');
fig2 = figure('Name', 'Histogram Equalization - Histograms Before');
fig3 = figure('Name', 'Histogram Equalization - Histograms After');

figure(fig2);
if isRGB
    [cR, cG, cB] = computeHistogram(img);
    subplot(1, 2, 1);
    bar(0:255, cR, 'r', 'FaceAlpha', 0.5); hold on;
    bar(0:255, cG, 'g', 'FaceAlpha', 0.5);
    bar(0:255, cB, 'b', 'FaceAlpha', 0.5); hold off;
    legend('R', 'G', 'B');
    title('Histogram Sebelum - RGB');
else
    [c] = computeHistogram(img);
    bar(0:255, c, 'k', 'FaceAlpha', 0.5);
    title('Histogram Sebelum - Grayscale');
end
xlim([0 255]); grid on; ylabel('Frekuensi');

subplot(1, 2, 2);
imshow(img); title('Citra Sebelum Equalization');

fprintf('\n--- Hasil Equalization ---\n');
for i = 1:numModes
    mode = modes{i, 1};
    desc = modes{i, 2};

    fprintf('[%d/%d] Mode: %s\n', i, numModes, desc);

    % Apply equalization
    result = histogramEqualization(img, 'mode', mode);

    if isRGB
        rCh = result(:, :, 1);
        gCh = result(:, :, 2);
        bCh = result(:, :, 3);
        rMean = mean(double(rCh(:)));
        gMean = mean(double(gCh(:)));
        bMean = mean(double(bCh(:)));
        fprintf('  Setelah: R=%.1f, G=%.1f, B=%.1f, All=%.1f\n', rMean, gMean, bMean, mean(double(result(:))));
    else
        fprintf('  Setelah: Mean=%.1f\n', mean(double(result(:))));
    end

    figure(fig1);
    subplot(numModes + 1, 3, (i-1)*3 + 1);
    imshow(img); title('Original');
    xlabel('Sebelum');

    subplot(numModes + 1, 3, (i-1)*3 + 2);
    imshow(result); title(sprintf('HE: %s', mode));
    xlabel(desc);

    figure(fig1);
    subplot(numModes + 1, 3, (i-1)*3 + 3);
    if isRGB
        [cR, cG, cB] = computeHistogram(img);
        bar(0:255, cR, 'r', 'FaceAlpha', 0.3); hold on;
        bar(0:255, cG, 'g', 'FaceAlpha', 0.3);
        bar(0:255, cB, 'b', 'FaceAlpha', 0.3); hold off;
    else
        [c] = computeHistogram(img);
        bar(0:255, c, 'k', 'FaceAlpha', 0.3);
    end
    title('Histogram Sebelum');
    xlim([0 255]);

    figure(fig3);
    subplot(numModes + 1, 3, (i-1)*3 + 1);
    if isRGB
        [cR, cG, cB] = computeHistogram(result);
        bar(0:255, cR, 'r', 'FaceAlpha', 0.5); hold on;
        bar(0:255, cG, 'g', 'FaceAlpha', 0.5);
        bar(0:255, cB, 'b', 'FaceAlpha', 0.5); hold off;
        legend('R', 'G', 'B');
        title(sprintf('Histogram Sesudah - %s', mode));
    else
        [c] = computeHistogram(result);
        bar(0:255, c, 'k', 'FaceAlpha', 0.5);
        title('Histogram Sesudah - Grayscale');
    end
    xlim([0 255]); grid on; ylabel('Frekuensi');

    subplot(numModes + 1, 3, (i-1)*3 + 2);
    imshow(result); title(sprintf('Hasil: %s', mode));

    subplot(numModes + 1, 3, (i-1)*3 + 3);
    if isRGB
        [cR, cG, cB] = computeHistogram(result);
        plot(0:255, cR, 'r', 'LineWidth', 1); hold on;
        plot(0:255, cG, 'g', 'LineWidth', 1);
        plot(0:255, cB, 'b', 'LineWidth', 1); hold off;
        title('CDF/Histogram Lines');
    else
        [c] = computeHistogram(result);
        plot(0:255, c, 'k', 'LineWidth', 1);
        title('Histogram Line');
    end
    xlim([0 255]); grid on;
end

figure(fig1);
subplot(numModes + 1, 3, numModes*3 + 1:numModes*3 + 3);
text(0.5, 0.7, 'HISTOGRAM EQUALIZATION COMPARISON', ...
    'FontSize', 14, 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'center');
text(0.5, 0.4, sprintf('Image: %dx%d', size(img,1), size(img,2)), ...
    'FontSize', 10, 'HorizontalAlignment', 'center');
text(0.5, 0.15, 'Baris: Original | HE Global | HE HSV | HE YCbCr', ...
    'FontSize', 9, 'HorizontalAlignment', 'center');
axis off;

figure(fig2);
annotation('textbox', [0.5 0.95 0.3 0.04], ...
    'String', 'Sebelum Histogram Equalization', ...
    'FontSize', 12, 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'center', 'EdgeColor', 'none');

figure(fig3);
annotation('textbox', [0.5 0.95 0.3 0.04], ...
    'String', 'Sesudah Histogram Equalization', ...
    'FontSize', 12, 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'center', 'EdgeColor', 'none');

fprintf('\n--- Uji dengan Grayscale ---\n');
imgGray = rgb2grayLocal(img);
eqGray = histogramEqualization(imgGray);
fprintf('Grayscale: Min=%d->%d, Max=%d->%d\n', ...
    min(imgGray(:)), min(eqGray(:)), max(imgGray(:)), max(eqGray(:)));

fprintf('\n--- Perbandingan dengan histeq (pembanding) ---\n');
try
    builtin = histeq(imgGray);
    diff = double(eqGray) - double(builtin);
    fprintf('Perbedaan max dengan histeq: %d\n', max(abs(diff(:))));
    fprintf('Perbedaan mean dengan histeq: %.2f\n', mean(abs(diff(:))));
catch
    fprintf('histeq tidak tersedia untuk pembanding\n');
end

fprintf('\n=== SELESAI ===\n');
fprintf('3 figure window terbuka:\n');
fprintf('  1. Results - Perbandingan visual\n');
fprintf('  2. Histograms Before\n');
fprintf('  3. Histograms After\n');


function out = ternary(cond, t, f)
    if cond, out = t; else, out = f; end
end

function gray = rgb2grayLocal(rgb)
    if size(rgb, 3) == 3
        gray = 0.2989 * double(rgb(:, :, 1)) + ...
               0.5870 * double(rgb(:, :, 2)) + ...
               0.1140 * double(rgb(:, :, 3));
    else
        gray = double(rgb);
    end
    gray = uint8(gray);
end

function img = createTestImage()
    [x, y] = meshgrid(1:256, 1:256);
    r = uint8(x); g = uint8(y); b = uint8(256-x);
    img = cat(3, r, g, b);
    img(1:64, :, :) = img(1:64, :, :) * 0.3;
    img = min(255, max(0, img));
end