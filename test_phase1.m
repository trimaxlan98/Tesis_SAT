% test_phase1.m
clc; clear; close all;

% Selecciona escenario para probar
threat = 'CW'; % Cambiar por: 'CW', 'BBNJ', 'Directional', 'Sweep', 'Clean'
JNR = 20;      % Jammer to Noise Ratio en dB (Interferencia potente)

% Llamada al generador
[Rx, Ref, P] = sat_scenario_gen.generate_scenario(threat, JNR);

% Visualización
figure('Name', ['Escenario: ' threat], 'Position', [100, 100, 1000, 600]);

% 1. Time Domain (Magnitud)
subplot(2,2,1);
plot(abs(Rx(1:200, 1)), 'r'); hold on;
plot(abs(Ref(1:200)), 'b', 'LineWidth', 1.5);
title('Dominio del Tiempo (Antena 1)');
legend('Señal RX (Sucia)', 'Referencia (Limpia)');
grid on;

% 2. Espectro de Frecuencia (PSD)
subplot(2,2,2);
[pxx, f] = pwelch(Rx(:,1), 500, 250, 1024, P.fs, 'centered');
plot(f/1e6, 10*log10(pxx));
title('Espectro de Potencia (PSD)');
xlabel('Frecuencia (MHz)'); ylabel('Potencia (dB)');
grid on;
% Nota: Si es CW, deberías ver un pico claro. Si es BBNJ, el piso de ruido sube.

% 3. Constelación (Sucia)
subplot(2,2,3);
plot(Rx(:,1), '.');
title('Constelación Recibida (Sin procesar)');
axis square; grid on;

% 4. Análisis Espacial (Solo conceptual por ahora)
subplot(2,2,4);
text(0.1, 0.5, {['Amenaza: ' threat], ...
                ['JNR: ' num2str(JNR) ' dB'], ...
                ['Angulo Jammer: ' num2str(P.theta_J) '°'], ...
                ['Angulo Satélite: ' num2str(P.theta_S) '°']}, ...
                'FontSize', 12);
axis off; title('Metadatos del Escenario');

sgtitle(['Validación Física: Escenario ' threat]);