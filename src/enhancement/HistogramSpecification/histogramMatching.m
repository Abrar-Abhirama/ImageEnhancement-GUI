% Histogram Matching / Specification
function [outputImg, info] = histogramMatching(img, refImg, varargin)
    if nargin < 2 || isempty(img) || isempty(refImg)
        error('Citra input dan citra referensi diperlukan.');
    end

    p = inputParser;
    addRequired(p, 'img', @isnumeric);
    addRequired(p, 'refImg', @isnumeric);
    addParameter(p, 'mode', 'global', @ischar);
    parse(p, img, refImg, varargin{:});

    mode = lower(p.Results.mode);
    isRGB = (ndims(img) == 3 && size(img, 3) == 3);

    if ~isRGB
        [mapping, cdfIn, cdfRef] = computeHistogramMatchingLUT(img, refImg);
        outputImg = applyHistogramMapping(img, mapping);
        currentMode = 'grayscale';
    else
        switch mode
            case 'global'
                [mapping, cdfIn, cdfRef] = computeHistogramMatchingLUT(img, refImg);
                outputImg = applyHistogramMapping(img, mapping, 'global');
                currentMode = 'global';

            case 'hsv'
                hsvIn = rgb2hsvLocal(img);
                hsvRef = rgb2hsvLocal(refImg);
                vIn  = hsvIn(:, :, 3) * 255;
                vRef = hsvRef(:, :, 3) * 255;

                [mapping, cdfIn, cdfRef] = computeHistogramMatchingLUT(vIn, vRef);
                outputImg = applyHistogramMapping(img, mapping, 'hsv');
                currentMode = 'hsv';

            case 'ycbcr'
                ycbcrIn = rgb2ycbcrLocal(img);
                ycbcrRef = rgb2ycbcrLocal(refImg);
                yIn  = ycbcrIn(:, :, 1);
                yRef = ycbcrRef(:, :, 1);

                [mapping, cdfIn, cdfRef] = computeHistogramMatchingLUT(yIn, yRef);
                outputImg = applyHistogramMapping(img, mapping, 'ycbcr');
                currentMode = 'ycbcr';

            otherwise
                error('Mode tidak dikenal: %s. Gunakan ''global'', ''hsv'', atau ''ycbcr''.', mode);
        end
    end

    if nargout > 1
        info = struct();
        info.mapping  = mapping;
        info.inputCDF = cdfIn;
        info.refCDF   = cdfRef;
        info.mode     = currentMode;
    end
end

function hsv = rgb2hsvLocal(rgb)
    r = double(rgb(:,:,1)) / 255;
    g = double(rgb(:,:,2)) / 255;
    b = double(rgb(:,:,3)) / 255;
    v = max(max(r, g), b);
    c = v - min(min(r, g), b);
    s = zeros(size(v));
    s(v ~= 0) = c(v ~= 0) ./ v(v ~= 0);
    h = zeros(size(v));
    mask = c ~= 0;
    rc = (v - r) ./ c;
    gc = (v - g) ./ c;
    bc = (v - b) ./ c;
    idx = (v == b) & mask; h(idx) = 60 * gc(idx) + 240;
    idx = (v == g) & mask; h(idx) = 60 * bc(idx) + 120;
    idx = (v == r) & mask; h(idx) = 60 * (gc(idx) - bc(idx));
    h = mod(h, 360) / 360;
    hsv = cat(3, h, s, v);
end

function ycbcr = rgb2ycbcrLocal(rgb)
    r = double(rgb(:,:,1));
    g = double(rgb(:,:,2));
    b = double(rgb(:,:,3));
    ycbcr = zeros(size(rgb));
    ycbcr(:,:,1) = 0.299 * r + 0.587 * g + 0.114 * b;
    ycbcr(:,:,2) = 128 - 0.168736 * r - 0.331264 * g + 0.5 * b;
    ycbcr(:,:,3) = 128 + 0.5 * r - 0.418688 * g - 0.081312 * b;
end
