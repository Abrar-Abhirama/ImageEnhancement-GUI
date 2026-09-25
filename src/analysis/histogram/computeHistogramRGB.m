% Hitung Histogram Terpisah untuk Kanal R, G, B
function [countsR, countsG, countsB, bins] = computeHistogramRGB(img)
    % Validasi input
    if size(img, 3) ~= 3
        error('Input harus citra RGB (3 channel)');
    end

    % Ekstrak kanal
    r = img(:, :, 1);
    g = img(:, :, 2);
    b = img(:, :, 3);

    % Hitung histogram setiap kanal
    countsR = computeHistogramChannel(r);
    countsG = computeHistogramChannel(g);
    countsB = computeHistogramChannel(b);

    bins = 0:255;
end


% Hitung histogram untuk satu kanal
function counts = computeHistogramChannel(channel)
    % Konversi ke double dan bulatkan
    ch = double(channel);
    ch = round(ch);
    ch = max(0, min(255, ch));

    [m, n] = size(ch);

    % Inisialisasi histogram 256 bins
    counts = zeros(256, 1);

    % Hitung frekuensi setiap level intensitas
    for i = 1:m
        for j = 1:n
            % Index = intensitas + 1 (karena MATLAB 1-based indexing)
            idx = ch(i, j) + 1;
            idx = max(1, min(256, idx));  % Clamp untuk safety
            counts(idx) = counts(idx) + 1;
        end
    end
end