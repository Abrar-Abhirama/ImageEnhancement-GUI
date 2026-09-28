% Alias untuk applyFilter
function varargout = spatialFilter(varargin)
    [varargout{1:nargout}] = applyFilter(varargin{:});
end
