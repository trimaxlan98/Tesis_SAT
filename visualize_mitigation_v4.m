function visualize_mitigation_v4(action_code)
% VISUALIZE_MITIGATION_V4 - Mejoras visuales: colores, líneas, tamaño de puntos.
% action_code strings: 'FILTER', 'ACM', 'BEAM_STBC', 'AGC', 'EMERGENCY', 'NOMINAL'

    figure(1);
    set(gcf, 'Name', 'SAT-COM Defense Dashboard V4 (Mejorado)', 'Color', 'white');
    clf;

    % --- Estilos de Color ---
    COLOR_BLUE_DARK = [0 0.2 0.6]; % Azul oscuro para líneas
    COLOR_GREEN_STRONG = [0 0.5 0]; % Verde fuerte
    COLOR_RED_STRONG = [0.8 0 0]; % Rojo fuerte
    COLOR_ORANGE = [1 0.5 0]; % Naranja
    
    switch action_code
        case 'BEAM_STBC' % Nivel 3: Beamforming + STBC
            % --- IZQUIERDA: BEAMFORMING ---
            subplot(1,2,1);
            theta = linspace(-90, 90, 360);
            pattern = abs(sinc((theta)/15)) + 0.1; 
            null_idx = abs(theta - 40) < 5;
            pattern(null_idx) = pattern(null_idx) * 0.1; 
            pattern = 20*log10(pattern); 
            pattern(pattern<-40)=-40;
            
            polarplot(deg2rad(theta), pattern, 'LineWidth', 2.5, 'Color', COLOR_BLUE_DARK); % Línea más gruesa, azul oscuro
            rlim([-40 0]);
            title('1. Beamforming (Null-Steering)', 'FontSize', 12, 'FontWeight', 'bold');
            hold on;
            polarplot(deg2rad(40), -10, 'o', 'MarkerSize', 10, 'LineWidth', 2, 'Color', COLOR_RED_STRONG); % Marcador rojo más grande
            text(deg2rad(40), -5, ' \leftarrow CCI Anulada', 'Color', COLOR_RED_STRONG, 'FontWeight', 'bold', 'FontSize', 10);
            polarplot(0, 0, 'xg', 'MarkerSize', 15, 'LineWidth', 3); % Satélite
            text(0, 5, ' Satélite', 'FontSize', 12, 'Color', 'g', 'FontWeight', 'bold');
            hold off;
            
            % --- DERECHA: STBC (Alamouti) ---
            subplot(1,2,2);
            snr = 0:20;
            ber_siso = 0.5 * erfc(sqrt(10.^(snr/10))); 
            ber_miso = 0.5 * erfc(sqrt(2*10.^(snr/10)));
            
            semilogy(snr, ber_siso, '--', 'Color', COLOR_RED_STRONG, 'LineWidth', 2); hold on; % Línea más gruesa, rojo oscuro
            semilogy(snr, ber_miso, '-', 'Color', COLOR_GREEN_STRONG, 'LineWidth', 2.5); % Línea más gruesa, verde fuerte
            grid on;
            legend('Sin Codificar (SISO)', 'Con STBC (MISO 2x1)', 'Location', 'southwest', 'FontSize', 9);
            title('2. Codificación Espacio-Tiempo (STBC)', 'FontSize', 12, 'FontWeight', 'bold');
            xlabel('SNR (dB)'); ylabel('BER');
            sgtitle('NIVEL 3: CONTRAMEDIDAS AVANZADAS', 'FontSize', 14, 'FontWeight', 'bold');

        case 'FILTER' % Nivel 1: Filtros
            f = linspace(0, 500, 1000);
            spec = exp(-(f-250).^2/2000); 
            noise = rand(1,1000)*0.1;
            filter_resp = ones(1,1000);
            filter_resp(480:520) = 0.01; 
            
            % Aumentar el contraste del área
            area(f, 20*log10(spec+noise), 'FaceColor', [0.9 0.6 0.6], 'EdgeColor', 'k', 'LineWidth', 0.5); hold on; 
            plot(f, 20*log10(filter_resp), 'Color', COLOR_GREEN_STRONG, 'LineWidth', 2.5); % Línea verde fuerte y gruesa
            title('NIVEL 1: FILTRADO ADAPTATIVO', 'FontSize', 14, 'FontWeight', 'bold');
            ylabel('Magnitud (dB)', 'FontSize', 10); xlabel('Frecuencia (Hz)', 'FontSize', 10);
            legend('Interferencia Detectada', 'Respuesta del Filtro', 'Location', 'southwest', 'FontSize', 9);
            ylim([-60 10]); grid on;
            
            % Mejorar la caja del filtro
            notch_center = 250;
            x_fill = [notch_center-20, notch_center+20, notch_center+20, notch_center-20];
            y_fill = [-100, -100, 0, 0];
            fill(x_fill, y_fill, [1 0.5 0], 'FaceAlpha', 0.4, 'EdgeColor', 'k', 'LineWidth', 1); % Naranja más visible
            text(notch_center, -20, 'Filtro Notch', 'HorizontalAlignment', 'center', 'Color', 'k', 'FontWeight', 'bold', 'FontSize', 10); % Texto negro
            hold off;

        case 'AGC' % Nivel 1: AGC (Para Atmospheric)
            subplot(2,1,1);
            t = 0:0.01:10;
            fading = (1 + 0.4*sin(2*pi*0.5*t) + 0.2*randn(size(t))); 
            plot(t, fading, 'Color', COLOR_ORANGE, 'LineWidth', 1.5); % Naranja más vibrante
            title('Entrada: Señal con Desvanecimiento Atmosférico', 'FontSize', 12, 'FontWeight', 'bold');
            ylabel('Amplitud', 'FontSize', 10); grid on; ylim([0 2.5]);
            
            subplot(2,1,2);
            corrected = ones(size(t)) + 0.05*randn(size(t)); 
            plot(t, corrected, 'Color', COLOR_GREEN_STRONG, 'LineWidth', 2.5); % Verde fuerte y grueso
            title('Salida: Compensación por AGC (Nivel 1)', 'FontSize', 12, 'FontWeight', 'bold');
            xlabel('Tiempo (s)', 'FontSize', 10); ylabel('Amplitud Nivelada', 'FontSize', 10);
            grid on; ylim([0 2.5]);
            sgtitle('NIVEL 1: CONTROL AUTOMÁTICO DE GANANCIA (AGC)', 'FontSize', 14, 'FontWeight', 'bold');


        case 'ACM' % Nivel 2: ACM
            % Aumentar número de puntos y color
            num_points = 500; % Más puntos para que se vea más denso
            
            subplot(1,2,1); 
            plot(randn(num_points,1)*0.5, randn(num_points,1)*0.5, '.', 'Color', COLOR_BLUE_DARK, 'MarkerSize', 8); % Puntos más grandes, azul oscuro
            title('QPSK (Ruidoso)', 'FontSize', 12, 'FontWeight', 'bold'); 
            axis([-1.5 1.5 -1.5 1.5]); axis square; grid on; % Limitar ejes y hacerlos cuadrados

            subplot(1,2,2); 
            plot([ones(num_points/2,1)*0.8; -ones(num_points/2,1)*0.8], randn(num_points,1)*0.2, '.', 'Color', COLOR_GREEN_STRONG, 'MarkerSize', 8); % Puntos más grandes, verde fuerte
            title('BPSK (Robusto)', 'FontSize', 12, 'FontWeight', 'bold'); 
            axis([-1.5 1.5 -1.5 1.5]); axis square; grid on; % Limitar ejes y hacerlos cuadrados
            sgtitle('NIVEL 2: ADAPTACIÓN DINÁMICA (ACM)', 'FontSize', 14, 'FontWeight', 'bold');

        case 'EMERGENCY' % Nivel 4: Respuesta Integral
            clf; set(gcf, 'Color', COLOR_RED_STRONG); 
            text(0.5, 0.6, '🚨 NIVEL 4 CRÍTICO 🚨', 'FontSize', 28, 'Color', 'w', 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
            text(0.5, 0.4, 'RECONFIGURACIÓN TOTAL DEL SISTEMA', 'FontSize', 20, 'Color', 'w', 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
            text(0.5, 0.3, 'Modo Seguro Activado - Enlace de Respaldo', 'FontSize', 16, 'Color', 'y', 'HorizontalAlignment', 'center');
            axis off;

        otherwise % Nominal
            clf; set(gcf, 'Color', 'w');
            text(0.5, 0.5, '✅ SISTEMA NOMINAL (Monitoreo)', 'FontSize', 24, 'HorizontalAlignment', 'center', 'Color', COLOR_GREEN_STRONG, 'FontWeight', 'bold');
            axis off;
    end
    
    drawnow;
end