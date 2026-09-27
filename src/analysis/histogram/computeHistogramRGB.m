% Fungsi menggunakan computeHistogramChannel dari shared location
function [countsR, countsG, countsB, bins] = computeHistogramRGB(img)
    % Validasi input
    if size(img, 3) ~= 3
        error('Input harus citra RGB (3 channel)');
    end

    % Ekstrak kanal
    r = img(:, :, 1);
    g = img(:, :, 2);
    b = img(:, :, 3);

    % Hitung histogram setiap kanal menggunakan fungsi shared
    countsR = computeHistogramChannel(r);
    countsG = computeHistogramChannel(g);
    countsB = computeHistogramChannel(b);

    bins = 0:255;
end