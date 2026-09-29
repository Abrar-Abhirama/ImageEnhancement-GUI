% Transformasi Intensitas pada Citra
function result = intensityTransform(img, varargin)
    p = inputParser;
    addRequired(p, 'img', @isnumeric);
    addRequired(p, 'transformType', @ischar);
    addParameter(p, 'c', 1);
    addParameter(p, 'gamma', 1);
    addParameter(p, 'offset', 0.1);
    addParameter(p, 'brightness', 0);
    addParameter(p, 'contrast', 1);
    parse(p, img, varargin{1}, varargin{2:end});

    img = double(img);

    switch lower(p.Results.transformType)
        case 'negative'
            result = transformNegative(img);
        case 'log'
            result = transformLog(img, p.Results.c);
        case 'power'
            result = transformPower(img, p.Results.c, p.Results.gamma);
        case 'contrast'
            result = transformContrastStretching(img);
        case 'histogram_stretch'
            result = transformHistogramStretch(img);
        case 'brightness_adjustment'
            result = transformBrightnessAdjustment(img, p.Results.brightness);
        case 'contrast_correction'
            result = transformContrastCorrection(img, p.Results.contrast);
        otherwise
            error('Transformasi tidak dikenal: %s', p.Results.transformType);
    end

    result = uint8(result);
end


% Negasi: s = 255 - r
% Membalik intensitas citra (brightness reversal)
function result = transformNegative(img)
    if size(img, 3) == 3
        result = zeros(size(img));
        for c = 1:3
            result(:, :, c) = 255 - img(:, :, c);
        end
    else
        result = 255 - img;
    end
end


% Log: s = c * (log(1 + r) / log(256)) * 255
function result = transformLog(img, c)
    result = c * (log(1 + img) / log(256)) * 255;
    result = max(0, min(255, result));
end


% Power-law: s = c * ((r / 255)^gamma) * 255
function result = transformPower(img, c, gamma)
    result = c * ((img / 255) .^ gamma) * 255;
    result = max(0, min(255, result));
end


% Contrast Stretching: s = (r - rmin) / (rmax - rmin) * 255
function result = transformContrastStretching(img)
    if size(img, 3) == 3
        result = zeros(size(img));
        for c = 1:3
            ch = img(:, :, c);
            mn = min(ch(:));
            mx = max(ch(:));
            if mx > mn
                result(:, :, c) = (ch - mn) / (mx - mn) * 255;
            else
                result(:, :, c) = ch;
            end
        end
    else
        mn = min(img(:));
        mx = max(img(:));
        if mx > mn
            result = (img - mn) / (mx - mn) * 255;
        else
            result = img;
        end
    end
end


% Histogram Stretch: sama dengan contrast stretching
function result = transformHistogramStretch(img)
    result = transformContrastStretching(img);
end


% Brightness Adjustment: s = r + brightness * 255
function result = transformBrightnessAdjustment(img, brightness)
    brightnessVal = brightness * 255;
    result = img + brightnessVal;
    result = max(0, min(255, result));
end


% Contrast Correction: s = c * (r - mean) + mean
function result = transformContrastCorrection(img, contrast)
    if size(img, 3) == 3
        result = zeros(size(img));
        for ch = 1:3
            channel = img(:, :, ch);
            meanVal = mean(channel(:));
            result(:, :, ch) = contrast * (channel - meanVal) + meanVal;
        end
    else
        meanVal = mean(img(:));
        result = contrast * (img - meanVal) + meanVal;
    end

    result = max(0, min(255, result));
end