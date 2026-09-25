% Histogram untuk Citra Grayscale atau RGB
function varargout = computeHistogram(img, varargin)
    isColored = (size(img, 3) == 3);

    if isColored
        % Histogram RGB
        [countsR, countsG, countsB, bins] = computeHistogramRGB(img);

        if nargout >= 3
            varargout{1} = countsR;
            varargout{2} = countsG;
            varargout{3} = countsB;
            varargout{4} = bins;
        else
            varargout{1} = countsR;
            varargout{2} = countsG;
            varargout{3} = countsB;
            varargout{4} = bins;
        end

        % Auto-plot jika diminta
        if nargin > 1 && strcmpi(varargin{1}, 'display')
            figure('Name', 'Histogram RGB');
            plotRGBHistogram(countsR, countsG, countsB, bins);
        end
    else
        % Histogram grayscale
        [counts, bins] = computeHistogramGrayscale(img);
        varargout{1} = counts;
        varargout{2} = bins;

        % Auto-plot jika diminta
        if nargin > 1 && strcmpi(varargin{1}, 'display')
            figure('Name', 'Histogram Grayscale');
            bar(bins, counts, 'k');
            xlim([0 255]);
            xlabel('Intensitas (0-255)');
            ylabel('Frekuensi');
            title('Histogram Grayscale');
            grid on;
        end
    end
end


% Plot histogram RGB dengan warna yang sesuai
function plotRGBHistogram(countsR, countsG, countsB, bins)
    bar(bins, countsR, 'r', 'FaceAlpha', 0.5); hold on;
    bar(bins, countsG, 'g', 'FaceAlpha', 0.5);
    bar(bins, countsB, 'b', 'FaceAlpha', 0.5); hold off;
    xlim([0 255]);
    xlabel('Intensitas (0-255)');
    ylabel('Frekuensi');
    title('Histogram RGB Terpisah (R, G, B)');
    legend('Red', 'Green', 'Blue', 'Location', 'NorthEast');
    grid on;
end


% Helper functions
function [countsR, countsG, countsB, bins] = computeHistogramRGB(img)
    r = img(:, :, 1);
    g = img(:, :, 2);
    b = img(:, :, 3);
    countsR = computeHistogramChannel(r);
    countsG = computeHistogramChannel(g);
    countsB = computeHistogramChannel(b);
    bins = 0:255;
end


function counts = computeHistogramChannel(channel)
    ch = double(channel);
    ch = round(ch);
    ch = max(0, min(255, ch));
    [m, n] = size(ch);
    counts = zeros(256, 1);
    for i = 1:m
        for j = 1:n
            idx = ch(i, j) + 1;
            idx = max(1, min(256, idx));
            counts(idx) = counts(idx) + 1;
        end
    end
end


function [counts, bins] = computeHistogramGrayscale(img)
    img = double(img);
    img = round(img);
    img = max(0, min(255, img));
    [m, n] = size(img);
    counts = zeros(256, 1);
    for i = 1:m
        for j = 1:n
            idx = img(i, j) + 1;
            idx = max(1, min(256, idx));
            counts(idx) = counts(idx) + 1;
        end
    end
    bins = 0:255;
end