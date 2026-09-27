% Hitung Histogram untuk Citra Grayscale atau RGB
function varargout = computeHistogramLocal(img)
    % Validasi input
    if ~isnumeric(img)
        error('Input must be numeric array');
    end

    isColored = (size(img, 3) == 3);

    if isColored
        % Histogram RGB - ekstrak dan hitung setiap channel
        r = double(img(:, :, 1));
        g = double(img(:, :, 2));
        b = double(img(:, :, 3));

        countsR = computeHistogramChannel(r);
        countsG = computeHistogramChannel(g);
        countsB = computeHistogramChannel(b);

        varargout{1} = countsR;
        varargout{2} = countsG;
        varargout{3} = countsB;
    else
        % Histogram grayscale
        imgDouble = double(img);
        counts = computeHistogramChannel(imgDouble);

        varargout{1} = counts;
        varargout{2} = [];  % Empty untuk menandakan grayscale
        varargout{3} = [];  % Empty untuk menandakan grayscale
    end
end