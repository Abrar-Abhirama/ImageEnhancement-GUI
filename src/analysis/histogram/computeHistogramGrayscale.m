% Hitung Histogram untuk Citra Grayscale
function [counts, bins] = computeHistogramGrayscale(img)
    % Validasi input
    if size(img, 3) == 3
        error('Gunakan computeHistogramRGB untuk citra berwarna');
    end

    % Konversi ke double dan bulatkan
    img = double(img);
    img = round(img);
    img = max(0, min(255, img));

    [m, n] = size(img);
    counts = zeros(256, 1);

    % Hitung frekuensi setiap level intensitas
    for i = 1:m
        for j = 1:n
            % Index = intensitas + 1 (MATLAB 1-based)
            idx = img(i, j) + 1;
            idx = max(1, min(256, idx));
            counts(idx) = counts(idx) + 1;
        end
    end

    bins = 0:255;
end


% Konversi RGB ke Grayscale
function gray = rgb2grayLocal(rgb)
    gray = 0.2989 * rgb(:, :, 1) + ...
        0.5870 * rgb(:, :, 2) + ...
        0.1140 * rgb(:, :, 3);
end