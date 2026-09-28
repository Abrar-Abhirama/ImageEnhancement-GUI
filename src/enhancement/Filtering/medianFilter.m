% Filter Median Spasial Manual
function outputImg = medianFilter(img, varargin)
    if nargin < 1 || isempty(img)
        error('Citra input harus disediakan.');
    end

    if ~isnumeric(img)
        error('Citra input harus berupa array numerik.');
    end

    p = inputParser;
    addParameter(p, 'size', 3, @isnumeric);
    addParameter(p, 'windowSize', [], @isnumeric);
    addParameter(p, 'padding', 'replicate', @(x) ischar(x) || isstring(x));
    parse(p, varargin{:});

    % Tentukan ukuran window (harus ganjil)
    wSize = p.Results.size;
    if ~isempty(p.Results.windowSize)
        wSize = p.Results.windowSize;
    end

    if isscalar(wSize)
        wh = wSize;
        ww = wSize;
    elseif length(wSize) == 2
        wh = wSize(1);
        ww = wSize(2);
    else
        error('Ukuran window harus skalar atau vektor [tinggi, lebar].');
    end

    if mod(wh, 2) == 0 || mod(ww, 2) == 0
        error('Ukuran window median filter harus bilangan ganjil (contoh: 3, 5, [3 3]).');
    end

    paddingMode = char(p.Results.padding);
    origClass = class(img);

    % Hitung radius padding
    padH = (wh - 1) / 2;
    padW = (ww - 1) / 2;

    % Terapkan boundary padding manual
    paddedImg = padImageManual(img, padH, padW, paddingMode);

    [H, W, numChannels] = size(img);
    output = zeros(H, W, numChannels, origClass);

    % Indeks nilai tengah setelah pengurutan
    numElements = wh * ww;
    medianIdx = (numElements + 1) / 2;

    % Filter median manual per channel
    for ch = 1:numChannels
        chPadded = paddedImg(:, :, ch);
        for i = 1:H
            for j = 1:W
                % 1. Ekstrak neighborhood lokal
                patch = chPadded(i : i + wh - 1, j : j + ww - 1);

                % 2. Kumpulkan nilai intensitas
                vals = patch(:);

                % 3. Urutkan nilai
                sortedVals = sort(vals);

                % 4 & 5. Ambil nilai median dan masukkan ke output
                output(i, j, ch) = sortedVals(medianIdx);
            end
        end
    end

    outputImg = output;
end
