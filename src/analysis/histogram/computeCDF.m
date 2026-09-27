% Hitung CDF dari citra atau histogram counts
function varargout = computeCDF(inputData, varargin)
    if nargin < 1 || isempty(inputData)
        error('Input citra atau vektor histogram counts diperlukan.');
    end

    isColored = (ndims(inputData) == 3 && size(inputData, 3) == 3);

    if isColored
        [countsR, countsG, countsB, ~] = computeHistogram(inputData);
        [cdfNormR, cdfRawR] = calculateCDFFromCounts(countsR);
        [cdfNormG, cdfRawG] = calculateCDFFromCounts(countsG);
        [cdfNormB, cdfRawB] = calculateCDFFromCounts(countsB);

        varargout{1} = cdfNormR;
        varargout{2} = cdfNormG;
        varargout{3} = cdfNormB;
        varargout{4} = cdfRawR;
        varargout{5} = cdfRawG;
        varargout{6} = cdfRawB;

        if nargin > 1 && ischar(varargin{1}) && strcmpi(varargin{1}, 'display')
            figure('Name', 'CDF (RGB)');
            bins = 0:255;
            plot(bins, cdfNormR, 'r-', bins, cdfNormG, 'g-', bins, cdfNormB, 'b-', 'LineWidth', 1.8);
            xlim([0 255]); ylim([0 1.05]); grid on;
            xlabel('Intensitas'); ylabel('CDF');
            legend('R', 'G', 'B', 'Location', 'SouthEast');
        end
    else
        if isvector(inputData) && numel(inputData) == 256
            counts = inputData;
        else
            [counts, ~] = computeHistogram(inputData);
        end

        [cdfNormalized, cdfRaw] = calculateCDFFromCounts(counts);

        varargout{1} = cdfNormalized;
        varargout{2} = cdfRaw;

        if nargin > 1 && ischar(varargin{1}) && strcmpi(varargin{1}, 'display')
            figure('Name', 'CDF (Grayscale)');
            plot(0:255, cdfNormalized, 'k-', 'LineWidth', 2);
            xlim([0 255]); ylim([0 1.05]); grid on;
            xlabel('Intensitas'); ylabel('CDF');
        end
    end
end

% Akumulasi manual counts 256-elemen dan normalisasi ke [0, 1]
function [cdfNormalized, cdfRaw] = calculateCDFFromCounts(counts)
    counts = double(counts(:));
    if length(counts) ~= 256
        error('Histogram counts harus memiliki 256 level intensitas (0-255).');
    end

    cdfRaw = zeros(256, 1);
    cumulativeSum = 0;
    for i = 1:256
        cumulativeSum = cumulativeSum + counts(i);
        cdfRaw(i) = cumulativeSum;
    end

    totalPixels = cdfRaw(256);
    if totalPixels > 0
        cdfNormalized = cdfRaw / totalPixels;
    else
        cdfNormalized = zeros(256, 1);
    end
end
