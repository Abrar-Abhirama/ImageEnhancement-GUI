% Jalankan enhancement dengan hasil terstruktur
function result = applyEnhancement(img, method, varargin)
    params = parseInputParams(varargin{:});
    result.originalImage = img;
    result.analysis = analyzeImage(img);
    result.statsBefore = computeImageStats(img);
    result.method = method;
    result.params = params;
    paramList = buildParamList(method, params);
    result.enhancedImage = intensityTransform(img, method, paramList{:});
    result.statsAfter = computeImageStats(result.enhancedImage);
    result.improvement = computeImprovement(result.statsBefore, result.statsAfter);
end


% Parse parameter input
function params = parseInputParams(varargin)
    params = struct();
    for i = 1:2:length(varargin)
        if i < length(varargin)
            paramName = varargin{i};
            paramValue = varargin{i+1};
            params.(paramName) = paramValue;
        end
    end
end


% Bangun parameter list untuk intensityTransform
function paramList = buildParamList(method, params)
    paramList = {};
    switch lower(method)
        case {'log', 'power'}
            if isfield(params, 'c')
                paramList{end+1} = 'c';
                paramList{end+1} = params.c;
            end
            if isfield(params, 'gamma')
                paramList{end+1} = 'gamma';
                paramList{end+1} = params.gamma;
            end

        case 'histogram_slide'
            if isfield(params, 'offset')
                paramList{end+1} = 'offset';
                paramList{end+1} = params.offset;
            end
    end
end


% Hitung perubahan statistik
function improvement = computeImprovement(statsBefore, statsAfter)
    improvement = struct();

    % Perubahan mean (indikator brightness)
    improvement.meanChange = statsAfter.mean - statsBefore.mean;

    % Perubahan std (indikator kontras)
    improvement.stdChange = statsAfter.std - statsBefore.std;

    % Perubahan dynamic range
    improvement.dynamicRangeChange = statsAfter.dynamicRange - statsBefore.dynamicRange;

    % Perubahan entropi
    improvement.entropyChange = statsAfter.entropy - statsBefore.entropy;

    improvement.qualityImproved = (improvement.entropyChange > 0.5) || ...
                                  (improvement.dynamicRangeChange > 10);
end


function printResultSummary(result)
    fprintf('\n');
    fprintf('========================================\n');
    fprintf('         HASIL ENHANCEMENT\n');
    fprintf('========================================\n');

    fprintf('\nMetode: %s\n', result.method);

    if ~isempty(fieldnames(result.params))
        fprintf('Parameter:\n');
        fields = fieldnames(result.params);
        for i = 1:length(fields)
            fprintf('  %s = %g\n', fields{i}, result.params.(fields{i}));
        end
    end

    fprintf('\nPerbandingan Statistik:\n');
    fprintf('%-15s %12s %12s %12s\n', 'Metrik', 'Sebelum', 'Sesudah', 'Perubahan');
    fprintf('%s\n', repmat('-', 1, 55));
    fprintf('%-15s %12.2f %12.2f %+12.2f\n', 'Mean', ...
        result.statsBefore.mean, result.statsAfter.mean, result.improvement.meanChange);
    fprintf('%-15s %12.2f %12.2f %+12.2f\n', 'Std Dev', ...
        result.statsBefore.std, result.statsAfter.std, result.improvement.stdChange);
    fprintf('%-15s %12.2f %12.2f %+12.2f\n', 'Dynamic Range', ...
        result.statsBefore.dynamicRange, result.statsAfter.dynamicRange, ...
        result.improvement.dynamicRangeChange);
    fprintf('%-15s %12.2f %12.2f %+12.2f\n', 'Entropy', ...
        result.statsBefore.entropy, result.statsAfter.entropy, ...
        result.improvement.entropyChange);

    fprintf('\n');
end