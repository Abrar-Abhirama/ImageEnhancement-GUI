% Analisis sederhana karakteristik citra
function analysis = analyzeImage(img)
    % Inisialisasi output
    analysis = struct();
    analysis.issues = {};
    analysis.suggestions = {};

    % Hitung statistik
    analysis.stats = computeImageStats(img);

    % Normalisasi mean ke 0-1 jika dalam 0-255
    meanVal = analysis.stats.mean;
    if meanVal > 1
        meanVal = meanVal / 255;
    end

    dynamicRange = analysis.stats.dynamicRange;
    if dynamicRange > 1
        dynamicRange = dynamicRange / 255;
    end

    % 1. Deteksi kecerahan
    if meanVal < 0.2
        analysis.issues{end+1} = 'Citra terlalu gelap (under-exposed)';
        analysis.suggestions{end+1} = 'Power Law (gamma < 1) atau Log Transform';
    elseif meanVal > 0.8
        analysis.issues{end+1} = 'Citra terlalu terang (over-exposed)';
        analysis.suggestions{end+1} = 'Power Law (gamma > 1)';
    end

    % 2. Deteksi kontras rendah
    if dynamicRange < 0.4
        analysis.issues{end+1} = 'Kontras rendah (dynamic range sempit)';
        analysis.suggestions{end+1} = 'Contrast Stretching';
    elseif dynamicRange < 0.6
        analysis.issues{end+1} = 'Kontras sedang';
        analysis.suggestions{end+1} = 'Contrast Stretching atau Histogram Stretch';
    end

    % 3. Deteksi histogram skewness (simplified)
    if meanVal < 0.3 && dynamicRange > 0.5
        analysis.suggestions{end+1} = 'Negative Transform dapat meningkatkan detail gelap';
    end

    if isempty(analysis.issues)
        analysis.issues{end+1} = 'Tidak ada permasalahan signifikan terdeteksi';
        analysis.suggestions{end+1} = 'Citra mungkin sudah berkualitas baik';
    end
end


% Tampilkan hasil analisis ke Command Window
function printAnalysis(analysis)
    fprintf('\n');
    fprintf('========================================\n');
    fprintf('         HASIL ANALISIS CITRA\n');
    fprintf('========================================\n');

    fprintf('\nStatistik:\n');
    fprintf('  Min:        %.2f\n', analysis.stats.min);
    fprintf('  Max:        %.2f\n', analysis.stats.max);
    fprintf('  Mean:       %.2f\n', analysis.stats.mean);
    fprintf('  Std Dev:    %.2f\n', analysis.stats.std);
    fprintf('  Entropy:    %.2f\n', analysis.stats.entropy);
    fprintf('  Dyn Range:  %.2f\n', analysis.stats.dynamicRange);

    fprintf('\nPermasalahan Teridentifikasi:\n');
    for i = 1:length(analysis.issues)
        fprintf('  %d. %s\n', i, analysis.issues{i});
    end

    fprintf('\nSaran Metode Enhancement:\n');
    for i = 1:length(analysis.suggestions)
        fprintf('  %d. %s\n', i, analysis.suggestions{i});
    end

    fprintf('\n');
end