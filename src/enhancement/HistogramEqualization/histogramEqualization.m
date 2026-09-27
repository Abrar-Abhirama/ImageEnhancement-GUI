% Histogram Equalization untuk Peningkatan Kontras
function result = histogramEqualization(img, varargin)
    % Parse input
    p = inputParser;
    addRequired(p, 'img', @isnumeric);
    addParameter(p, 'mode', 'global');
    parse(p, img, varargin{:});

    mode = lower(p.Results.mode);
    isColored = (size(img, 3) == 3);

    if isColored
        switch mode
            case 'global'
                % Equalize setiap channel secara independen
                result = equalizeGlobal(img);
            case 'hsv'
                % Convert ke HSV, equalize V channel saja
                result = equalizeHSV(img);
            case 'ycbcr'
                % Convert ke YCbCr, equalize Y channel saja
                result = equalizeYCbCr(img);
            otherwise
                error('Mode tidak dikenal: %s. Gunakan ''global'', ''hsv'', atau ''ycbcr''', mode);
        end
    else
        result = equalizeGrayscale(img);
    end

    result = uint8(result);
end


% Equalize citra grayscale
function result = equalizeGrayscale(img)
    [m, n] = size(img);
    numPixels = m * n;
    img = double(img);

    % Hitung histogram
    counts = computeHistogramChannel(img);

    % Hitung CDF (cumulative)
    cdf = cumsum(counts);

    % Normalisasi CDF
    % CDF normalized = (CDF / total_pixels) * 255
    cdfNormalized = (cdf / numPixels) * 255;
    cdfNormalized = round(cdfNormalized);

    % Transformasi/Mapping
    result = zeros(m, n);
    for i = 1:m
        for j = 1:n
            r = round(img(i, j)) + 1;  % round() untuk keamanan
            r = max(1, min(256, r));  % Clamp
            result(i, j) = cdfNormalized(r);
        end
    end
end


% Equalize setiap channel secara independen
function result = equalizeGlobal(img)
    [m, n, ~] = size(img);
    numPixels = m * n;

    result = zeros(size(img));

    % Equalize setiap channel
    for ch = 1:3
        channel = double(img(:, :, ch));

        % Hitung histogram channel
        counts = computeHistogramChannel(channel);

        % Hitung CDF
        cdf = cumsum(counts);

        % Normalisasi CDF
        cdfNormalized = round((cdf / numPixels) * 255);

        % Transformasi
        for i = 1:m
            for j = 1:n
                r = round(channel(i, j)) + 1;
                r = max(1, min(256, r));
                result(i, j, ch) = cdfNormalized(r);
            end
        end
    end
end


% Equalize hanya Value channel di HSV
function result = equalizeHSV(img)
    % Konversi RGB ke HSV
    hsv = rgb2hsvCustom(img);

    % Ambil channel V (berada pada range [0, 1])
    v = double(hsv(:, :, 3));
    [m, n] = size(v);

    % Konversi V dari [0,1] ke [0,255]
    vScaled = v * 255;

    % Equalize V channel
    counts = computeHistogramChannel(vScaled);
    cdf = cumsum(counts);
    cdfNormalized = round((cdf / (m * n)) * 255);

    resultV = zeros(m, n);
    for i = 1:m
        for j = 1:n
            r = round(vScaled(i, j)) + 1;  % round() untuk keamanan
            r = max(1, min(256, r));
            resultV(i, j) = cdfNormalized(r);
        end
    end

    % Konversi hasil dari [0,255] kembali ke [0,1] untuk HSV
    resultV_normalized = resultV / 255;
    resultV_normalized = max(0, min(1, resultV_normalized));  % Safety clamp
    hsv(:, :, 3) = resultV_normalized;

    % Konversi HSV ke RGB
    result = hsv2rgbCustom(hsv);
end


% Equalize hanya Y (luminance) channel di YCbCr
function result = equalizeYCbCr(img)
    % Konversi RGB ke YCbCr
    ycbcr = rgb2ycbcrCustom(img);

    % Ambil channel Y (luminance)
    y = double(ycbcr(:, :, 1));
    [m, n] = size(y);

    % Equalize Y channel
    counts = computeHistogramChannel(y);
    cdf = cumsum(counts);
    cdfNormalized = round((cdf / (m * n)) * 255);

    resultY = zeros(m, n);
    for i = 1:m
        for j = 1:n
            r = round(y(i, j)) + 1;
            r = max(1, min(256, r));
            resultY(i, j) = cdfNormalized(r);
        end
    end

    % Replace Y channel
    ycbcr(:, :, 1) = resultY;

    % Konversi YCbCr ke RGB
    result = ycbcr2rgbCustom(ycbcr);
end


% Konversi RGB ke HSV
function hsv = rgb2hsvCustom(rgb)
    r = double(rgb(:, :, 1)) / 255;
    g = double(rgb(:, :, 2)) / 255;
    b = double(rgb(:, :, 3)) / 255;

    v = max(max(r, g), b);
    c = v - min(min(r, g), b);

    s = zeros(size(v));
    s(v ~= 0) = c(v ~= 0) ./ v(v ~= 0);

    h = zeros(size(v));
    mask = c ~= 0;

    % Calculate hue for non-zero chroma pixels
    rc = (v - r) ./ c;
    gc = (v - g) ./ c;
    bc = (v - b) ./ c;

    % Blue max
    idx = (v == b) & mask;
    h(idx) = 60 * gc(idx) + 240;
    % Green max
    idx = (v == g) & mask;
    h(idx) = 60 * bc(idx) + 120;
    % Red max
    idx = (v == r) & mask;
    h(idx) = 60 * (gc(idx) - bc(idx));

    h = mod(h, 360) / 360;  % Normalize to [0,1]

    hsv = cat(3, h, s, v);
end


% Konversi HSV ke RGB
function rgb = hsv2rgbCustom(hsv)
    h = double(hsv(:, :, 1));  % H dalam [0,1]
    s = double(hsv(:, :, 2));  % S dalam [0,1]
    v = double(hsv(:, :, 3));  % V dalam [0,1]

    [m, n] = size(h);
    rgb = zeros(m, n, 3);

    for i = 1:m
        for j = 1:n
            hi = mod(h(i,j) * 6, 6);  % Hue sector (0-6)
            f = h(i,j) * 6 - hi;      % Fractional part
            p = v(i,j) * (1 - s(i,j));
            q = v(i,j) * (1 - f * s(i,j));
            t = v(i,j) * (1 - (1 - f) * s(i,j));

            if hi < 1
                rgb(i,j,1) = v(i,j); rgb(i,j,2) = t; rgb(i,j,3) = p;
            elseif hi < 2
                rgb(i,j,1) = q; rgb(i,j,2) = v(i,j); rgb(i,j,3) = p;
            elseif hi < 3
                rgb(i,j,1) = p; rgb(i,j,2) = v(i,j); rgb(i,j,3) = t;
            elseif hi < 4
                rgb(i,j,1) = p; rgb(i,j,2) = q; rgb(i,j,3) = v(i,j);
            elseif hi < 5
                rgb(i,j,1) = t; rgb(i,j,2) = p; rgb(i,j,3) = v(i,j);
            else
                rgb(i,j,1) = v(i,j); rgb(i,j,2) = p; rgb(i,j,3) = q;
            end
        end
    end

    rgb = rgb * 255;
end


% Konversi RGB ke YCbCr
function ycbcr = rgb2ycbcrCustom(rgb)
    r = double(rgb(:, :, 1));
    g = double(rgb(:, :, 2));
    b = double(rgb(:, :, 3));

    ycbcr(:, :, 1) = 0.299 * r + 0.587 * g + 0.114 * b;                    % Y
    ycbcr(:, :, 2) = 128 - 0.168736 * r - 0.331264 * g + 0.5 * b;          % Cb
    ycbcr(:, :, 3) = 128 + 0.5 * r - 0.418688 * g - 0.081312 * b;          % Cr
end


function rgb = ycbcr2rgbCustom(ycbcr)
    % Konversi YCbCr ke RGB
    y = double(ycbcr(:, :, 1));
    cb = double(ycbcr(:, :, 2));
    cr = double(ycbcr(:, :, 3));

    rgb(:, :, 1) = y + 1.402 * (cr - 128);
    rgb(:, :, 2) = y - 0.344136 * (cb - 128) - 0.714136 * (cr - 128);
    rgb(:, :, 3) = y + 1.772 * (cb - 128);

    rgb = max(0, min(255, rgb));
end