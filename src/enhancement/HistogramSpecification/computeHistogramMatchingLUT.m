% computeHistogramMatchingLUT
% Menghitung LUT pemetaan intensitas Histogram Matching: z = G^(-1)(F(r))
function [mapping, cdfIn, cdfRef] = computeHistogramMatchingLUT(inputData, refData)
    if nargin < 2 || isempty(inputData) || isempty(refData)
        error('Input dan referensi citra/histogram diperlukan.');
    end

    isRGBInput = (ndims(inputData) == 3 && size(inputData, 3) == 3);
    isRGBRef   = (ndims(refData) == 3 && size(refData, 3) == 3);

    if isRGBInput && isRGBRef
        [countsInR, countsInG, countsInB, ~] = computeHistogram(inputData);
        [countsRefR, countsRefG, countsRefB, ~] = computeHistogram(refData);

        cdfInR = calculateNormalizedCDF(countsInR);
        cdfInG = calculateNormalizedCDF(countsInG);
        cdfInB = calculateNormalizedCDF(countsInB);

        cdfRefR = calculateNormalizedCDF(countsRefR);
        cdfRefG = calculateNormalizedCDF(countsRefG);
        cdfRefB = calculateNormalizedCDF(countsRefB);

        lutR = findClosestMapping(cdfInR, cdfRefR);
        lutG = findClosestMapping(cdfInG, cdfRefG);
        lutB = findClosestMapping(cdfInB, cdfRefB);

        mapping = [lutR, lutG, lutB];
        cdfIn   = [cdfInR, cdfInG, cdfInB];
        cdfRef  = [cdfRefR, cdfRefG, cdfRefB];

    elseif isRGBInput && ~isRGBRef
        [countsInR, countsInG, countsInB, ~] = computeHistogram(inputData);
        countsRef = extractCounts(refData);

        cdfInR = calculateNormalizedCDF(countsInR);
        cdfInG = calculateNormalizedCDF(countsInG);
        cdfInB = calculateNormalizedCDF(countsInB);
        cdfRefSingle = calculateNormalizedCDF(countsRef);

        lutR = findClosestMapping(cdfInR, cdfRefSingle);
        lutG = findClosestMapping(cdfInG, cdfRefSingle);
        lutB = findClosestMapping(cdfInB, cdfRefSingle);

        mapping = [lutR, lutG, lutB];
        cdfIn   = [cdfInR, cdfInG, cdfInB];
        cdfRef  = repmat(cdfRefSingle, 1, 3);

    else
        countsIn = extractCounts(inputData);
        countsRef = extractCounts(refData);

        cdfIn = calculateNormalizedCDF(countsIn);
        cdfRef = calculateNormalizedCDF(countsRef);

        mapping = findClosestMapping(cdfIn, cdfRef);
    end
end

% Ekstrak counts 256x1 dari citra atau vektor
function counts = extractCounts(data)
    if isvector(data) && numel(data) == 256
        counts = double(data(:));
    else
        if ndims(data) == 3 && size(data, 3) == 3
            gray = 0.2989 * double(data(:,:,1)) + 0.5870 * double(data(:,:,2)) + 0.1140 * double(data(:,:,3));
            [c, ~] = computeHistogram(gray);
            counts = double(c(:));
        else
            [c, ~] = computeHistogram(data);
            counts = double(c(:));
        end
    end
end

% Hitung CDF ternormalisasi [0, 1]
function cdf = calculateNormalizedCDF(counts)
    counts = double(counts(:));
    cdf = zeros(256, 1);
    cumulative = 0;
    for i = 1:256
        cumulative = cumulative + counts(i);
        cdf(i) = cumulative;
    end

    total = cdf(256);
    if total > 0
        cdf = cdf / total;
    else
        cdf = zeros(256, 1);
    end
end

% Cari z yang meminimalkan |G(z) - F(r)| untuk setiap r
function mapping = findClosestMapping(cdfIn, cdfRef)
    mapping = zeros(256, 1, 'uint8');

    for r = 0:255
        r_idx = r + 1;
        fr = cdfIn(r_idx);
        minDiff = Inf;
        bestZ = 0;

        for z = 0:255
            z_idx = z + 1;
            diff = abs(cdfRef(z_idx) - fr);
            if diff < minDiff
                minDiff = diff;
                bestZ = z;
            end
        end

        mapping(r_idx) = uint8(bestZ);
    end
end
