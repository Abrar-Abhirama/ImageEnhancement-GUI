% imageEnhancementGUI - Fungsi launcher untuk ImageEnhancementApp
function app = imageEnhancementGUI()
    app = ImageEnhancementApp();
    if nargout == 0
        clear app;
    end
end
