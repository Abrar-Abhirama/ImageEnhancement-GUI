function [outputImg, info] = histogramSpecification(img, refImg, varargin)
    [outputImg, info] = histogramMatching(img, refImg, varargin{:});
end
