function visualize_mitigation(threat_type)
% VISUALIZE_MITIGATION Genera gráficas de defensa en tiempo real
% Muestra la respuesta del sistema (Filtros o Beamforming)

    figure(1);
    set(gcf, 'Name', 'SAT-COM Defense Dashboard', 'Color', 'white');
    clf; % Limpiar figura anterior

    switch threat_type
        case 'CCI'
            % --- VISUALIZACIÓN: BEAMFORMING (NULL STEERING) ---
            % Simulamos un Array Lineal Uniforme (ULA) de 8 elementos
            % Objetivo: Satélite en 0°, Interferencia en 40°
            
            theta = linspace(-90, 90, 360); % Ángulos de -90 a 90
            theta_rad = deg2rad(theta);
            
            % Pesos simulados para crear un nulo en 40 grados
            % (Matemática simplificada de Array Factor)
            N = 8; % Elementos
            d = 0.5; % Espaciado (lambda/2)
            k = 2*pi;
            
            % Vector de dirección deseado (0°) e interferencia (40°)
            w = ones(1, N); % Pesos iniciales
            
            % Aplicamos desfase progresivo para anular 40° (Simulación visual)
            % En la realidad, esto sale de la matriz de covarianza inversa
            AF = zeros(size(theta));
            
            % Generamos un patrón con lóbulo principal en 0 y nulo en 40
            for i = 1:length(theta)
                steering_vec = exp(1j * k * d * (0:N-1)' * sind(theta(i)));
                % Peso hardcodeado para simular MVDR visualmente
                % (Cancelación en 40 grados)
                null_angle = 40;
                w_null = exp(-1j * k * d * (0:N-1)' * sind(null_angle));
                
                % Combinación: Preservar 0°, anular 40°
                total_weight = ones(N,1) - 0.9 * w_null; 
                
                AF(i) = abs(sum(total_weight .* steering_vec));
            end
            
            % Normalizar
            AF = AF / max(AF);
            AF_dB = 20*log10(AF + 0.001);
            AF_dB(AF_dB < -40) = -40; % Piso de ruido visual

            % --- PLOT POLAR ---
            subplot(1,1,1);
            polarplot(theta_rad, AF_dB, 'LineWidth', 2, 'Color', [0 0.447 0.741]);
            rlim([-40 0]);
            title('📡 ACCIÓN: MVDR Beamforming Null-Steering', 'FontSize', 14);
            
            hold on;
            % Marcar Satélite
            polarplot(0, 0, 'xg', 'MarkerSize', 15, 'LineWidth', 3); 
            text(0, 5, ' Satélite', 'FontSize', 12, 'Color', 'g', 'FontWeight', 'bold');
            
            % Marcar Interferencia Anulada
            polarplot(deg2rad(40), -10, 'or', 'MarkerSize', 10, 'LineWidth', 2);
            text(deg2rad(40), -5, ' \leftarrow CCI Anulada', 'Color', 'r', 'FontWeight', 'bold');
            hold off;

        case {'CW', 'Sweep', 'ACI'}
            % --- VISUALIZACIÓN: ESPECTRO Y FILTRO ---
            % Generar señal dummy y espectro
            Fs = 1000;
            t = 0:1/Fs:1;
            sig = chirp(t, 100, 1, 400) + randn(size(t))*0.1;
            
            % Simular el "hueco" del filtro
            L = length(sig);
            f = Fs*(-L/2:L/2-1)/L;
            S = fftshift(abs(fft(sig)));
            S = S / max(S);
            
            % Crear muesca (Notch) visual
            notch_center = 250; % Frecuencia arbitraria para demo
            mask = ones(size(f));
            mask(abs(abs(f) - notch_center) < 20) = 0.01; % El filtro
            S_filtered = S .* mask;
            
            subplot(2,1,1);
            plot(f, 20*log10(S), 'Color', [0.85 0.32 0.09]);
            title(['⚠️ Amenaza Detectada: ' threat_type ' (Espectro)']);
            ylabel('Magnitud (dB)'); grid on; xlim([0 500]);
            
            subplot(2,1,2);
            plot(f, 20*log10(S_filtered), 'Color', [0.46 0.67 0.18], 'LineWidth', 1.5);
            title('🛡️ Respuesta: Filtro Notch Adaptativo Activado');
            ylabel('Magnitud (dB)'); xlabel('Frecuencia (Hz)'); grid on; xlim([0 500]);
            
            % Dibujar caja roja del filtro
            hold on;
            x_fill = [notch_center-20, notch_center+20, notch_center+20, notch_center-20];
            y_fill = [-100, -100, 0, 0];
            fill(x_fill, y_fill, 'r', 'FaceAlpha', 0.3, 'EdgeColor', 'none');
            text(notch_center, -20, 'Filtro', 'HorizontalAlignment', 'center', 'Color', 'r');
            hold off;

        case {'AWGN', 'BBNJ', 'Pulsed'}
             % --- VISUALIZACIÓN: CONSTELACIÓN ---
             % Mostrar cómo BPSK es más robusto que QPSK
             data = randi([0 1], 1000, 1);
             qpsk = pskmod(randi([0 3], 1000, 1), 4);
             bpsk = pskmod(data, 2);
             
             subplot(1,2,1);
             plot(real(qpsk)+randn(1000,1)*0.3, imag(qpsk)+randn(1000,1)*0.3, '.b');
             title('❌ QPSK (Vulnerable)'); axis square; grid on;
             
             subplot(1,2,2);
             plot(real(bpsk)+randn(1000,1)*0.3, imag(bpsk)+randn(1000,1)*0.3, '.g');
             title('✅ BPSK (Robusto/ACM)'); axis square; grid on;
             sgtitle(['Degradación por ' threat_type ' -> Cambio de Modulación']);

        otherwise
            % Limpiar si es Clean
            clf;
            text(0.5, 0.5, '✅ SISTEMA NOMINAL', 'FontSize', 20, ...
                'HorizontalAlignment', 'center', 'Color', 'g');
            axis off;
    end
    
    drawnow; % Forzar actualización de gráficos
end