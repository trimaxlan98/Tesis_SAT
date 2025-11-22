function generate_matrix_only()
% GENERATE_MATRIX_ONLY
% Genera exclusivamente la matriz comparativa de 3x3 espectrogramas.

    clc; close all;
    CLASSES = {'Clean', 'AWGN', 'BBNJ', 'CW', 'Pulsed', 'Sweep', 'CCI', 'ACI', 'Atmospheric'};
    Fs = 1e6;
    
    % Configurar Figura Grande y Panorámica
    f = figure('Name', 'Matriz de Huellas Espectrales', 'Color', 'w', ...
           'Position', [100, 100, 1200, 800]);
    
    % Título General
    sgtitle('Atlas de Huellas Espectrales (Dataset SDCS)', 'FontSize', 18, 'FontWeight', 'bold');
    
    for i = 1:length(CLASSES)
        label = CLASSES{i};
        iq_sig = sat_scenario_gen_v2(label);
        
        subplot(3, 3, i);
        
        % Parámetros de alta resolución visual para la matriz
        [~,F,T,P] = spectrogram(iq_sig, hamming(128), 120, 128, Fs, 'centered');
        
        % Usar imagesc para colores vibrantes sin bordes
        imagesc(T*1e6, F/1000, 10*log10(abs(P)));
        axis xy; 
        colormap jet;
        
        % Estética limpia
        title(label, 'FontSize', 14, 'FontWeight', 'bold');
        set(gca, 'XTick', [], 'YTick', []); % Quitar números para limpiar la vista
        
        % Solo poner etiquetas en los bordes externos para no saturar
        if i > 6, xlabel('Tiempo', 'FontSize', 10); end
        if mod(i,3)==1, ylabel('Frecuencia', 'FontSize', 10); end
    end
    
    % Guardar
    if ~exist('Atlas_Resultados', 'dir'), mkdir('Atlas_Resultados'); end
    saveas(f, fullfile('Atlas_Resultados', 'Atlas_Matrix_Summary.png'));
    disp('✅ Matriz generada: Atlas_Resultados/Atlas_Matrix_Summary.png');
end