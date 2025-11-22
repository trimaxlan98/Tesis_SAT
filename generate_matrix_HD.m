function generate_matrix_HD()
% GENERATE_MATRIX_HD
% Genera una matriz de "Caricaturas Espectrales" exageradas para
% que las diferencias sean OBVIAS al ojo humano en la presentación.

    clc; close all;
    CLASSES = {'Clean', 'AWGN', 'BBNJ', 'CW', 'Pulsed', 'Sweep', 'CCI', 'ACI', 'Atmospheric'};
    Fs = 1e6;
    
    f = figure('Name', 'Matriz HD - Diferencias Visuales', 'Color', 'w', ...
           'Position', [100, 100, 1200, 800]);
    sgtitle('Atlas de Huellas Espectrales (Contrastes Exagerados)', 'FontSize', 18, 'FontWeight', 'bold');
    
    for i = 1:length(CLASSES)
        label = CLASSES{i};
        
        % Usamos el generador "Exagerado" local
        iq_sig = get_visual_signal(label, Fs);
        
        subplot(3, 3, i);
        
        % Configuración de Espectrograma para ALTO CONTRASTE
        % Aumentamos nfft para mejor resolución de frecuencia
        [~,F,T,P] = spectrogram(iq_sig, hamming(256), 240, 512, Fs, 'centered');
        
        % Truco visual: Saturar el rango de colores (CLim)
        % Esto hace que el fondo sea azul profundo y la señal rojo intenso
        imagesc(T*1e6, F/1000, 10*log10(abs(P)));
        axis xy; 
        colormap jet;
        
        % Ajustar límites de color para borrar ruido de fondo visual
        caxis([-100 -40]); 
        
        title(label, 'FontSize', 14, 'FontWeight', 'bold');
        set(gca, 'XTick', [], 'YTick', []); 
        
        if i > 6, xlabel('Tiempo', 'FontSize', 10); end
        if mod(i,3)==1, ylabel('Frecuencia', 'FontSize', 10); end
    end
    
    % Guardar
    if ~exist('Atlas_Resultados', 'dir'), mkdir('Atlas_Resultados'); end
    saveas(f, fullfile('Atlas_Resultados', 'Atlas_Matrix_HD.png'));
    disp('✅ Matriz HD generada con contrastes mejorados.');
end

% --- GENERADOR LOCAL "EXAGERADO" PARA VISUALIZACIÓN ---
function iq = get_visual_signal(label, Fs)
    N = 2048; % Más muestras para mejor resolución
    t = (0:N-1)/Fs;
    
    % Señal Base (Muy limpia)
    data = randi([0 3], N/4, 1);
    mod_sig = pskmod(data, 4, pi/4);
    tx_sig = rectpulse(mod_sig, 4);
    tx_sig = tx_sig(1:N).';
    
    switch label
        case 'Clean'
            % SNR muy alto (50 dB) para que se vea perfecto
            iq = awgn(tx_sig, 50, 'measured');
            
        case 'AWGN'
            % Mucho ruido
            iq = awgn(tx_sig, 0, 'measured');
            
        case 'BBNJ'
            % Ruido cubriendo todo, muy fuerte
            noise = wgn(1, N, 10, 'complex'); 
            iq = tx_sig + noise;
            
        case 'CW'
            % Línea muy fina y potente
            tone = exp(1j*2*pi*0.1e6*t); % Tono desplazado
            iq = tx_sig + 2*tone;
            
        case 'Pulsed'
            % Cortes muy claros
            mask = square(2*pi*5000*t, 50) > 0; % Onda cuadrada perfecta
            noise = wgn(1, N, 15, 'complex') .* mask;
            iq = tx_sig + noise;
            
        case 'Sweep'
            % Chirp muy marcado
            sw = chirp(t, -Fs/3, t(end), Fs/3, 'linear', 0, 'complex');
            iq = tx_sig + 2*sw;
            
        case 'CCI'
            % TRUCO VISUAL: Interferente ligeramente desplazado en frecuencia
            % para que se vea un "batido" o engrosamiento de la banda
            int_data = randi([0 3], N/4, 1);
            int_mod = pskmod(int_data, 4, pi/4);
            int_sig = rectpulse(int_mod, 4);
            int_sig = int_sig(1:N).';
            % Desplazamiento sutil (50kHz) para crear textura visual
            int_sig = int_sig .* exp(1j*2*pi*0.05e6*t); 
            iq = tx_sig + 1.5*int_sig; % Interferencia más fuerte que señal
            
        case 'ACI'
            % TRUCO VISUAL: Moverla muy al borde
            int_data = randi([0 3], N/4, 1);
            int_mod = pskmod(int_data, 4, pi/4);
            int_sig = rectpulse(int_mod, 4);
            int_sig = int_sig(1:N).';
            % Desplazamiento grande (350kHz)
            aci = int_sig .* exp(1j*2*pi*0.35e6*t);
            iq = tx_sig + 2*aci; 
            
        case 'Atmospheric'
            % TRUCO VISUAL: Desvanecimiento lento y profundo (rayas horizontales)
            fading = 0.5 + 0.5*cos(2*pi*2000*t); % Variación sinusoidal visible
            iq = tx_sig .* fading;
            iq = awgn(iq, 30); % Poco ruido para ver el efecto
            
        otherwise
            iq = tx_sig;
    end
end