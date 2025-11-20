function visualize_mitigation_v3(action_code)
% VISUALIZE_MITIGATION_V3
% Soporta visualización de STBC (Nivel 3) y Emergencia (Nivel 4)
% action_code strings: 'FILTER', 'ACM', 'BEAM_STBC', 'AGC', 'EMERGENCY', 'NOMINAL'

    figure(1);
    set(gcf, 'Name', 'SAT-COM Defense Dashboard V3', 'Color', 'white');
    clf; 

    switch action_code
        case 'BEAM_STBC' % Nivel 3: Beamforming + STBC
            % --- IZQUIERDA: BEAMFORMING ---
            subplot(1,2,1);
            theta = linspace(-90, 90, 360); 
            % Patrón con nulo en 40 grados
            pattern = abs(sinc((theta)/15)) + 0.1; % Lóbulo principal
            null_idx = abs(theta - 40) < 5;
            pattern(null_idx) = pattern(null_idx) * 0.1; % El Nulo
            pattern = 20*log10(pattern); pattern(pattern<-40)=-40;
            
            polarplot(deg2rad(theta), pattern, 'LineWidth', 2);
            rlim([-40 0]); title('1. Beamforming (Null-Steering)');
            hold on; polarplot(deg2rad(40), -10, 'or', 'LineWidth', 2); hold off;
            
            % --- DERECHA: STBC (Alamouti) ---
            subplot(1,2,2);
            % Simulación visual de ganancia de diversidad
            snr = 0:20;
            ber_siso = 0.5 * erfc(sqrt(10.^(snr/10))); % Un solo canal
            ber_miso = 0.5 * erfc(sqrt(2*10.^(snr/10))); % STBC (2Tx 1Rx)
            
            semilogy(snr, ber_siso, '--r', 'LineWidth', 1.5); hold on;
            semilogy(snr, ber_miso, '-g', 'LineWidth', 2);
            grid on; legend('Sin Codificar (SISO)', 'Con STBC (MISO 2x1)');
            title('2. Codificación Espacio-Tiempo (STBC)');
            xlabel('SNR (dB)'); ylabel('BER');
            sgtitle('NIVEL 3: CONTRAMEDIDAS AVANZADAS');

        case 'FILTER' % Nivel 1: Filtros
            % Visualización de espectro con Notch
            f = linspace(0, 500, 1000);
            spec = exp(-(f-250).^2/2000); % Señal
            noise = rand(1,1000)*0.1;
            % El filtro
            filter_resp = ones(1,1000);
            filter_resp(480:520) = 0.01; % Notch en el centro
            
            area(f, 20*log10(spec+noise), 'FaceColor', [0.9 0.6 0.6]); hold on;
            plot(f, 20*log10(filter_resp), 'g', 'LineWidth', 2);
            title('NIVEL 1: FILTRADO ADAPTATIVO');
            legend('Interferencia', 'Respuesta del Filtro');
            ylim([-60 10]); grid on;

        case 'AGC' % Nivel 1: AGC (Específico para Atmospheric)
            subplot(2,1,1);
            t = 0:0.01:10;
            % Señal fluctuante (Desvanecimiento Rician simulado)
            fading = (1 + 0.4*sin(2*pi*0.5*t) + 0.2*randn(size(t))); 
            plot(t, fading, 'Color', [0.85 0.32 0.09], 'LineWidth', 1);
            title('Entrada: Señal con Desvanecimiento Atmosférico');
            ylabel('Amplitud'); grid on; ylim([0 2.5]);
            
            subplot(2,1,2);
            % Señal estabilizada
            corrected = ones(size(t)) + 0.05*randn(size(t)); 
            plot(t, corrected, 'Color', [0.46 0.67 0.18], 'LineWidth', 2);
            title('Salida: Compensación por AGC (Nivel 1)');
            xlabel('Tiempo (s)'); ylabel('Amplitud Nivelada'); 
            grid on; ylim([0 2.5]);

        case 'ACM' % Nivel 2: ACM
            % Constelaciones
            subplot(1,2,1); plot(randn(100,1), randn(100,1), '.b'); title('QPSK (Ruidoso)'); axis square;
            subplot(1,2,2); plot([ones(50,1); -ones(50,1)], randn(100,1)*0.5, '.g'); title('BPSK (Robusto)'); axis square;
            sgtitle('NIVEL 2: ADAPTACIÓN DINÁMICA (ACM)');

        case 'EMERGENCY' % Nivel 4: Respuesta Integral
            % Pantalla de alerta roja
            clf; set(gcf, 'Color', [0.8 0 0]); % Fondo rojo
            text(0.5, 0.6, '⚠️ NIVEL 4 CRÍTICO ⚠️', 'FontSize', 24, 'Color', 'w', 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
            text(0.5, 0.4, 'RECONFIGURACIÓN TOTAL DEL SISTEMA', 'FontSize', 16, 'Color', 'w', 'HorizontalAlignment', 'center');
            text(0.5, 0.3, 'Modo Seguro Activado - Enlace de Respaldo', 'FontSize', 14, 'Color', 'y', 'HorizontalAlignment', 'center');
            axis off;

        otherwise % Nominal
            clf; set(gcf, 'Color', 'w');
            text(0.5, 0.5, '✅ SISTEMA NOMINAL (Monitoreo)', 'FontSize', 20, 'HorizontalAlignment', 'center', 'Color', 'g');
            axis off;
    end
    drawnow;
end