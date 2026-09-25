% Transformasi Intensitas pada Citra
function result = intensityTransform(img, varargin)
    p = inputParser;
    addRequired(p, 'img', @isnumeric);
    addRequired(p, 'transformType', @ischar);
    addParameter(p, 'c', 1);
    addParameter(p, 'gamma', 1);
    addParameter(p, 'offset', 0.1);
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
        case 'histogram_slide'
            result = transformHistogramSlide(img, p.Results.offset);
        case 'histogram_stretch'
            result = transformHistogramStretch(img);
        otherwise
            error('Transformasi tidak dikenal: %s', p.Results.transformType);
    end

    result = uint8(result);
end


% Negasi: s = 255 - r
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


% Log: s = c * log(1 + r)
function result = transformLog(img, c)
    if size(img, 3) == 3
        result = zeros(size(img));
        for ch = 1:3
            result(:, :, ch) = c * log(1 + img(:, :, ch));
        end
    else
        result = c * log(1 + img);
    end
    result = rescale(result);
end


% Power-law: s = c * r^gamma
function result = transformPower(img, c, gamma)
    if size(img, 3) == 3
        result = zeros(size(img));
        for ch = 1:3
            result(:, :, ch) = c * (img(:, :, ch) .^ gamma);
        end
    else
        result = c * (img .^ gamma);
    end
    result = rescale(result);
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


% Histogram Slide: s = r + offset * 255
function result = transformHistogramSlide(img, offset)
    offsetVal = offset * 255;
    if size(img, 3) == 3
        result = zeros(size(img));
        for ch = 1:3
            result(:, :, ch) = img(:, :, ch) + offsetVal;
        end
    else
        result = img + offsetVal;
    end
    result = max(0, min(255, result));
end


% Histogram Stretch: sama dengan contrast stretching
function result = transformHistogramStretch(img)
    result = transformContrastStretching(img);
end


% Normalisasi ke 0-255
function output = rescale(img)
    mn = min(img(:));
    mx = max(img(:));
    if mx > mn
        output = (img - mn) / (mx - mn) * 255;
    else
        output = img;
    end
end