% Konvolusi 2D Spasial Manual
function [outputImg, flippedKernel] = applyConvolution2D(img, kernel, varargin)
    % 1. Validasi input citra dan kernel
    if nargin < 2 || isempty(img) || isempty(kernel)
        error('Citra input dan kernel convolution harus disediakan.');
    end

    if ~isnumeric(img)
        error('Citra input harus berupa array numerik.');
    end

    if ~isnumeric(kernel) || ndims(kernel) > 2
        error('Kernel harus berupa matriks 2D numerik.');
    end

    [kh, kw] = size(kernel);
    if mod(kh, 2) == 0 || mod(kw, 2) == 0
        error('Dimensi kernel harus berupa bilangan ganjil (contoh: 3x3, 5x5, 7x7). Diterima: %dx%d.', kh, kw);
    end

    % 2. Parsing parameter opsional
    p = inputParser;
    addParameter(p, 'padding', 'replicate', @(x) ischar(x) || isstring(x));
    addParameter(p, 'boundary', '', @(x) ischar(x) || isstring(x));
    addParameter(p, 'clip', [], @(x) isempty(x) || islogical(x) || isnumeric(x));
    parse(p, varargin{:});

    paddingMode = char(p.Results.padding);
    if ~isempty(p.Results.boundary)
        paddingMode = char(p.Results.boundary);
    end

    origClass = class(img);
    isUint8Input = isa(img, 'uint8');

    if isempty(p.Results.clip)
        clipOutput = isUint8Input;
    else
        clipOutput = logical(p.Results.clip);
    end

    % Flip kernel 180 derajat
    flippedKernel = zeros(kh, kw);
    for i = 1:kh
        for j = 1:kw
            flippedKernel(i, j) = kernel(kh - i + 1, kw - j + 1);
        end
    end

    % Padding untuk menjaga ukuran citra
    padH = (kh - 1) / 2;
    padW = (kw - 1) / 2;
    paddedImg = padImageManual(img, padH, padW, paddingMode);

    [H, W, numChannels] = size(img);
    paddedDouble = double(paddedImg);
    accumResult = zeros(H, W, numChannels);

    % Konvolusi 2D manual
    for ch = 1:numChannels
        chPadded = paddedDouble(:, :, ch);
        for i = 1:H
            for j = 1:W
                window = chPadded(i : i + kh - 1, j : j + kw - 1);
                accumResult(i, j, ch) = sum(sum(window .* flippedKernel));
            end
        end
    end

    % Format output
    if clipOutput
        clamped = max(0, min(255, round(accumResult)));
        outputImg = uint8(clamped);
    else
        if isUint8Input
            outputImg = accumResult;
        else
            outputImg = cast(accumResult, origClass);
        end
    end
end
