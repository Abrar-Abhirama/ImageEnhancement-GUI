% Definisi Mask / Kernel Filtering Linier
function [kernel, kernelY] = getFilterKernel(filterType, varargin)
    if nargin < 1 || isempty(filterType)
        error('Tipe filter harus ditentukan.');
    end

    p = inputParser;
    addRequired(p, 'filterType', @(x) ischar(x) || isstring(x));
    addParameter(p, 'size', 3, @isnumeric);
    addParameter(p, 'sigma', 1.0, @isnumeric);
    addParameter(p, 'variant', '8', @(x) ischar(x) || isstring(x) || isnumeric(x));
    parse(p, filterType, varargin{:});

    kSize = p.Results.size;
    sigma = p.Results.sigma;
    variant = char(string(p.Results.variant));
    kernelY = [];

    switch lower(char(filterType))
        case {'mean', 'average', 'box'}
            % Filter Rata-rata (Box / Averaging)
            if mod(kSize, 2) == 0
                error('Ukuran kernel harus bilangan ganjil.');
            end
            kernel = ones(kSize, kSize) / (kSize * kSize);

        case 'gaussian'
            % Filter Gaussian 2D
            if mod(kSize, 2) == 0
                error('Ukuran kernel Gaussian harus ganjil.');
            end
            radius = (kSize - 1) / 2;
            [X, Y] = meshgrid(-radius:radius, -radius:radius);
            h = exp(-(X.^2 + Y.^2) / (2 * sigma^2));
            kernel = h / sum(h(:));

        case {'sharpen', 'sharpening'}
            % Filter Penajaman (Sharpening) berbasis Laplacian
            if strcmp(variant, '4')
                kernel = [
                     0, -1,  0;
                    -1,  5, -1;
                     0, -1,  0
                ];
            else
                kernel = [
                    -1, -1, -1;
                    -1,  9, -1;
                    -1, -1, -1
                ];
            end

        case 'laplacian'
            % Filter Deteksi Tepi Laplacian (Turunan Kedua)
            if strcmp(variant, '4')
                kernel = [
                     0,  1,  0;
                     1, -4,  1;
                     0,  1,  0
                ];
            else
                kernel = [
                     1,  1,  1;
                     1, -8,  1;
                     1,  1,  1
                ];
            end

        case {'sobel', 'sobel_gradient'}
            % Filter Deteksi Tepi Sobel (X dan Y)
            kernel = [
                -1,  0,  1;
                -2,  0,  2;
                -1,  0,  1
            ];
            kernelY = [
                -1, -2, -1;
                 0,  0,  0;
                 1,  2,  1
            ];

        case 'sobel_x'
            % Sobel arah horizontal
            kernel = [
                -1,  0,  1;
                -2,  0,  2;
                -1,  0,  1
            ];

        case 'sobel_y'
            % Sobel arah vertikal
            kernel = [
                -1, -2, -1;
                 0,  0,  0;
                 1,  2,  1
            ];

        case 'prewitt_x'
            % Prewitt arah horizontal
            kernel = [
                -1,  0,  1;
                -1,  0,  1;
                -1,  0,  1
            ];

        case 'prewitt_y'
            % Prewitt arah vertikal
            kernel = [
                -1, -1, -1;
                 0,  0,  0;
                 1,  1,  1
            ];

        otherwise
            error('Tipe filter tidak dikenal: %s', filterType);
    end
end
