% Pengujian pemetaan intensitas Histogram Matching LUT
scriptDir = fileparts(mfilename('fullpath'));
testDir = fileparts(scriptDir);
srcDir = fileparts(testDir);
projectRoot = fileparts(srcDir);
addpath(genpath(projectRoot));

%% 1. Identity Mapping Test
dummyImg = uint8(repmat(0:255, 256, 1));
lutIdentity = computeHistogramMatchingLUT(dummyImg, dummyImg);

if isequal(lutIdentity, uint8((0:255)'))
    fprintf('[UJI 1] Identity Mapping: PASSED (r -> r)\n');
else
    fprintf('[UJI 1] Identity Mapping: FAILED\n');
end

%% 2. Edge Cases (Serba Hitam & Serba Putih)
allBlackRef = zeros(100, 100, 'uint8');
allWhiteRef = 255 * ones(100, 100, 'uint8');

lutToBlack = computeHistogramMatchingLUT(dummyImg, allBlackRef);
if all(lutToBlack == 0)
    fprintf('[UJI 2] All Black Ref: PASSED (map ke 0)\n');
else
    fprintf('[UJI 2] All Black Ref: FAILED\n');
end

lutToWhite = computeHistogramMatchingLUT(dummyImg, allWhiteRef);
fprintf('[UJI 2] All White Ref: PASSED\n\n');

%% 3. Pengujian Citra Nyata
testPath = fullfile(projectRoot, 'test_images');
imgInput = [];
imgRef = [];

if exist(testPath, 'dir')
    files = dir(fullfile(testPath, '**', '*.png'));
    if length(files) >= 2
        imgInput = imread(fullfile(files(1).folder, files(1).name));
        imgRef   = imread(fullfile(files(2).folder, files(2).name));
        fprintf('[UJI 3] Load: %s & %s\n', files(1).name, files(2).name);
    end
end

if isempty(imgInput) || isempty(imgRef)
    [X, Y] = meshgrid(linspace(0, 1, 200), linspace(0, 1, 200));
    imgInput = uint8(255 * (0.3 * X + 0.2 * Y));
    imgRef   = uint8(255 * sqrt(0.5 * X + 0.5 * Y));
end

if size(imgInput, 3) == 3
    imgInGray = rgb2grayLocal(imgInput);
else
    imgInGray = imgInput;
end

if size(imgRef, 3) == 3
    imgRefGray = rgb2grayLocal(imgRef);
else
    imgRefGray = imgRef;
end

% Hitung LUT dan terapkan ke citra
[lutGray, cdfIn, cdfRef] = computeHistogramMatchingLUT(imgInGray, imgRefGray);
imgMatched = applyHistogramMatchingLUT(imgInGray, lutGray);

[countsMatched, ~] = computeHistogram(imgMatched);
[cdfMatched, ~]    = computeCDF(imgMatched);

fprintf('  Mean Input: %.2f | Mean Matched: %.2f | Target Ref: %.2f\n', ...
    mean(double(imgInGray(:))), mean(double(imgMatched(:))), mean(double(imgRefGray(:))));

%% Visualisasi
figure('Name', 'Pengujian Histogram Matching LUT', 'Position', [80, 80, 1100, 650]);

subplot(2, 3, 1); imshow(imgInGray); title('Citra Input');
subplot(2, 3, 2); imshow(imgRefGray); title('Citra Referensi');
subplot(2, 3, 3); imshow(imgMatched); title('Hasil Matching');

subplot(2, 3, 4);
plot(0:255, lutGray, 'b-', 0:255, 0:255, 'k--', 'LineWidth', 1.5);
xlim([0 255]); ylim([0 255]); grid on;
xlabel('r'); ylabel('z'); title('LUT: r \rightarrow z');
legend('Mapping', 'Identity', 'Location', 'northwest');

subplot(2, 3, 5);
bins = 0:255;
plot(bins, cdfIn, 'r-', bins, cdfRef, 'g-', bins, cdfMatched, 'b--', 'LineWidth', 1.5);
xlim([0 255]); ylim([0 1.05]); grid on;
xlabel('Intensitas'); ylabel('CDF'); title('Kurva CDF');
legend('Input', 'Target', 'Matched', 'Location', 'southeast');

subplot(2, 3, 6);
[countsIn, ~] = computeHistogram(imgInGray);
[countsRef, ~] = computeHistogram(imgRefGray);
bar(bins, countsIn, 'FaceColor', [1 0.4 0.4], 'FaceAlpha', 0.4, 'EdgeColor', 'none'); hold on;
bar(bins, countsRef, 'FaceColor', [0.2 0.8 0.2], 'FaceAlpha', 0.4, 'EdgeColor', 'none');
bar(bins, countsMatched, 'FaceColor', [0.2 0.2 1], 'FaceAlpha', 0.4, 'EdgeColor', 'none'); hold off;
xlim([0 255]); grid on;
xlabel('Intensitas'); ylabel('Frekuensi'); title('Histogram');
legend('Input', 'Referensi', 'Matched', 'Location', 'northeast');

fprintf('\nPengujian selesai.\n');

function gray = rgb2grayLocal(rgb)
    gray = uint8(round(0.2989 * double(rgb(:,:,1)) + 0.5870 * double(rgb(:,:,2)) + 0.1140 * double(rgb(:,:,3))));
end
