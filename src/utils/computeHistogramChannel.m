% Hitung histogram untuk satu channel (0-255)
function counts = computeHistogramChannel(channel)
    % Konversi ke double dan bulatkan
    ch = double(channel);
    ch = round(ch);
    ch = max(0, min(255, ch));  % Clamp ke range [0, 255]

    [m, n] = size(ch);

    % Inisialisasi histogram 256 bins (0-255)
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