% Menerapkan intensity mapping (LUT 256-level) ke citra (Grayscale & RGB)
function outImg = applyHistogramMapping(img, mapping, varargin)
    if nargin < 2 || isempty(img) || isempty(mapping)
        error('Input citra dan tabel mapping diperlukan.');
    end

    mode = 'global';
    if nargin >= 3 && ischar(varargin{1})
        mode = lower(varargin{1});
    end

    origClass = class(img);
    isRGB = (ndims(img) == 3 && size(img, 3) == 3);

    if ~isRGB
        outImg = applyMappingChannel(img, mapping(:, 1));
    else
        switch mode
            case 'global'
                outImg = zeros(size(img), 'like', img);
                if size(mapping, 2) == 3
                    for c = 1:3
                        outImg(:, :, c) = applyMappingChannel(img(:, :, c), mapping(:, c));
                    end
                else
                    lut = mapping(:, 1);
                    for c = 1:3
                        outImg(:, :, c) = applyMappingChannel(img(:, :, c), lut);
                    end
                end

            case 'hsv'
                hsv = rgb2hsvCustom(img);
                v = double(hsv(:, :, 3)) * 255;
                vMapped = double(applyMappingChannel(v, mapping(:, 1))) / 255;
                hsv(:, :, 3) = max(0, min(1, vMapped));
                outImg = hsv2rgbCustom(hsv);

            case 'ycbcr'
                ycbcr = rgb2ycbcrCustom(img);
                y = double(ycbcr(:, :, 1));
                ycbcr(:, :, 1) = double(applyMappingChannel(y, mapping(:, 1)));
                outImg = ycbcr2rgbCustom(ycbcr);

            otherwise
                error('Mode tidak dikenal: %s. Gunakan ''global'', ''hsv'', atau ''ycbcr''.', mode);
        end
    end

    if ~isa(outImg, origClass) && strcmp(origClass, 'uint8')
        outImg = uint8(max(0, min(255, round(outImg))));
    end
end

function out = applyMappingChannel(channel, lut)
    ch = double(channel);
    idx = round(ch) + 1;
    idx = max(1, min(256, idx));
    lut = uint8(lut(:));
    out = lut(idx);
end

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

    rc = (v - r) ./ c;
    gc = (v - g) ./ c;
    bc = (v - b) ./ c;

    idx = (v == b) & mask;
    h(idx) = 60 * gc(idx) + 240;
    idx = (v == g) & mask;
    h(idx) = 60 * bc(idx) + 120;
    idx = (v == r) & mask;
    h(idx) = 60 * (gc(idx) - bc(idx));

    h = mod(h, 360) / 360;
    hsv = cat(3, h, s, v);
end

function rgb = hsv2rgbCustom(hsv)
    h = double(hsv(:, :, 1));
    s = double(hsv(:, :, 2));
    v = double(hsv(:, :, 3));

    [m, n] = size(h);
    rgb = zeros(m, n, 3);

    for i = 1:m
        for j = 1:n
            hi = mod(h(i,j) * 6, 6);
            f = h(i,j) * 6 - hi;
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

function ycbcr = rgb2ycbcrCustom(rgb)
    r = double(rgb(:, :, 1));
    g = double(rgb(:, :, 2));
    b = double(rgb(:, :, 3));

    ycbcr = zeros(size(rgb));
    ycbcr(:, :, 1) = 0.299 * r + 0.587 * g + 0.114 * b;
    ycbcr(:, :, 2) = 128 - 0.168736 * r - 0.331264 * g + 0.5 * b;
    ycbcr(:, :, 3) = 128 + 0.5 * r - 0.418688 * g - 0.081312 * b;
end

function rgb = ycbcr2rgbCustom(ycbcr)
    y  = double(ycbcr(:, :, 1));
    cb = double(ycbcr(:, :, 2));
    cr = double(ycbcr(:, :, 3));

    rgb = zeros(size(ycbcr));
    rgb(:, :, 1) = y + 1.402 * (cr - 128);
    rgb(:, :, 2) = y - 0.344136 * (cb - 128) - 0.714136 * (cr - 128);
    rgb(:, :, 3) = y + 1.772 * (cb - 128);

    rgb = max(0, min(255, rgb));
end
