% Filtering Linier pada Citra
function [outputImg, info] = linearFilter(img, filterNameOrKernel, varargin)
    if nargin < 2 || isempty(img) || isempty(filterNameOrKernel)
        error('Citra input dan filter/kernel harus disediakan.');
    end

    p = inputParser;
    p.KeepUnmatched = true;
    addRequired(p, 'img', @isnumeric);
    addRequired(p, 'filterNameOrKernel');
    addParameter(p, 'padding', 'replicate', @(x) ischar(x) || isstring(x));
    addParameter(p, 'size', 3, @isnumeric);
    addParameter(p, 'sigma', 1.0, @isnumeric);
    addParameter(p, 'variant', '8', @(x) ischar(x) || isstring(x) || isnumeric(x));
    parse(p, img, filterNameOrKernel, varargin{:});

    paddingMode = char(p.Results.padding);
    isCustomKernel = isnumeric(filterNameOrKernel);

    if isCustomKernel
        kernel = filterNameOrKernel;
        filterName = 'custom';
        kernelY = [];
    else
        filterName = lower(char(filterNameOrKernel));
        [kernel, kernelY] = getFilterKernel(filterName, ...
            'size', p.Results.size, ...
            'sigma', p.Results.sigma, ...
            'variant', p.Results.variant);
    end

    % Eksekusi konvolusi berdasarkan tipe filter
    switch filterName
        case {'sobel', 'sobel_gradient'}
            % Magnitudo gradien Sobel sqrt(Gx^2 + Gy^2)
            gx = applyConvolution2D(img, kernel, 'padding', paddingMode, 'clip', false);
            gy = applyConvolution2D(img, kernelY, 'padding', paddingMode, 'clip', false);
            mag = sqrt(double(gx).^2 + double(gy).^2);
            outputImg = uint8(max(0, min(255, round(mag))));

        case {'laplacian', 'sobel_x', 'sobel_y', 'prewitt_x', 'prewitt_y'}
            % Deteksi tepi dengan nilai absolut
            res = applyConvolution2D(img, kernel, 'padding', paddingMode, 'clip', false);
            mag = abs(double(res));
            outputImg = uint8(max(0, min(255, round(mag))));

        otherwise
            % Smoothing (mean, gaussian), penajaman (sharpen), atau kernel kustom
            outputImg = applyConvolution2D(img, kernel, 'padding', paddingMode, 'clip', true);
    end

    if nargout > 1
        info = struct();
        info.filterName = filterName;
        info.kernel = kernel;
        info.kernelY = kernelY;
        info.padding = paddingMode;
    end
end
