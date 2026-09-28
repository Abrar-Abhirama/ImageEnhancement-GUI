% API Utama Spatial Image Filtering
function [outputImg, info] = applyFilter(img, filterType, varargin)
    if nargin < 2 || isempty(img) || isempty(filterType)
        error('Citra input dan tipe filter harus disediakan.');
    end

    p = inputParser;
    p.KeepUnmatched = true;
    addRequired(p, 'img', @isnumeric);
    addRequired(p, 'filterType');
    addParameter(p, 'kernel', [], @isnumeric);
    addParameter(p, 'size', 3, @isnumeric);
    addParameter(p, 'windowSize', [], @isnumeric);
    addParameter(p, 'sigma', 1.0, @isnumeric);
    addParameter(p, 'variant', '8', @(x) ischar(x) || isstring(x) || isnumeric(x));
    addParameter(p, 'padding', 'replicate', @(x) ischar(x) || isstring(x));
    parse(p, img, filterType, varargin{:});

    info = struct();
    info.inputSize = size(img);
    info.isRGB = (ndims(img) == 3 && size(img, 3) == 3);

    % Jika filterType adalah matriks numerik, jalankan sebagai linear kustom
    if isnumeric(filterType)
        info.category = 'linear';
        info.filterType = 'custom';
        [outputImg, filterInfo] = linearFilter(img, filterType, varargin{:});
        info.details = filterInfo;
        info.outputSize = size(outputImg);
        return;
    end

    filterName = lower(char(filterType));

    switch filterName
        % Non-Linear Filtering: Median Filter
        case {'median', 'medfilt', 'non_linear', 'nonlinear'}
            info.category = 'non-linear';
            info.filterType = 'median';
            outputImg = medianFilter(img, varargin{:});

        % Linear Filtering: Manual Convolution
        case {'linear', 'convolution'}
            info.category = 'linear';
            if ~isempty(p.Results.kernel)
                kernelTarget = p.Results.kernel;
            else
                kernelTarget = 'mean';
            end
            [outputImg, filterInfo] = linearFilter(img, kernelTarget, varargin{:});
            info.filterType = filterInfo.filterName;
            info.details = filterInfo;

        % Shortcut Linear Filters
        case {'mean', 'average', 'box', 'gaussian', 'sharpen', 'sharpening', ...
              'sobel', 'sobel_gradient', 'sobel_x', 'sobel_y', 'laplacian', ...
              'prewitt_x', 'prewitt_y', 'custom'}
            info.category = 'linear';
            info.filterType = filterName;
            [outputImg, filterInfo] = linearFilter(img, filterName, varargin{:});
            info.details = filterInfo;

        otherwise
            error('Tipe filter tidak dikenal: %s. Gunakan: linear, median, mean, gaussian, sharpen, sobel, laplacian.', filterName);
    end

    info.outputSize = size(outputImg);
end
