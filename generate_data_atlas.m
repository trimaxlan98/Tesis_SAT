function generate_data_atlas_final()
% GENERATE_DATA_ATLAS_FINAL
% Genera una ficha técnica visual por cada clase de amenaza.
% Guarda automáticamente las imágenes en la carpeta 'Atlas_Resultados'.

    clc; close all;
    
    % --- CONFIGURACIÓN ---
    CLASSES = {'Clean', 'AWGN', 'BBNJ', 'CW', 'Pulsed', 'Sweep', 'CCI', 'ACI', 'Atmospheric'};
    Fs = 1e6; % 1 MHz
    SAVE_DIR = 'Atlas_Resultados';
    
    % Crear carpeta si no existe
    if ~exist(SAVE_DIR, 'dir')
        mkdir(SAVE_DIR);
        disp(['📂 Carpeta creada: ' SAVE_DIR]);
    end
    
    disp('🚀 Generando Atlas de Señales... Por favor espere.');

    % --- BUCLE POR CLASE ---
    for i = 1:length(CLASSES)
        label = CLASSES{i};
        fprintf('   Procesando: %s...\n', label);
        
        % 1. Generar Señal
        iq_sig = sat_scenario_gen_v2(label);
        
        % Configurar Figura (Formato panorámico para diapositiva)
        fig = figure('Name', ['Análisis: ' label], 'Color', 'w', 'Visible', 'off', ...
                     'Position', [100, 100, 1200, 400]);
        
        % --- A. DOMINIO DEL TIEMPO (ZOOM) ---
        subplot(1, 3, 1);
        % Mostramos 200 muestras (200 microsegundos) para ver la forma de onda
        zoom_range = 1:200; 
        t_us = (zoom_range-1)/Fs * 1e6;
        
        % Graficamos la parte REAL (In-Phase) que lleva la información principal
        plot(t_us, real(iq_sig(zoom_range)), 'b', 'LineWidth', 1.2); 
        hold on;
        % Graficamos la envolvente (Magnitud) para ver si hay pulsos
        plot(t_us, abs(iq_sig(zoom_range)), 'r:', 'LineWidth', 1);
        
        title(['1. Dominio del Tiempo (' label ')'], 'FontWeight', 'bold');
        xlabel('Tiempo (\mus)'); 
        ylabel('Amplitud');
        legend('Señal (I)', 'Envolvente (Mag)', 'Location', 'best');
        grid on; axis tight; ylim([-1.2 1.2]);
        
        % --- B. DOMINIO DE LA FRECUENCIA (PSD) ---
        subplot(1, 3, 2);
        % Welch: Promedio de periodogramas para suavizar el ruido
        [pxx, f] = pwelch(iq_sig, hamming(512), 256, 512, Fs, 'centered');
        
        plot(f/1000, 10*log10(pxx), 'Color', [0.85 0.32 0.09], 'LineWidth', 1.5);
        title('2. Espectro de Potencia (PSD)', 'FontWeight', 'bold');
        xlabel('Frecuencia (kHz)'); 
        ylabel('Potencia (dB/Hz)');
        grid on; xlim([-500 500]);
        
        % --- C. ESPECTROGRAMA (TIEMPO-FRECUENCIA) ---
        subplot(1, 3, 3);
        % Ajuste fino para resolución visual
        win_size = 128;
        overlap = 120;
        nfft = 256;
        
        [~,F,T,P] = spectrogram(iq_sig, hamming(win_size), overlap, nfft, Fs, 'centered');
        
        % Graficar como superficie plana (pcolor es mejor que spectrogram default para guardar)
        imagesc(T*1e6, F/1000, 10*log10(abs(P))); 
        axis xy; colormap jet; 
        c = colorbar; c.Label.String = 'Potencia (dB)';
        
        title('3. Espectrograma', 'FontWeight', 'bold');
        xlabel('Tiempo (\mus)'); 
        ylabel('Frecuencia (kHz)');
        
        % --- GUARDADO AUTOMÁTICO ---
        filename = fullfile(SAVE_DIR, ['Atlas_' label '.png']);
        saveas(fig, filename);
        close(fig); % Cerrar para no llenar la memoria
    end
    
    disp('✅ ¡Proceso terminado! Revisa la carpeta "Atlas_Resultados".');
end