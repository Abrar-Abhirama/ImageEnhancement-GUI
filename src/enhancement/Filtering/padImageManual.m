% Padding Citra Manual
function padded = padImageManual(img, padH, padW, mode)
    if nargin < 4 || isempty(mode)
        mode = 'replicate';
    end

    if ~isnumeric(img)
        error('Input citra harus bertipe numerik.');
    end

    if padH < 0 || padW < 0 || floor(padH) ~= padH || floor(padW) ~= padW
        error('Ukuran padding (padH, padW) harus berupa bilangan bulat non-negatif.');
    end

    % Jika tidak ada padding yang dibutuhkan, kembalikan citra asli
    if padH == 0 && padW == 0
        padded = img;
        return;
    end

    [H, W, numChannels] = size(img);
    mode = lower(mode);

    switch mode
        case {'zero', 'zeros'}
            % Zero padding
            padded = zeros(H + 2 * padH, W + 2 * padW, numChannels, class(img));
            padded(padH + 1 : padH + H, padW + 1 : padW + W, :) = img;

        case 'replicate'
            % Replicate border
            rowIndices = min(max((1 - padH) : (H + padH), 1), H);
            colIndices = min(max((1 - padW) : (W + padW), 1), W);
            padded = img(rowIndices, colIndices, :);

        case {'symmetric', 'reflect'}
            % Symmetric reflection
            rowIndices = getSymmetricIndices(H, padH);
            colIndices = getSymmetricIndices(W, padW);
            padded = img(rowIndices, colIndices, :);

        otherwise
            error('Mode padding tidak dikenal: %s. Gunakan ''replicate'', ''zero'', atau ''symmetric''.', mode);
    end
end

% Hitung indeks symmetric manual (whole-point reflection)
function indices = getSymmetricIndices(len, pad)
    indices = zeros(1, len + 2 * pad);
    for k = 1:(len + 2 * pad)
        pos = k - pad;
        while pos < 1 || pos > len
            if pos < 1
                pos = 1 - pos;
            elseif pos > len
                pos = 2 * len + 1 - pos;
            end
        end
        indices(k) = min(max(pos, 1), len);
    end
end
