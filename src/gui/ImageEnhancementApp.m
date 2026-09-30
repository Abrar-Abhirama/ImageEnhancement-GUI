classdef ImageEnhancementApp < matlab.apps.AppBase

    % Komponen UI
    properties (Access = public)
        UIFigure                matlab.ui.Figure
        MainGrid                matlab.ui.container.GridLayout
        
        % Panel Display Atas (Kiri: Input, Kanan: Output)
        DisplayGrid             matlab.ui.container.GridLayout
        
        % Bagian Kiri (Input)
        InputImagePanel         matlab.ui.container.Panel
        InputImageAxes          matlab.ui.control.UIAxes
        InputHistPanel          matlab.ui.container.Panel
        InputHistAxes           matlab.ui.control.UIAxes
        
        % Bagian Kanan (Output)
        OutputImagePanel        matlab.ui.container.Panel
        OutputImageAxes         matlab.ui.control.UIAxes
        OutputHistPanel         matlab.ui.container.Panel
        OutputHistAxes          matlab.ui.control.UIAxes
        
        % Panel Kontrol Bawah
        ControlPanel            matlab.ui.container.Panel
        ControlGrid             matlab.ui.container.GridLayout
        
        % Tombol File & Aksi
        LoadImageButton         matlab.ui.control.Button
        ResetButton             matlab.ui.control.Button
        EnhanceButton           matlab.ui.control.Button
        
        % Pilihan Metode Utama
        MethodDropDown          matlab.ui.control.DropDown
        
        % Kontrol Parameter Dinamis (100% Native uigridlayout)
        ParamPanel              matlab.ui.container.Panel
        ParamGrid               matlab.ui.container.GridLayout
        
        % Baris 1: Kontrol Sub-metode ATAU Pesan Utama ATAU Load Reference
        Row1Grid                matlab.ui.container.GridLayout
        ControlsRow1Grid        matlab.ui.container.GridLayout
        MainInfoLabel           matlab.ui.control.Label
        RefRow1Grid             matlab.ui.container.GridLayout
        LoadReferenceButton     matlab.ui.control.Button
        RefStatusLabel          matlab.ui.control.Label
        
        SubMethodLabel          matlab.ui.control.Label
        SubMethodDropDown       matlab.ui.control.DropDown
        
        OptionDropDownLabel     matlab.ui.control.Label
        Col4Grid                matlab.ui.container.GridLayout
        OptionDropDown          matlab.ui.control.DropDown
        CustomKernelEditField   matlab.ui.control.EditField
        
        % Baris 2: Kontrol Slider ATAU Pesan Sub-metode
        Row2Grid                matlab.ui.container.GridLayout
        SlidersGrid             matlab.ui.container.GridLayout
        SubInfoLabel            matlab.ui.control.Label
        
        Param1Label             matlab.ui.control.Label
        Param1Slider            matlab.ui.control.Slider
        Param1EditField         matlab.ui.control.NumericEditField
        
        Param2Label             matlab.ui.control.Label
        Param2Slider            matlab.ui.control.Slider
        Param2EditField         matlab.ui.control.NumericEditField
        
        StatusLabel             matlab.ui.control.Label
    end

    % Data State Aplikasi
    properties (Access = public)
        InputImage                  = []
        InputImageFileName          = ''
        InputImageFilePath          = ''
        ReferenceImage              = []
        ReferenceImageFileName      = ''
        ReferenceImageFilePath      = ''
        ReferenceHistogramCounts    = []
        ReferenceHistogramBins      = []
        OutputImage                 = []
    end

    % Callbacks & Event Handlers
    methods (Access = private)

        % Callback saat tombol Load Image ditekan
        function LoadImageButtonPushed(app, varargin)
            [file, path] = uigetfile({'*.png;*.jpg;*.jpeg;*.bmp;*.tif;*.tiff', ...
                'Image Files (*.png, *.jpg, *.jpeg, *.bmp, *.tif, *.tiff)'; ...
                '*.*', 'All Files (*.*)'}, 'Pilih Citra Input');
            if isequal(file, 0) || isequal(path, 0)
                return;
            end
            
            fullFilePath = fullfile(path, file);
            try
                img = imread(fullFilePath);
            catch ME
                uialert(app.UIFigure, ...
                    sprintf('Gagal membaca berkas citra: %s\n\nDetail error: %s', file, ME.message), ...
                    'Error Membaca Citra', 'Icon', 'error');
                return;
            end
            
            app.InputImage = img;
            app.InputImageFileName = file;
            app.InputImageFilePath = fullFilePath;
            
            % Tampilkan citra input
            cla(app.InputImageAxes);
            imshow(app.InputImage, 'Parent', app.InputImageAxes);
            title(app.InputImageAxes, sprintf('Input: %s', file), 'Interpreter', 'none');
            
            % Hitung dan tampilkan histogram input menggunakan custom function
            app.updateInputHistogram();
            
            % Reset axes output
            cla(app.OutputImageAxes);
            title(app.OutputImageAxes, 'Output Image');
            cla(app.OutputHistAxes);
            legend(app.OutputHistAxes, 'off');
            title(app.OutputHistAxes, 'Output Histogram');
            
            app.StatusLabel.Text = sprintf('Citra input berhasil dimuat: %s', file);
        end

        % Hitung & Tampilkan Histogram Input Menggunakan Custom Functions
        function updateInputHistogram(app)
            if isempty(app.InputImage)
                cla(app.InputHistAxes);
                legend(app.InputHistAxes, 'off');
                title(app.InputHistAxes, 'Input Histogram');
                return;
            end

            cla(app.InputHistAxes);
            
            if size(app.InputImage, 3) == 3
                % Citra RGB: Hitung menggunakan custom computeHistogram (computeHistogramRGB)
                [countsR, countsG, countsB, bins] = computeHistogram(app.InputImage);
                
                hold(app.InputHistAxes, 'on');
                bar(app.InputHistAxes, bins, countsR, 'FaceColor', [0.85 0.25 0.25], 'EdgeColor', 'none', 'FaceAlpha', 0.5);
                bar(app.InputHistAxes, bins, countsG, 'FaceColor', [0.25 0.75 0.25], 'EdgeColor', 'none', 'FaceAlpha', 0.5);
                bar(app.InputHistAxes, bins, countsB, 'FaceColor', [0.25 0.45 0.85], 'EdgeColor', 'none', 'FaceAlpha', 0.5);
                hold(app.InputHistAxes, 'off');
                
                xlim(app.InputHistAxes, [0 255]);
                legend(app.InputHistAxes, {'Red', 'Green', 'Blue'}, 'Location', 'northeast');
                title(app.InputHistAxes, 'Input Histogram (RGB)');
                xlabel(app.InputHistAxes, 'Intensity');
                ylabel(app.InputHistAxes, 'Frequency');
                grid(app.InputHistAxes, 'on');
            else
                % Citra Grayscale: Hitung menggunakan custom computeHistogram (computeHistogramGrayscale)
                [counts, bins] = computeHistogram(app.InputImage);
                
                legend(app.InputHistAxes, 'off');
                bar(app.InputHistAxes, bins, counts, 'FaceColor', [0.35 0.35 0.35], 'EdgeColor', 'none', 'FaceAlpha', 0.85);
                
                xlim(app.InputHistAxes, [0 255]);
                title(app.InputHistAxes, 'Input Histogram (Grayscale)');
                xlabel(app.InputHistAxes, 'Intensity');
                ylabel(app.InputHistAxes, 'Frequency');
                grid(app.InputHistAxes, 'on');
            end
        end

        % Callback saat tombol Load Reference ditekan (khusus Histogram Matching)
        function LoadReferenceButtonPushed(app, varargin)
            [file, path] = uigetfile({'*.png;*.jpg;*.jpeg;*.bmp;*.tif;*.tiff', ...
                'Image Files (*.png, *.jpg, *.jpeg, *.bmp, *.tif, *.tiff)'; ...
                '*.*', 'All Files (*.*)'}, 'Pilih Citra Referensi');
            if isequal(file, 0) || isequal(path, 0)
                return;
            end
            
            fullFilePath = fullfile(path, file);
            try
                img = imread(fullFilePath);
            catch ME
                uialert(app.UIFigure, ...
                    sprintf('Gagal membaca berkas citra referensi: %s\n\nDetail error: %s', file, ME.message), ...
                    'Error Membaca Citra Referensi', 'Icon', 'error');
                return;
            end
            
            app.ReferenceImage = img;
            app.ReferenceImageFileName = file;
            app.ReferenceImageFilePath = fullFilePath;
            
            % Hitung histogram referensi menggunakan custom function (tanpa imhist)
            if size(app.ReferenceImage, 3) == 3
                [countsR, countsG, countsB, bins] = computeHistogram(app.ReferenceImage);
                app.ReferenceHistogramCounts = {countsR, countsG, countsB};
                app.ReferenceHistogramBins = bins;
                channelDesc = 'RGB';
            else
                [counts, bins] = computeHistogram(app.ReferenceImage);
                app.ReferenceHistogramCounts = counts;
                app.ReferenceHistogramBins = bins;
                channelDesc = 'Grayscale';
            end
            
            app.RefStatusLabel.Text = sprintf('Reference: %s', file);
            app.SubInfoLabel.Text = sprintf('Reference histogram calculated (%s). Ready for matching.', channelDesc);
            app.StatusLabel.Text = sprintf('Citra referensi dimuat: %s (%s, histogram referensi siap)', file, channelDesc);
        end

        % Callback saat metode utama diganti
        function MethodDropDownValueChanged(app, varargin)
            selectedMethod = app.MethodDropDown.Value;
            app.updateParameterControls(selectedMethod);
        end

        % Callback saat sub-metode diganti
        function SubMethodDropDownValueChanged(app, varargin)
            selectedMethod = app.MethodDropDown.Value;
            selectedSub = app.SubMethodDropDown.Value;
            if strcmp(selectedMethod, 'Histogram Equalization')
                app.updateHistogramEqualizationParams(selectedSub);
            else
                app.updateSubMethodParams(selectedMethod, selectedSub);
            end
        end

        % Update visibilitas parameter sesuai metode utama
        function updateParameterControls(app, method)
            switch method
                case 'Intensity Transformation'
                    app.Row1Grid.ColumnWidth = {'1x', 0, 0};
                    app.ControlsRow1Grid.Visible = 'on';
                    app.MainInfoLabel.Visible = 'off';
                    app.RefRow1Grid.Visible = 'off';
                    app.LoadReferenceButton.Visible = 'off';
                    app.RefStatusLabel.Visible = 'off';
                    app.SubMethodLabel.Text = 'Transform:';
                    app.SubMethodDropDown.Items = {'Brightness Adjustment', 'Contrast Correction', 'Negative', 'Log', 'Power (Gamma)', 'Contrast Stretching'};
                    if ~ismember(app.SubMethodDropDown.Value, app.SubMethodDropDown.Items)
                        app.SubMethodDropDown.Value = 'Power (Gamma)';
                    end
                    app.updateSubMethodParams(method, app.SubMethodDropDown.Value);

                case 'Histogram Equalization'
                    app.Row1Grid.ColumnWidth = {'1x', 0, 0};
                    app.ControlsRow1Grid.Visible = 'on';
                    app.MainInfoLabel.Visible = 'off';
                    app.RefRow1Grid.Visible = 'off';
                    app.LoadReferenceButton.Visible = 'off';
                    app.RefStatusLabel.Visible = 'off';
                    app.SubMethodLabel.Text = 'Mode:';
                    app.SubMethodDropDown.Items = {'Global', 'HSV', 'YCbCr'};
                    if ~ismember(app.SubMethodDropDown.Value, app.SubMethodDropDown.Items)
                        app.SubMethodDropDown.Value = 'Global';
                    end
                    app.updateHistogramEqualizationParams(app.SubMethodDropDown.Value);

                case 'Histogram Matching'
                    app.Row1Grid.ColumnWidth = {0, 0, '1x'};
                    app.ControlsRow1Grid.Visible = 'off';
                    app.MainInfoLabel.Visible = 'off';
                    app.RefRow1Grid.Visible = 'on';
                    app.LoadReferenceButton.Visible = 'on';
                    app.RefStatusLabel.Visible = 'on';
                    app.Row2Grid.ColumnWidth = {0, '1x'};
                    app.SlidersGrid.Visible = 'off';
                    app.SubInfoLabel.Visible = 'on';
                    if isempty(app.ReferenceImage)
                        app.RefStatusLabel.Text = 'Reference: (None loaded)';
                        app.SubInfoLabel.Text = 'Reference image required. Click "Load Reference" above.';
                    else
                        app.RefStatusLabel.Text = sprintf('Reference: %s', app.ReferenceImageFileName);
                        if size(app.ReferenceImage, 3) == 3
                            app.SubInfoLabel.Text = 'Reference histogram calculated (RGB). Ready for matching.';
                        else
                            app.SubInfoLabel.Text = 'Reference histogram calculated (Grayscale). Ready for matching.';
                        end
                    end

                case 'Linear Filtering'
                    app.Row1Grid.ColumnWidth = {'1x', 0, 0};
                    app.ControlsRow1Grid.Visible = 'on';
                    app.MainInfoLabel.Visible = 'off';
                    app.RefRow1Grid.Visible = 'off';
                    app.LoadReferenceButton.Visible = 'off';
                    app.RefStatusLabel.Visible = 'off';
                    app.SubMethodLabel.Text = 'Kernel:';
                    app.SubMethodDropDown.Items = {'Gaussian', 'Mean (Box)', 'Sharpen', 'Sobel', 'Laplacian', 'Custom'};
                    if ~ismember(app.SubMethodDropDown.Value, app.SubMethodDropDown.Items)
                        app.SubMethodDropDown.Value = 'Gaussian';
                    end
                    app.updateSubMethodParams(method, app.SubMethodDropDown.Value);

                case 'Median Filtering'
                    app.Row1Grid.ColumnWidth = {'1x', 0, 0};
                    app.ControlsRow1Grid.Visible = 'on';
                    app.MainInfoLabel.Visible = 'off';
                    app.RefRow1Grid.Visible = 'off';
                    app.LoadReferenceButton.Visible = 'off';
                    app.RefStatusLabel.Visible = 'off';
                    app.SubMethodLabel.Text = 'Window Size:';
                    app.SubMethodDropDown.Items = {'3x3', '5x5', '7x7'};
                    if ~ismember(app.SubMethodDropDown.Value, app.SubMethodDropDown.Items)
                        app.SubMethodDropDown.Value = '3x3';
                    end
                    app.OptionDropDownLabel.Visible = 'on';
                    app.OptionDropDownLabel.Text = 'Padding:';
                    app.Col4Grid.ColumnWidth = {'1x', 0};
                    app.OptionDropDown.Visible = 'on';
                    app.OptionDropDown.Items = {'replicate', 'zero', 'symmetric'};
                    app.OptionDropDown.Value = 'replicate';
                    app.CustomKernelEditField.Visible = 'off';
                    app.Row2Grid.ColumnWidth = {0, '1x'};
                    app.SlidersGrid.Visible = 'off';
                    app.SubInfoLabel.Visible = 'on';
                    app.SubInfoLabel.Text = 'Non-linear median filtering for salt-and-pepper noise.';
            end
        end

        % Update slider dan kontrol berdasarkan sub-metode
        function updateSubMethodParams(app, method, subMethod)
            switch method
                case 'Intensity Transformation'
                    app.OptionDropDownLabel.Visible = 'off';
                    app.Col4Grid.ColumnWidth = {0, 0};
                    app.OptionDropDown.Visible = 'off';
                    app.CustomKernelEditField.Visible = 'off';

                    switch subMethod
                        case 'Brightness Adjustment'
                            app.Row2Grid.ColumnWidth = {'1x', 0};
                            app.SlidersGrid.Visible = 'on';
                            app.SubInfoLabel.Visible = 'off';
                            app.Param1Label.Visible = 'on';
                            app.Param1Label.Text = 'Brightness:';
                            app.Param1Slider.Visible = 'on';
                            app.Param1Slider.Limits = [-1, 1];
                            app.Param1Slider.Value = 0;
                            app.Param1EditField.Visible = 'on';
                            app.Param1EditField.Value = 0;
                            app.Param2Label.Visible = 'off';
                            app.Param2Slider.Visible = 'off';
                            app.Param2EditField.Visible = 'off';

                        case 'Contrast Correction'
                            app.Row2Grid.ColumnWidth = {'1x', 0};
                            app.SlidersGrid.Visible = 'on';
                            app.SubInfoLabel.Visible = 'off';
                            app.Param1Label.Visible = 'on';
                            app.Param1Label.Text = 'Contrast (c):';
                            app.Param1Slider.Visible = 'on';
                            app.Param1Slider.Limits = [0, 2];
                            app.Param1Slider.Value = 1;
                            app.Param1EditField.Visible = 'on';
                            app.Param1EditField.Value = 1;
                            app.Param2Label.Visible = 'off';
                            app.Param2Slider.Visible = 'off';
                            app.Param2EditField.Visible = 'off';
                        case 'Negative'
                            app.Row2Grid.ColumnWidth = {0, '1x'};
                            app.SlidersGrid.Visible = 'off';
                            app.SubInfoLabel.Visible = 'on';
                            app.SubInfoLabel.Text = 'No additional parameters required.';

                        case 'Log'
                            app.Row2Grid.ColumnWidth = {'1x', 0};
                            app.SlidersGrid.Visible = 'on';
                            app.SubInfoLabel.Visible = 'off';
                            app.Param1Label.Visible = 'on';
                            app.Param1Label.Text = 'c (Constant):';
                            app.Param1Slider.Visible = 'on';
                            app.Param1Slider.Limits = [0.1, 3.0];
                            app.Param1Slider.Value = 1.0;
                            app.Param1EditField.Visible = 'on';
                            app.Param1EditField.Value = 1.0;
                            app.Param2Label.Visible = 'off';
                            app.Param2Slider.Visible = 'off';
                            app.Param2EditField.Visible = 'off';

                        case 'Power (Gamma)'
                            app.Row2Grid.ColumnWidth = {'1x', 0};
                            app.SlidersGrid.Visible = 'on';
                            app.SubInfoLabel.Visible = 'off';
                            app.Param1Label.Visible = 'on';
                            app.Param1Label.Text = 'Gamma:';
                            app.Param1Slider.Visible = 'on';
                            app.Param1Slider.Limits = [0.1, 5.0];
                            app.Param1Slider.Value = 1.0;
                            app.Param1EditField.Visible = 'on';
                            app.Param1EditField.Value = 1.0;
                            app.Param2Label.Visible = 'on';
                            app.Param2Label.Text = 'c (Constant):';
                            app.Param2Slider.Visible = 'on';
                            app.Param2Slider.Limits = [0.1, 3.0];
                            app.Param2Slider.Value = 1.0;
                            app.Param2EditField.Visible = 'on';
                            app.Param2EditField.Value = 1.0;

                        case 'Contrast Stretching'
                            app.Row2Grid.ColumnWidth = {0, '1x'};
                            app.SlidersGrid.Visible = 'off';
                            app.SubInfoLabel.Visible = 'on';
                            app.SubInfoLabel.Text = 'No additional parameters required.';
                    end

                case 'Linear Filtering'
                    switch subMethod
                        case 'Gaussian'
                            app.OptionDropDownLabel.Visible = 'on';
                            app.OptionDropDownLabel.Text = 'Kernel Size:';
                            app.Col4Grid.ColumnWidth = {'1x', 0};
                            app.OptionDropDown.Visible = 'on';
                            app.OptionDropDown.Items = {'3x3', '5x5', '7x7'};
                            app.OptionDropDown.Value = '5x5';
                            app.CustomKernelEditField.Visible = 'off';

                            app.Row2Grid.ColumnWidth = {'1x', 0};
                            app.SlidersGrid.Visible = 'on';
                            app.SubInfoLabel.Visible = 'off';
                            app.Param1Label.Visible = 'on';
                            app.Param1Label.Text = 'Sigma (\sigma):';
                            app.Param1Slider.Visible = 'on';
                            app.Param1Slider.Limits = [0.1, 5.0];
                            app.Param1Slider.Value = 1.0;
                            app.Param1EditField.Visible = 'on';
                            app.Param1EditField.Value = 1.0;
                            app.Param2Label.Visible = 'off';
                            app.Param2Slider.Visible = 'off';
                            app.Param2EditField.Visible = 'off';

                        case 'Mean (Box)'
                            app.OptionDropDownLabel.Visible = 'on';
                            app.OptionDropDownLabel.Text = 'Kernel Size:';
                            app.Col4Grid.ColumnWidth = {'1x', 0};
                            app.OptionDropDown.Visible = 'on';
                            app.OptionDropDown.Items = {'3x3', '5x5', '7x7'};
                            app.OptionDropDown.Value = '3x3';
                            app.CustomKernelEditField.Visible = 'off';

                            app.Row2Grid.ColumnWidth = {0, '1x'};
                            app.SlidersGrid.Visible = 'off';
                            app.SubInfoLabel.Visible = 'on';
                            app.SubInfoLabel.Text = 'Box blur averaging filter.';

                        case {'Sharpen', 'Laplacian'}
                            app.OptionDropDownLabel.Visible = 'on';
                            app.OptionDropDownLabel.Text = 'Variant:';
                            app.Col4Grid.ColumnWidth = {'1x', 0};
                            app.OptionDropDown.Visible = 'on';
                            app.OptionDropDown.Items = {'8-neighbor', '4-neighbor'};
                            app.OptionDropDown.Value = '8-neighbor';
                            app.CustomKernelEditField.Visible = 'off';

                            app.Row2Grid.ColumnWidth = {0, '1x'};
                            app.SlidersGrid.Visible = 'off';
                            app.SubInfoLabel.Visible = 'on';
                            app.SubInfoLabel.Text = 'Second-derivative high-pass filter.';

                        case 'Sobel'
                            app.OptionDropDownLabel.Visible = 'off';
                            app.Col4Grid.ColumnWidth = {0, 0};
                            app.OptionDropDown.Visible = 'off';
                            app.CustomKernelEditField.Visible = 'off';

                            app.Row2Grid.ColumnWidth = {0, '1x'};
                            app.SlidersGrid.Visible = 'off';
                            app.SubInfoLabel.Visible = 'on';
                            app.SubInfoLabel.Text = 'Standard 3x3 Sobel gradient magnitude (Gx & Gy).';

                        case 'Custom'
                            app.OptionDropDownLabel.Visible = 'on';
                            app.OptionDropDownLabel.Text = 'Matrix:';
                            app.Col4Grid.ColumnWidth = {0, '1x'};
                            app.OptionDropDown.Visible = 'off';
                            app.CustomKernelEditField.Visible = 'on';
                            app.CustomKernelEditField.Value = '[0 -1 0; -1 5 -1; 0 -1 0]';

                            app.Row2Grid.ColumnWidth = {0, '1x'};
                            app.SlidersGrid.Visible = 'off';
                            app.SubInfoLabel.Visible = 'on';
                            app.SubInfoLabel.Text = 'Enter custom NxN convolution kernel matrix.';
                    end

                case 'Median Filtering'
                    app.Row2Grid.ColumnWidth = {0, '1x'};
                    app.SlidersGrid.Visible = 'off';
                    app.SubInfoLabel.Visible = 'on';
                    app.SubInfoLabel.Text = 'Non-linear median filtering for salt-and-pepper noise.';
            end
        end

        % Update parameter controls untuk Histogram Equalization
        function updateHistogramEqualizationParams(app, mode)
            app.OptionDropDownLabel.Visible = 'off';
            app.Col4Grid.ColumnWidth = {0, 0};
            app.OptionDropDown.Visible = 'off';
            app.CustomKernelEditField.Visible = 'off';

            app.Row2Grid.ColumnWidth = {0, '1x'};
            app.SlidersGrid.Visible = 'off';
            app.SubInfoLabel.Visible = 'on';

            switch lower(mode)
                case 'global'
                    app.SubInfoLabel.Text = 'Equalize all channels independently. Suitable for grayscale images.';
                case 'hsv'
                    app.SubInfoLabel.Text = 'Equalize Value channel only. Preserves hue and saturation for color images.';
                case 'ycbcr'
                    app.SubInfoLabel.Text = 'Equalize Luminance (Y) channel only. Preserves color while adjusting brightness.';
            end
        end

        % Sinkronisasi Slider 1 ke EditField 1
        function Param1SliderValueChanged(app, varargin)
            app.Param1EditField.Value = app.Param1Slider.Value;
        end

        % Sinkronisasi EditField 1 ke Slider 1
        function Param1EditFieldValueChanged(app, varargin)
            val = app.Param1EditField.Value;
            val = min(max(val, app.Param1Slider.Limits(1)), app.Param1Slider.Limits(2));
            app.Param1Slider.Value = val;
            app.Param1EditField.Value = val;
        end

        % Sinkronisasi Slider 2 ke EditField 2
        function Param2SliderValueChanged(app, varargin)
            app.Param2EditField.Value = app.Param2Slider.Value;
        end

        % Sinkronisasi EditField 2 ke Slider 2
        function Param2EditFieldValueChanged(app, varargin)
            val = app.Param2EditField.Value;
            val = min(max(val, app.Param2Slider.Limits(1)), app.Param2Slider.Limits(2));
            app.Param2Slider.Value = val;
            app.Param2EditField.Value = val;
        end

        % Hitung & Tampilkan Histogram Output Menggunakan Custom Functions
        function updateOutputHistogram(app)
            if isempty(app.OutputImage)
                cla(app.OutputHistAxes);
                legend(app.OutputHistAxes, 'off');
                title(app.OutputHistAxes, 'Output Histogram');
                return;
            end

            cla(app.OutputHistAxes);
            
            if size(app.OutputImage, 3) == 3
                % Citra RGB: Hitung menggunakan custom computeHistogram (computeHistogramRGB)
                [countsR, countsG, countsB, bins] = computeHistogram(app.OutputImage);
                
                hold(app.OutputHistAxes, 'on');
                bar(app.OutputHistAxes, bins, countsR, 'FaceColor', [0.85 0.25 0.25], 'EdgeColor', 'none', 'FaceAlpha', 0.5);
                bar(app.OutputHistAxes, bins, countsG, 'FaceColor', [0.25 0.75 0.25], 'EdgeColor', 'none', 'FaceAlpha', 0.5);
                bar(app.OutputHistAxes, bins, countsB, 'FaceColor', [0.25 0.45 0.85], 'EdgeColor', 'none', 'FaceAlpha', 0.5);
                hold(app.OutputHistAxes, 'off');
                
                xlim(app.OutputHistAxes, [0 255]);
                legend(app.OutputHistAxes, {'Red', 'Green', 'Blue'}, 'Location', 'northeast');
                title(app.OutputHistAxes, 'Output Histogram (RGB)');
                xlabel(app.OutputHistAxes, 'Intensity');
                ylabel(app.OutputHistAxes, 'Frequency');
                grid(app.OutputHistAxes, 'on');
            else
                % Citra Grayscale: Hitung menggunakan custom computeHistogram (computeHistogramGrayscale)
                [counts, bins] = computeHistogram(app.OutputImage);
                
                legend(app.OutputHistAxes, 'off');
                bar(app.OutputHistAxes, bins, counts, 'FaceColor', [0.35 0.35 0.35], 'EdgeColor', 'none', 'FaceAlpha', 0.85);
                
                xlim(app.OutputHistAxes, [0 255]);
                title(app.OutputHistAxes, 'Output Histogram (Grayscale)');
                xlabel(app.OutputHistAxes, 'Intensity');
                ylabel(app.OutputHistAxes, 'Frequency');
                grid(app.OutputHistAxes, 'on');
            end
        end

        % Callback saat tombol Enhance ditekan
        function EnhanceButtonPushed(app, varargin)
            % 1. Validasi Citra Input
            if isempty(app.InputImage)
                uialert(app.UIFigure, 'Silakan muat citra input terlebih dahulu sebelum melakukan enhancement.', ...
                    'Citra Belum Dimuat', 'Icon', 'warning');
                return;
            end
            
            selectedMethod = app.MethodDropDown.Value;
            
            % Tampilkan status memproses
            app.StatusLabel.Text = sprintf('Memproses %s...', selectedMethod);
            drawnow;
            
            try
                switch selectedMethod
                    case 'Intensity Transformation'
                        subMethod = app.SubMethodDropDown.Value;
                        switch subMethod
                            case 'Brightness Adjustment'
                                brightnessVal = app.Param1EditField.Value;
                                if isempty(brightnessVal) || isnan(brightnessVal)
                                    uialert(app.UIFigure, 'Nilai Brightness harus berupa angka antara -1 dan 1.', ...
                                        'Parameter Tidak Valid', 'Icon', 'warning');
                                    app.StatusLabel.Text = 'Gagal: Parameter Brightness tidak valid.';
                                    return;
                                end
                                outImg = intensityTransform(app.InputImage, 'brightness_adjustment', 'brightness', brightnessVal);
                                titleStr = sprintf('Output: Brightness Adjustment (b=%.2f)', brightnessVal);
                                statusMsg = sprintf('Intensity Transformation (Brightness Adjustment, b=%.2f) selesai.', brightnessVal);

                            case 'Contrast Correction'
                                contrastVal = app.Param1EditField.Value;
                                if isempty(contrastVal) || isnan(contrastVal)
                                    uialert(app.UIFigure, 'Nilai Contrast harus berupa angka antara 0 dan 2.', ...
                                        'Parameter Tidak Valid', 'Icon', 'warning');
                                    app.StatusLabel.Text = 'Gagal: Parameter Contrast tidak valid.';
                                    return;
                                end
                                outImg = intensityTransform(app.InputImage, 'contrast_correction', 'contrast', contrastVal);
                                titleStr = sprintf('Output: Contrast Correction (c=%.2f)', contrastVal);
                                statusMsg = sprintf('Intensity Transformation (Contrast Correction, c=%.2f) selesai.', contrastVal);
                                
                            case 'Negative'
                                outImg = intensityTransform(app.InputImage, 'negative');
                                titleStr = 'Output: Negative';
                                statusMsg = 'Intensity Transformation (Negative) selesai.';
                                
                            case 'Log'
                                cVal = app.Param1EditField.Value;
                                if isempty(cVal) || isnan(cVal) || cVal <= 0
                                    uialert(app.UIFigure, 'Konstanta c harus berupa angka positif (> 0).', ...
                                        'Parameter Tidak Valid', 'Icon', 'warning');
                                    app.StatusLabel.Text = 'Gagal: Parameter c tidak valid.';
                                    return;
                                end
                                outImg = intensityTransform(app.InputImage, 'log', 'c', cVal);
                                titleStr = sprintf('Output: Log (c=%.2f)', cVal);
                                statusMsg = sprintf('Intensity Transformation (Log, c=%.2f) selesai.', cVal);
                                
                            case 'Power (Gamma)'
                                gammaVal = app.Param1EditField.Value;
                                cVal = app.Param2EditField.Value;
                                if isempty(gammaVal) || isnan(gammaVal) || gammaVal <= 0 || ...
                                   isempty(cVal) || isnan(cVal) || cVal <= 0
                                    uialert(app.UIFigure, 'Nilai Gamma dan konstanta c harus berupa angka positif (> 0).', ...
                                        'Parameter Tidak Valid', 'Icon', 'warning');
                                    app.StatusLabel.Text = 'Gagal: Parameter Gamma / c tidak valid.';
                                    return;
                                end
                                outImg = intensityTransform(app.InputImage, 'power', 'c', cVal, 'gamma', gammaVal);
                                titleStr = sprintf('Output: Power (\\gamma=%.2f, c=%.2f)', gammaVal, cVal);
                                statusMsg = sprintf('Intensity Transformation (Power, \\gamma=%.2f, c=%.2f) selesai.', gammaVal, cVal);
                                
                            case 'Contrast Stretching'
                                outImg = intensityTransform(app.InputImage, 'contrast');
                                titleStr = 'Output: Contrast Stretching';
                                statusMsg = 'Intensity Transformation (Contrast Stretching) selesai.';

                            otherwise
                                error('Transformasi tidak dikenal: %s', subMethod);
                        end
                        
                    case 'Histogram Equalization'
                        mode = app.SubMethodDropDown.Value;
                        % Convert mode name to lowercase for function call
                        switch lower(mode)
                            case 'global'
                                modeStr = 'global';
                            case 'hsv'
                                modeStr = 'hsv';
                            case 'ycbcr'
                                modeStr = 'ycbcr';
                        end
                        outImg = histogramEqualization(app.InputImage, 'mode', modeStr);
                        titleStr = sprintf('Output: Histogram Equalization (%s)', mode);
                        statusMsg = sprintf('Histogram Equalization (%s) selesai.', mode);
                        
                    case 'Histogram Matching'
                        % 1. Validasi keberadaan Citra Referensi
                        if isempty(app.ReferenceImage)
                            uialert(app.UIFigure, 'Please load a reference image first.', ...
                                'Citra Referensi Belum Dimuat', 'Icon', 'warning');
                            app.StatusLabel.Text = 'Gagal: Citra referensi belum dimuat.';
                            return;
                        end
                        
                        % 2. Validasi kompatibilitas citra
                        if ~isnumeric(app.InputImage) || isempty(app.InputImage)
                            uialert(app.UIFigure, 'Citra input harus berupa data numerik yang valid.', ...
                                'Kompatibilitas Citra', 'Icon', 'error');
                            app.StatusLabel.Text = 'Gagal: Format citra input tidak valid.';
                            return;
                        end
                        
                        if ~isnumeric(app.ReferenceImage) || isempty(app.ReferenceImage)
                            uialert(app.UIFigure, 'Citra referensi harus berupa data numerik yang valid.', ...
                                'Kompatibilitas Citra', 'Icon', 'error');
                            app.StatusLabel.Text = 'Gagal: Format citra referensi tidak valid.';
                            return;
                        end
                        
                        if ndims(app.InputImage) > 3 || (ndims(app.InputImage) == 3 && size(app.InputImage, 3) ~= 3)
                            uialert(app.UIFigure, 'Dimensi citra input tidak didukung. Citra harus 2D (grayscale) atau 3D (RGB 3-kanal).', ...
                                'Dimensi Citra Tidak Kompatibel', 'Icon', 'error');
                            app.StatusLabel.Text = 'Gagal: Dimensi citra input tidak kompatibel.';
                            return;
                        end
                        
                        if ndims(app.ReferenceImage) > 3 || (ndims(app.ReferenceImage) == 3 && size(app.ReferenceImage, 3) ~= 3)
                            uialert(app.UIFigure, 'Dimensi citra referensi tidak didukung. Citra harus 2D (grayscale) atau 3D (RGB 3-kanal).', ...
                                'Dimensi Citra Tidak Kompatibel', 'Icon', 'error');
                            app.StatusLabel.Text = 'Gagal: Dimensi citra referensi tidak kompatibel.';
                            return;
                        end
                        
                        % 3. Panggil fungsi Histogram Matching eksisting
                        outImg = histogramMatching(app.InputImage, app.ReferenceImage);
                        
                        if ~isempty(app.ReferenceImageFileName)
                            titleStr = sprintf('Output: Matched to %s', app.ReferenceImageFileName);
                            statusMsg = sprintf('Histogram Matching selesai (Target: %s).', app.ReferenceImageFileName);
                        else
                            titleStr = 'Output: Histogram Matching';
                            statusMsg = 'Histogram Matching selesai.';
                        end
                        
                    case 'Linear Filtering'
                        subMethod = app.SubMethodDropDown.Value;
                        switch subMethod
                            case 'Gaussian'
                                kSizeArr = sscanf(app.OptionDropDown.Value, '%dx%d');
                                if isempty(kSizeArr)
                                    kSize = 5;
                                else
                                    kSize = kSizeArr(1);
                                end
                                sigmaVal = app.Param1EditField.Value;
                                if isempty(sigmaVal) || isnan(sigmaVal) || sigmaVal <= 0
                                    uialert(app.UIFigure, 'Nilai Sigma (\sigma) harus berupa angka positif (> 0).', ...
                                        'Parameter Tidak Valid', 'Icon', 'warning');
                                    app.StatusLabel.Text = 'Gagal: Parameter Sigma tidak valid.';
                                    return;
                                end
                                outImg = linearFilter(app.InputImage, 'gaussian', 'size', kSize, 'sigma', sigmaVal);
                                titleStr = sprintf('Output: Gaussian Filter (%dx%d, \\sigma=%.2f)', kSize, kSize, sigmaVal);
                                statusMsg = sprintf('Linear Filtering (Gaussian %dx%d, \\sigma=%.2f) selesai.', kSize, kSize, sigmaVal);
                                
                            case 'Mean (Box)'
                                kSizeArr = sscanf(app.OptionDropDown.Value, '%dx%d');
                                if isempty(kSizeArr)
                                    kSize = 3;
                                else
                                    kSize = kSizeArr(1);
                                end
                                outImg = linearFilter(app.InputImage, 'mean', 'size', kSize);
                                titleStr = sprintf('Output: Mean Filter (%dx%d)', kSize, kSize);
                                statusMsg = sprintf('Linear Filtering (Mean %dx%d) selesai.', kSize, kSize);
                                
                            case 'Sharpen'
                                varStr = '8';
                                if contains(app.OptionDropDown.Value, '4')
                                    varStr = '4';
                                end
                                outImg = linearFilter(app.InputImage, 'sharpen', 'variant', varStr);
                                titleStr = sprintf('Output: Sharpen Filter (%s)', app.OptionDropDown.Value);
                                statusMsg = sprintf('Linear Filtering (Sharpen %s) selesai.', app.OptionDropDown.Value);
                                
                            case 'Sobel'
                                outImg = linearFilter(app.InputImage, 'sobel');
                                titleStr = 'Output: Sobel Gradient Magnitude';
                                statusMsg = 'Linear Filtering (Sobel) selesai.';
                                
                            case 'Laplacian'
                                varStr = '8';
                                if contains(app.OptionDropDown.Value, '4')
                                    varStr = '4';
                                end
                                outImg = linearFilter(app.InputImage, 'laplacian', 'variant', varStr);
                                titleStr = sprintf('Output: Laplacian Filter (%s)', app.OptionDropDown.Value);
                                statusMsg = sprintf('Linear Filtering (Laplacian %s) selesai.', app.OptionDropDown.Value);
                                
                            case 'Custom'
                                rawKernelStr = app.CustomKernelEditField.Value;
                                rawKernel = str2num(rawKernelStr); %#ok<ST2NM>
                                if isempty(rawKernel) || ~isnumeric(rawKernel) || ndims(rawKernel) > 2
                                    uialert(app.UIFigure, ...
                                        'Format matriks kernel kustom tidak valid. Masukkan matriks numerik 2D, contoh: [0 -1 0; -1 5 -1; 0 -1 0]', ...
                                        'Kernel Kustom Tidak Valid', 'Icon', 'warning');
                                    app.StatusLabel.Text = 'Gagal: Format matriks kernel kustom tidak valid.';
                                    return;
                                end
                                [kh, kw] = size(rawKernel);
                                if mod(kh, 2) == 0 || mod(kw, 2) == 0
                                    uialert(app.UIFigure, ...
                                        sprintf('Dimensi kernel harus ganjil (contoh: 3x3, 5x5). Dimensi saat ini: %dx%d.', kh, kw), ...
                                        'Dimensi Kernel Tidak Valid', 'Icon', 'warning');
                                    app.StatusLabel.Text = 'Gagal: Dimensi kernel kustom harus ganjil.';
                                    return;
                                end
                                outImg = linearFilter(app.InputImage, rawKernel);
                                titleStr = sprintf('Output: Custom Kernel (%dx%d)', kh, kw);
                                statusMsg = sprintf('Linear Filtering (Custom Kernel %dx%d) selesai.', kh, kw);
                                
                            otherwise
                                error('Kernel "%s" tidak dikenali.', subMethod);
                        end
                        
                    case 'Median Filtering'
                        % 1. Ekstrak dan validasi Window Size
                        rawWinSize = app.SubMethodDropDown.Value;
                        wSizeArr = sscanf(rawWinSize, '%dx%d');
                        if isempty(wSizeArr)
                            wSizeArr = str2double(rawWinSize);
                        end
                        
                        if isempty(wSizeArr) || isnan(wSizeArr(1)) || mod(wSizeArr(1), 2) == 0 || wSizeArr(1) < 1
                            uialert(app.UIFigure, ...
                                'Ukuran window median filter harus berupa bilangan ganjil (contoh: 3x3, 5x5, 7x7).', ...
                                'Ukuran Window Tidak Valid', 'Icon', 'warning');
                            app.StatusLabel.Text = 'Gagal: Ukuran window median filter tidak valid.';
                            return;
                        end
                        wSize = wSizeArr(1);
                        
                        % 2. Baca mode padding
                        paddingMode = app.OptionDropDown.Value;
                        if isempty(paddingMode)
                            paddingMode = 'replicate';
                        end
                        
                        % 3. Panggil fungsi median filter manual eksisting
                        outImg = medianFilter(app.InputImage, 'size', wSize, 'padding', paddingMode);
                        
                        titleStr = sprintf('Output: Median Filter (%dx%d, %s)', wSize, wSize, paddingMode);
                        statusMsg = sprintf('Median Filtering (%dx%d, padding: %s) selesai.', wSize, wSize, paddingMode);
                        
                    otherwise
                        uialert(app.UIFigure, ...
                            sprintf('Metode "%s" belum dihubungkan pada tahap ini.', selectedMethod), ...
                            'Informasi', 'Icon', 'info');
                        app.StatusLabel.Text = sprintf('Metode %s siap dihubungkan pada langkah berikutnya.', selectedMethod);
                        return;
                end
                
                % Simpan hasil ke properti aplikasi
                app.OutputImage = outImg;
                
                % Tampilkan Citra Output
                cla(app.OutputImageAxes);
                imshow(app.OutputImage, 'Parent', app.OutputImageAxes);
                title(app.OutputImageAxes, titleStr, 'Interpreter', 'none');
                
                % Hitung & Tampilkan Histogram Output
                app.updateOutputHistogram();
                
                % Perbarui Status Bar
                app.StatusLabel.Text = statusMsg;
                
            catch ME
                uialert(app.UIFigure, ...
                    sprintf('Terjadi kesalahan saat menjalankan enhancement:\n\n%s', ME.message), ...
                    'Error Enhancement', 'Icon', 'error');
                app.StatusLabel.Text = sprintf('Error: %s', ME.message);
            end
        end

        % Callback saat tombol Reset ditekan
        function ResetButtonPushed(app, varargin)
            if ~isempty(app.InputImage)
                cla(app.InputImageAxes);
                imshow(app.InputImage, 'Parent', app.InputImageAxes);
                if ~isempty(app.InputImageFileName)
                    title(app.InputImageAxes, sprintf('Input: %s', app.InputImageFileName), 'Interpreter', 'none');
                else
                    title(app.InputImageAxes, 'Input Image');
                end
                app.updateInputHistogram();
                
                cla(app.OutputImageAxes);
                title(app.OutputImageAxes, 'Output Image');
                cla(app.OutputHistAxes);
                legend(app.OutputHistAxes, 'off');
                title(app.OutputHistAxes, 'Output Histogram');
                app.OutputImage = [];
                app.StatusLabel.Text = 'Tampilan direset ke citra awal.';
            end
        end
    end

    % Inisialisasi dan Pembuatan Komponen GUI
    methods (Access = private)

        function createComponents(app)
            % Figure Utama
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [50, 50, 1100, 670];
            app.UIFigure.Name = 'IMAGE ENHANCEMENT APP';

            % Grid Utama (2 Baris: Display Atas, Kontrol Bawah)
            app.MainGrid = uigridlayout(app.UIFigure, [2, 1]);
            app.MainGrid.RowHeight = {'1x', 175};
            app.MainGrid.Padding = [12, 60, 12, 10];

            % 1. DISPLAY GRID (2 Kolom: Kiri = Input, Kanan = Output)
            app.DisplayGrid = uigridlayout(app.MainGrid, [2, 2]);
            app.DisplayGrid.RowHeight = {'1x', 145};
            app.DisplayGrid.ColumnWidth = {'1x', '1x'};

            % Panel & Axes Citra Input (Kiri Atas)
            app.InputImagePanel = uipanel(app.DisplayGrid, 'Title', 'Input Image');
            inputImgGrid = uigridlayout(app.InputImagePanel, [1, 1]);
            inputImgGrid.Padding = [2, 2, 2, 2];
            app.InputImageAxes = uiaxes(inputImgGrid);
            title(app.InputImageAxes, 'Input Image');

            % Panel & Axes Citra Output (Kanan Atas)
            app.OutputImagePanel = uipanel(app.DisplayGrid, 'Title', 'Output Image');
            outputImgGrid = uigridlayout(app.OutputImagePanel, [1, 1]);
            outputImgGrid.Padding = [2, 2, 2, 2];
            app.OutputImageAxes = uiaxes(outputImgGrid);
            title(app.OutputImageAxes, 'Output Image');

            % Panel & Axes Histogram Input (Kiri Bawah)
            app.InputHistPanel = uipanel(app.DisplayGrid, 'Title', 'Input Histogram');
            inputHistGrid = uigridlayout(app.InputHistPanel, [1, 1]);
            inputHistGrid.Padding = [2, 2, 2, 2];
            app.InputHistAxes = uiaxes(inputHistGrid);
            title(app.InputHistAxes, 'Input Histogram');

            % Panel & Axes Histogram Output (Kanan Bawah)
            app.OutputHistPanel = uipanel(app.DisplayGrid, 'Title', 'Output Histogram');
            outputHistGrid = uigridlayout(app.OutputHistPanel, [1, 1]);
            outputHistGrid.Padding = [2, 2, 2, 2];
            app.OutputHistAxes = uiaxes(outputHistGrid);
            title(app.OutputHistAxes, 'Output Histogram');

            % 2. CONTROL PANEL (Bagian Bawah)
            app.ControlPanel = uipanel(app.MainGrid, 'Title', 'Control Panel');
            app.ControlGrid = uigridlayout(app.ControlPanel, [3, 4]);
            app.ControlGrid.RowHeight = {35, 65, 25};
            app.ControlGrid.ColumnWidth = {160, 220, '1x', 160};

            % Baris 1: Tombol Load & Dropdown Metode Utama
            app.LoadImageButton = uibutton(app.ControlGrid, 'push', 'Text', 'Load Image', ...
                'ButtonPushedFcn', @(s, e) app.LoadImageButtonPushed(s, e));
            app.LoadImageButton.Layout.Row = 1;
            app.LoadImageButton.Layout.Column = 1;

            app.MethodDropDown = uidropdown(app.ControlGrid, ...
                'Items', {'Intensity Transformation', 'Histogram Equalization', 'Histogram Matching', 'Linear Filtering', 'Median Filtering'}, ...
                'Value', 'Intensity Transformation', ...
                'ValueChangedFcn', @(s, e) app.MethodDropDownValueChanged(s, e));
            app.MethodDropDown.Layout.Row = 1;
            app.MethodDropDown.Layout.Column = 2;

            % Panel Kontrol Parameter Dinamis (Tengah Baris 1-2)
            app.ParamPanel = uipanel(app.ControlGrid, 'Title', 'Parameters');
            app.ParamPanel.Layout.Row = [1, 2];
            app.ParamPanel.Layout.Column = 3;

            app.ParamGrid = uigridlayout(app.ParamPanel, [2, 1]);
            app.ParamGrid.RowHeight = {30, 30};
            app.ParamGrid.Padding = [8, 4, 8, 4];
            app.ParamGrid.RowSpacing = 4;

            % --- BARIS 1: Kontrol Sub-metode ATAU Pesan Utama ATAU Load Reference ---
            app.Row1Grid = uigridlayout(app.ParamGrid, [1, 3]);
            app.Row1Grid.Layout.Row = 1;
            app.Row1Grid.Layout.Column = 1;
            app.Row1Grid.ColumnWidth = {'1x', 0, 0};
            app.Row1Grid.Padding = [0, 0, 0, 0];
            app.Row1Grid.ColumnSpacing = 0;

            % 1A. Kontrol Sub-metode Baris 1
            app.ControlsRow1Grid = uigridlayout(app.Row1Grid, [1, 4]);
            app.ControlsRow1Grid.Layout.Row = 1;
            app.ControlsRow1Grid.Layout.Column = 1;
            app.ControlsRow1Grid.ColumnWidth = {85, 130, 85, '1x'};
            app.ControlsRow1Grid.Padding = [0, 0, 0, 0];
            app.ControlsRow1Grid.ColumnSpacing = 6;

            app.SubMethodLabel = uilabel(app.ControlsRow1Grid, 'Text', 'Transform:');
            app.SubMethodLabel.Layout.Row = 1;
            app.SubMethodLabel.Layout.Column = 1;

            app.SubMethodDropDown = uidropdown(app.ControlsRow1Grid, ...
                'ValueChangedFcn', @(s, e) app.SubMethodDropDownValueChanged(s, e));
            app.SubMethodDropDown.Layout.Row = 1;
            app.SubMethodDropDown.Layout.Column = 2;

            app.OptionDropDownLabel = uilabel(app.ControlsRow1Grid, 'Text', 'Option:', 'Visible', 'off');
            app.OptionDropDownLabel.Layout.Row = 1;
            app.OptionDropDownLabel.Layout.Column = 3;

            % Subgrid Col 4 (OptionDropDown di Col 1, CustomKernel di Col 2)
            app.Col4Grid = uigridlayout(app.ControlsRow1Grid, [1, 2]);
            app.Col4Grid.Layout.Row = 1;
            app.Col4Grid.Layout.Column = 4;
            app.Col4Grid.ColumnWidth = {'1x', 0};
            app.Col4Grid.Padding = [0, 0, 0, 0];
            app.Col4Grid.ColumnSpacing = 0;

            app.OptionDropDown = uidropdown(app.Col4Grid, 'Visible', 'off');
            app.OptionDropDown.Layout.Row = 1;
            app.OptionDropDown.Layout.Column = 1;

            app.CustomKernelEditField = uieditfield(app.Col4Grid, 'text', 'Visible', 'off', ...
                'Value', '[0 -1 0; -1 5 -1; 0 -1 0]');
            app.CustomKernelEditField.Layout.Row = 1;
            app.CustomKernelEditField.Layout.Column = 2;

            % 1B. Pesan Utama (untuk Histogram Equalization)
            app.MainInfoLabel = uilabel(app.Row1Grid, 'Text', '', 'Visible', 'off', ...
                'HorizontalAlignment', 'center', 'FontColor', [0.45 0.45 0.45], 'FontSize', 12);
            app.MainInfoLabel.Layout.Row = 1;
            app.MainInfoLabel.Layout.Column = 2;

            % 1C. Kontrol Load Reference (untuk Histogram Matching)
            app.RefRow1Grid = uigridlayout(app.Row1Grid, [1, 2]);
            app.RefRow1Grid.Layout.Row = 1;
            app.RefRow1Grid.Layout.Column = 3;
            app.RefRow1Grid.ColumnWidth = {130, '1x'};
            app.RefRow1Grid.Padding = [0, 0, 0, 0];
            app.RefRow1Grid.ColumnSpacing = 8;
            app.RefRow1Grid.Visible = 'off';

            app.LoadReferenceButton = uibutton(app.RefRow1Grid, 'push', 'Text', 'Load Reference', ...
                'Visible', 'off', 'ButtonPushedFcn', @(s, e) app.LoadReferenceButtonPushed(s, e));
            app.LoadReferenceButton.Layout.Row = 1;
            app.LoadReferenceButton.Layout.Column = 1;

            app.RefStatusLabel = uilabel(app.RefRow1Grid, 'Text', 'Reference: (None loaded)', ...
                'Visible', 'off', 'FontColor', [0.35 0.35 0.35], 'FontWeight', 'bold');
            app.RefStatusLabel.Layout.Row = 1;
            app.RefStatusLabel.Layout.Column = 2;

            % --- BARIS 2: Kontrol Slider ATAU Pesan Sub-metode ---
            app.Row2Grid = uigridlayout(app.ParamGrid, [1, 2]);
            app.Row2Grid.Layout.Row = 2;
            app.Row2Grid.Layout.Column = 1;
            app.Row2Grid.ColumnWidth = {'1x', 0};
            app.Row2Grid.Padding = [0, 0, 0, 0];
            app.Row2Grid.ColumnSpacing = 0;

            % 2A. Grid Sliders
            app.SlidersGrid = uigridlayout(app.Row2Grid, [1, 4]);
            app.SlidersGrid.Layout.Row = 1;
            app.SlidersGrid.Layout.Column = 1;
            app.SlidersGrid.ColumnWidth = {85, 130, 85, '1x'};
            app.SlidersGrid.Padding = [0, 0, 0, 0];
            app.SlidersGrid.ColumnSpacing = 6;

            app.Param1Label = uilabel(app.SlidersGrid, 'Text', 'Param 1:', 'Visible', 'off');
            app.Param1Label.Layout.Row = 1;
            app.Param1Label.Layout.Column = 1;

            param1SubGrid = uigridlayout(app.SlidersGrid, [1, 2]);
            param1SubGrid.Layout.Row = 1;
            param1SubGrid.Layout.Column = 2;
            param1SubGrid.Padding = [0, 0, 0, 0];
            param1SubGrid.ColumnWidth = {'1x', 50};

            app.Param1Slider = uislider(param1SubGrid, 'Visible', 'off', ...
                'ValueChangedFcn', @(s, e) app.Param1SliderValueChanged(s, e));
            app.Param1EditField = uieditfield(param1SubGrid, 'numeric', 'Visible', 'off', ...
                'ValueChangedFcn', @(s, e) app.Param1EditFieldValueChanged(s, e));

            app.Param2Label = uilabel(app.SlidersGrid, 'Text', 'Param 2:', 'Visible', 'off');
            app.Param2Label.Layout.Row = 1;
            app.Param2Label.Layout.Column = 3;

            param2SubGrid = uigridlayout(app.SlidersGrid, [1, 2]);
            param2SubGrid.Layout.Row = 1;
            param2SubGrid.Layout.Column = 4;
            param2SubGrid.Padding = [0, 0, 0, 0];
            param2SubGrid.ColumnWidth = {'1x', 50};

            app.Param2Slider = uislider(param2SubGrid, 'Visible', 'off', ...
                'ValueChangedFcn', @(s, e) app.Param2SliderValueChanged(s, e));
            app.Param2EditField = uieditfield(param2SubGrid, 'numeric', 'Visible', 'off', ...
                'ValueChangedFcn', @(s, e) app.Param2EditFieldValueChanged(s, e));

            % 2B. Pesan Sub-metode (e.g. Negative, Contrast Stretching, Sobel)
            app.SubInfoLabel = uilabel(app.Row2Grid, 'Text', '', 'Visible', 'off', ...
                'HorizontalAlignment', 'center', 'FontColor', [0.45 0.45 0.45], 'FontSize', 11);
            app.SubInfoLabel.Layout.Row = 1;
            app.SubInfoLabel.Layout.Column = 2;

            % Tombol Aksi Kanan (Enhance & Reset)
            app.EnhanceButton = uibutton(app.ControlGrid, 'push', 'Text', 'Enhance', ...
                'BackgroundColor', [0.15, 0.45, 0.85], 'FontColor', [1 1 1], 'FontWeight', 'bold', ...
                'ButtonPushedFcn', @(s, e) app.EnhanceButtonPushed(s, e));
            app.EnhanceButton.Layout.Row = 1;
            app.EnhanceButton.Layout.Column = 4;

            % Baris 2: Tombol Reset
            app.ResetButton = uibutton(app.ControlGrid, 'push', 'Text', 'Reset', ...
                'ButtonPushedFcn', @(s, e) app.ResetButtonPushed(s, e));
            app.ResetButton.Layout.Row = 2;
            app.ResetButton.Layout.Column = 4;

            % Baris 3: Status Bar Informasi
            app.StatusLabel = uilabel(app.ControlGrid, 'Text', 'Siap. Silakan muat citra input.', ...
                'FontColor', [0.3 0.3 0.3]);
            app.StatusLabel.Layout.Row = 3;
            app.StatusLabel.Layout.Column = [1, 4];

            % Set status awal parameter
            app.updateParameterControls('Intensity Transformation');
            app.UIFigure.Visible = 'on';
        end
    end

    % Konstruktor dan Destruktor App
    methods (Access = public)

        function app = ImageEnhancementApp
            guiPath = fileparts(mfilename('fullpath'));
            if ~isempty(guiPath)
                srcPath = fileparts(guiPath);
                if exist(srcPath, 'dir')
                    addpath(genpath(srcPath));
                end
            end
            createComponents(app);
            registerApp(app, app.UIFigure);
        end

        function delete(app)
            delete(app.UIFigure);
        end
    end
end
