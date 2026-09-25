% Hitung statistik dasar citra
function stats = computeImageStats(img)
    stats = struct();

    % Deteksi tipe citra
    if ndims(img) == 3 && size(img, 3) == 3
        stats.isRGB = true;
        % Konversi ke grayscale untuk statistik keseluruhan
        gray = 0.2989 * double(img(:, :, 1)) + ...
               0.5870 * double(img(:, :, 2)) + ...
               0.1140 * double(img(:, :, 3));
    else
        stats.isRGB = false;
        gray = double(img);
    end

    % Normalisasi ke 0-255 jika perlu
    if max(gray(:)) <= 1
        gray = gray * 255;
    end
    
    stats.min = min(gray(:));
    stats.max = max(gray(:));
    stats.mean = mean(gray(:));
    stats.std = std(gray(:));
    stats.dynamicRange = stats.max - stats.min;

    % Hitung histogram untuk entropi
    [counts] = computeHistogramLocal(img);

    % Hitung probabilitas
    totalPixels = sum(counts);
    if totalPixels > 0
        p = counts / totalPixels;
        p(p == 0) = [];  % Hapus nol
        stats.entropy = -sum(p .* log2(p));
    else
        stats.entropy = 0;
    end

    if stats.isRGB
        for ch = 1:3
            channel = double(img(:, :, ch));
            if max(channel(:)) <= 1
                channel = channel * 255;
            end
            channelName = {'Red', 'Green', 'Blue'};
            stats.channelStats.(channelName{ch}) = struct();
            stats.channelStats.(channelName{ch}).min = min(channel(:));
            stats.channelStats.(channelName{ch}).max = max(channel(:));
            stats.channelStats.(channelName{ch}).mean = mean(channel(:));
            stats.channelStats.(channelName{ch}).std = std(channel(:));
        end
    end
end