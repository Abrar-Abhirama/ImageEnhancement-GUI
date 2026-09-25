scriptDir = fileparts(mfilename('fullpath'));
testDir = fileparts(scriptDir);
srcDir = fileparts(testDir);
projectRoot = fileparts(srcDir);

fprintf('Project root: %s\n', projectRoot);
addpath(genpath(projectRoot));

fprintf('=== PENGUJIAN INTENSITY TRANSFORMATION ===\n\n');

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

fprintf('--- Statistik Awal ---\n');
if isRGB
    fprintf('R: Min=%d, Max=%d, Mean=%.1f\n', min(img(:)), max(img(:)), mean(double(img(:))));
else
    fprintf('Mean=%.1f, Std=%.1f\n', mean(double(img(:))), std(double(img(:))));
end

transforms = {
    'negative',          {},                     'Negasi';
    'log',              {'c',1},              'Log';
    'power',            {'c',1,'gamma',0.5}, 'Gamma 0.5 (Bright)';
    'power',            {'c',1,'gamma',2.0}, 'Gamma 2.0 (Dark)';
    'contrast',         {},                     'Contrast Stretch';
    'histogram_slide',  {'offset',0.15},      'Slide +';
    'histogram_slide',  {'offset',-0.15},     'Slide -';
    'histogram_stretch',{},                     'Histogram Stretch';
};

fig1 = figure('Name','Results - RGB Images');
fig2 = figure('Name','Results - RGB Histograms');

for i = 1:length(transforms)
    type = transforms{i,1};
    params = transforms{i,2};
    desc = transforms{i,3};

    if isempty(params)
        result = intensityTransform(img, type);
    else
        result = intensityTransform(img, type, params{:});
    end

    fprintf('[%d/%d] %s\n', i, length(transforms), desc);

    figure(fig1);
    subplot(3,3,i); imshow(result); title(type,'Interpreter','none');

    figure(fig2);
    subplot(3,3,i);
    if isRGB
        [cR,cG,cB] = computeHistogram(result);
        hold on;
        bar(0:255,cR,'r','FaceAlpha',0.5);
        bar(0:255,cG,'g','FaceAlpha',0.5);
        bar(0:255,cB,'b','FaceAlpha',0.5);
        hold off;
    else
        [c] = computeHistogram(result);
        bar(0:255,c,'k','FaceAlpha',0.5);
    end
    xlim([0 255]); grid on;
    title(sprintf('%s Histogram',type),'Interpreter','none');
end

figure(fig1);
subplot(3,3,9); imshow(img); title('Original');
figure(fig2);
subplot(3,3,9);
if isRGB
    [cR,cG,cB] = computeHistogram(img);
    hold on;
    bar(0:255,cR,'r','FaceAlpha',0.5);
    bar(0:255,cG,'g','FaceAlpha',0.5);
    bar(0:255,cB,'b','FaceAlpha',0.5);
    hold off;
    legend('R','G','B');
else
    [c] = computeHistogram(img);
    bar(0:255,c,'k','FaceAlpha',0.5);
end
xlim([0 255]); grid on;
title('Original Histogram');

fprintf('\n=== SELESAI ===\n');
fprintf('3 figure window terbuka: Results - RGB Images, Results - RGB Histograms\n');


function out = ternary(cond, t, f)
    if cond, out = t; else, out = f; end
end

function img = createTestImage()
    [x,y] = meshgrid(1:256,1:256);
    r = uint8(x); g = uint8(y); b = uint8(256-x);
    img = cat(3,r,g,b);
    img(1:64,:,:) = img(1:64,:,:) * 0.3;
    img = min(255, max(0, img));
end