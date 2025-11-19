%% SISTEMA DE CIBERDEFENSA SATELITAL - MAIN LOOP
% Tesis: Control Selectivo para Mitigación de Interferencias NGSO
% Arquitectura: Generación -> Decisión (IA Simulada) -> DSP -> Visualización
clc; clear; close all;

%% 1. CONFIGURACIÓN DEL ESCENARIO (Simulación del Entorno)
% ---------------------------------------------------------
% CAMBIA ESTAS DOS VARIABLES PARA PROBAR DIFERENTES CASOS:
threat_type = 'Directional';  % Opciones: 'CW', 'Directional', 'BBNJ', 'Clean'
JNR_dB = 30;                  % Potencia de interferencia (30 dB es muy fuerte)
% ---------------------------------------------------------

fprintf('=== INICIANDO SIMULACIÓN ===\n');
fprintf('1. Generando escenario: %s con JNR = %d dB...\n', threat_type, JNR_dB);

% Llamada a la Fase 1 (Física)
[Rx_Signal_Matrix, Target_Ref, Params] = sat_scenario_gen.generate_scenario(threat_type, JNR_dB);

%% 2. LÓGICA DE CONTROL SELECTIVO (El "Cerebro")
% En la versión final, esta variable vendrá de Python (AI Classifier).
% Aquí simulamos que la IA ya clasificó correctamente la amenaza.
detected_class = threat_type; 

clean_signal = [];
weights = []; % Solo para Beamforming

fprintf('2. Decisión de Control: Amenaza "%s" detectada.\n', detected_class);

switch detected_class
    case 'CW'
        % ESTRATEGIA: Dominio de la Frecuencia (Filtro Notch)
        % Para CW, tomamos una antena representativa (o sumamos) y filtramos.
        signal_to_process = Rx_Signal_Matrix(:, 1); 
        [clean_signal, f_notch] = sat_dsp_modules.mitigate_cw_notch(signal_to_process, Params.fs);
        
    case 'Directional'
        % ESTRATEGIA: Dominio Espacial (Beamforming MVDR)
        % Usamos la matriz completa de antenas para anular el ángulo de llegada.
        [clean_signal, weights] = sat_dsp_modules.mitigate_beamforming_mvdr(Rx_Signal_Matrix, Params);
        
    case {'BBNJ', 'Clean'}
        % ESTRATEGIA: Passthrough (O Coding Gain en capas superiores)
        clean_signal = sat_dsp_modules.bypass(Rx_Signal_Matrix);
        
    otherwise
        error('Clase no soportada en la matriz de decisión.');
end

%% 3. VISUALIZACIÓN DE RESULTADOS (Evidencia para Tesis)
figure('Name', 'Resultados de Mitigación', 'Position', [100, 100, 1200, 700], 'Color', 'w');

% A) CONSTELACIONES (La prueba de que recuperamos los datos)
subplot(2, 3, 1);
plot(Rx_Signal_Matrix(:,1), '.', 'Color', [0.9 0.4 0.4]); hold on;
title('Antes: Señal Sucia (Rx)'); axis square; grid on;
subplot(2, 3, 4);
plot(clean_signal, '.', 'Color', [0.2 0.6 0.2]); 
title('Después: Señal Mitigada'); axis square; grid on;
% Nota: Ajustamos la escala visual del limpio para comparar
xlim([-2 2]); ylim([-2 2]);

% B) VISUALIZACIÓN ESPECÍFICA SEGÚN AMENAZA
if strcmp(detected_class, 'CW')
    % --- MOSTRAR ESPECTRO (PSD) ---
    subplot(2, 3, [2, 3, 5, 6]);
    [pxx_pre, f] = pwelch(Rx_Signal_Matrix(:,1), 500, 250, 1024, Params.fs, 'centered');
    [pxx_post, ~] = pwelch(clean_signal, 500, 250, 1024, Params.fs, 'centered');
    
    plot(f/1e6, 10*log10(pxx_pre), 'r', 'LineWidth', 1); hold on;
    plot(f/1e6, 10*log10(pxx_post), 'g', 'LineWidth', 1.5);
    xline(f_notch/1e6, '--k', 'Frecuencia Notch');
    
    title('Análisis Espectral: Eliminación del Tono CW');
    xlabel('Frecuencia (MHz)'); ylabel('Potencia (dB)');
    legend('Espectro Sucio', 'Espectro Limpio (Notch Aplicado)');
    grid on;
    
elseif strcmp(detected_class, 'Directional')
    % --- MOSTRAR PATRÓN DE RADIACIÓN (Polar Plot) ---
    subplot(2, 3, [2, 3, 5, 6]);
    
    % Cálculo del Patrón de Radiación del Array
    angles = -90:0.5:90;
    array_factor = zeros(size(angles));
    
    % Suma de las respuestas de cada antena con los pesos calculados (w)
    % AF(theta) = sum( w_n * exp(j * k * d * n * sin(theta)) )
    for i = 1:length(angles)
        theta = angles(i);
        v_test = exp(-1j * 2*pi * Params.d * (0:Params.N_antennas-1)' * sind(theta) / Params.lambda);
        array_factor(i) = abs(weights' * v_test);
    end
    
    % Normalizar y convertir a dB
    array_factor = array_factor / max(array_factor);
    af_db = 20*log10(array_factor + 1e-6); % +1e-6 para evitar log(0)
    
    plot(angles, af_db, 'LineWidth', 2); hold on;
    xline(Params.theta_J, '--r', 'Dirección Jammer');
    xline(Params.theta_S, '--g', 'Dirección Satélite');
    
    title('Patrón de Radiación Adaptativo (MVDR)');
    xlabel('Ángulo de Llegada (Grados)'); ylabel('Ganancia del Array (dB)');
    legend('Respuesta del Array', 'Jammer (Debe estar en un Nulo)', 'Satélite (Max Ganancia)');
    grid on; ylim([-50 0]);
    
    text(-80, -40, 'Nota: Observa el "Null" profundo en la linea roja', 'BackgroundColor', 'w');

else
    % --- BBNJ o CLEAN ---
    subplot(2, 3, [2, 3, 5, 6]);
    text(0.5, 0.5, 'Amenaza de Ruido Banda Ancha o Canal Limpio.', ...
        'HorizontalAlignment', 'center', 'FontSize', 14);
    text(0.5, 0.4, 'El filtrado DSP convencional no elimina ruido blanco superpuesto.', ...
        'HorizontalAlignment', 'center', 'FontSize', 10);
    axis off;
end

fprintf('=== SIMULACIÓN COMPLETADA ===\n');