% Visualisasi perbandingan sebelum dan sesudah enhancement
function fig = visualizeEnhancementComparison(imgOriginal, imgEnhanced, methodName, params)
    if nargin < 3
        methodName = 'Enhancement';
    end

    fig = figure('Name', ['Enhancement: ' methodName], ...
        'Position', [100, 100, 1200, 600]);

    % Subplot 1: Citra Asli
    subplot(2, 2, 1);
    if ndims(imgOriginal) == 3
        imshow(imgOriginal);
    else
        imshow(imgOriginal, []);
    end
    title('Citra Asli', 'FontSize', 12, 'FontWeight', 'bold');

    % Subplot 2: Histogram Asli
    subplot(2, 2, 2);
    plotHistogram(imgOriginal, 'Histogram Asli');

    % Subplot 3: Citra Hasil
    subplot(2, 2, 3);
    if ndims(imgEnhanced) == 3
        imshow(imgEnhanced);
    else
        imshow(imgEnhanced, []);
    end
    title(['Hasil: ' methodName], 'FontSize', 12, 'FontWeight', 'bold');
    
    % Subplot 4: Histogram Hasil
    subplot(2, 2, 4);
    plotHistogram(imgEnhanced, 'Histogram Hasil');

    % Tampilkan info parameter jika ada
    if nargin >= 4 && ~isempty(params)
        paramStr = formatParams(params);
        annotation('textbox', [0.02, 0.02, 0.3, 0.08], ...
            'String', ['Parameter: ' paramStr], ...
            'FitBoxToText', 'on', ...
            'BackgroundColor', [1 1 0.9], ...
            'EdgeColor', [0.8 0.8 0.8], ...
            'FontSize', 9);
    end
end


% Plot histogram untuk citra grayscale atau RGB
function plotHistogram(img, titleStr)
    if ndims(img) == 3 && size(img, 3) == 3
        % Citra RGB - histogram terpisah
        [countsR, countsG, countsB, bins] = computeHistogramLocal(img);

        hold on;
        bar(bins, countsR, 'r', 'FaceAlpha', 0.5, 'EdgeAlpha', 0.3);
        bar(bins, countsG, 'g', 'FaceAlpha', 0.5, 'EdgeAlpha', 0.3);
        bar(bins, countsB, 'b', 'FaceAlpha', 0.5, 'EdgeAlpha', 0.3);
        hold off;

        legend('Red', 'Green', 'Blue', 'Location', 'northwest');
    else
        % Citra grayscale
        [counts, bins] = computeHistogramLocal(img);
        bar(bins, counts, 'k', 'FaceAlpha', 0.7);
    end

    xlim([0 255]);
    xlabel('Intensitas (0-255)');
    ylabel('Frekuensi');
    title(titleStr, 'FontSize', 11, 'FontWeight', 'bold');
    grid on;
end


% Format parameter menjadi string
function paramStr = formatParams(params)
    fieldNames = fieldnames(params);
    paramParts = {};

    for i = 1:length(fieldNames)
        fieldName = fieldNames{i};
        value = params.(fieldName);

        if ischar(value)
            paramParts{end+1} = sprintf('%s=%s', fieldName, value);
        elseif islogical(value)
            paramParts{end+1} = sprintf('%s=%s', fieldName, mat2str(value));
        elseif isscalar(value)
            paramParts{end+1} = sprintf('%s=%.3g', fieldName, value);
        else
            paramParts{end+1} = sprintf('%s=[%s]', fieldName, num2str(value));
        end
    end

    paramStr = strjoin(paramParts, ', ');
end