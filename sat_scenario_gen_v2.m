function iq_signal = sat_scenario_gen_v2(label_type)
% SAT_SCENARIO_GEN_V2 Generador de formas de onda para Dataset de Tesis
% Entradas:
%   label_type: String con el nombre de la clase ('Clean', 'CCI', etc.)
% Salida:
%   iq_signal: Vector complejo (1xN) normalizado
%
% Autor: Tu Asistente de IA
% Contexto: Tesis de Defensa Cognitiva Satelital

    % --- 1. Configuración Global ---
    N = 1024;           % Longitud de la secuencia (samples)
    Fs = 1e6;           % Frecuencia de muestreo (1 MHz)
    Fc = 0;             % Banda base
    t = (0:N-1)/Fs;     % Vector de tiempo
    
    % Parámetros de Variabilidad (Para que la IA generalice mejor)
    % SNR alto para Clean, bajo para ataques
    snr_high = 20 + 5*rand();  % Entre 20 y 25 dB
    snr_low = 5 + 5*rand();    % Entre 5 y 10 dB
    jsr_val = 0 + 5*rand();    % Jammer-to-Signal Ratio (0 a 5 dB más fuerte que la señal)

    % --- 2. Generar Señal Legítima (Usuario) ---
    % Usamos QPSK como estándar satelital robusto
    data_syms = randi([0 3], N/4, 1); % 4 muestras por símbolo aprox
    mod_sig = pskmod(data_syms, 4, pi/4);
    % Sobremuestreo para dar forma a la onda
    tx_sig = rectpulse(mod_sig, 4); 
    % Recortar o rellenar para asegurar longitud N
    tx_sig = tx_sig(1:N).'; 
    
    % --- 3. Inyección de Interferencias/Escenarios ---
    
    switch label_type
        case 'Clean'
            % Señal limpia + ruido térmico base (SNR alto)
            iq_signal = awgn(tx_sig, snr_high, 'measured');
            
        case 'AWGN'
            % Señal enterrada en ruido (SNR muy bajo)
            iq_signal = awgn(tx_sig, -5, 'measured'); % SNR negativo (-5 dB)
            
        case 'BBNJ' % Broadband Noise Jamming
            % Ruido blanco de alta potencia cubriendo toda la banda
            noise_jammer = wgn(1, N, 0, 'complex');
            % Escalamos el jammer para cumplir el JSR
            sig_power = bandpower(tx_sig);
            jam_power = sig_power * 10^(jsr_val/10);
            noise_jammer = noise_jammer * sqrt(jam_power/bandpower(noise_jammer));
            
            iq_signal = tx_sig + noise_jammer;
            iq_signal = awgn(iq_signal, snr_high, 'measured');
            
        case 'CW' % Continuous Wave (Tono Puro)
            % Interferencia de banda estrecha
            f_tone = (Fs/4) * (rand() - 0.5); % Frecuencia aleatoria dentro de la banda
            jam_tone = exp(1j*2*pi*f_tone*t);
            
            % Potencia del tono
            sig_power = bandpower(tx_sig);
            jam_tone = jam_tone * sqrt((sig_power * 10^(jsr_val/10)));
            
            iq_signal = tx_sig + jam_tone;
            iq_signal = awgn(iq_signal, snr_high, 'measured');
            
        case 'Pulsed' % Jamming Pulsado
            % Ruido que se enciende y apaga
            duty_cycle = 0.3; % 30% del tiempo activo
            mask = rand(1, N) < duty_cycle;
            pulsed_noise = wgn(1, N, 10, 'complex') .* mask; % Potencia alta (10dBW)
            
            iq_signal = tx_sig + pulsed_noise;
            iq_signal = awgn(iq_signal, snr_high, 'measured');
            
        case 'Sweep' % Frequency Sweep (Chirp)
            % Barrido de frecuencia que cruza la banda
            sweep_sig = chirp(t, -Fs/4, t(end), Fs/4, 'linear', 0, 'complex');
            % Ajuste de potencia
            sig_power = bandpower(tx_sig);
            sweep_sig = sweep_sig * sqrt((sig_power * 10^(jsr_val/10)));
            
            iq_signal = tx_sig + sweep_sig;
            iq_signal = awgn(iq_signal, snr_high, 'measured');

        case 'CCI' % Co-Channel Interference (EL RETO PRINCIPAL)
            % Otra señal QPSK en la MISMA frecuencia, pero distintos datos
            int_syms = randi([0 3], N/4, 1);
            int_mod = pskmod(int_syms, 4, pi/4);
            int_sig = rectpulse(int_mod, 4);
            int_sig = int_sig(1:N).';
            
            % A menudo la CCI llega con una potencia similar o ligeramente menor
            scale_factor = 0.8 + 0.4*rand(); % 0.8x a 1.2x de amplitud
            
            iq_signal = tx_sig + (int_sig * scale_factor);
            iq_signal = awgn(iq_signal, snr_high, 'measured');
            
        case 'ACI' % Adjacent Channel Interference
            % Señal similar pero desplazada en frecuencia
            int_syms = randi([0 3], N/4, 1);
            int_mod = pskmod(int_syms, 4, pi/4);
            int_sig = rectpulse(int_mod, 4);
            int_sig = int_sig(1:N).';
            
            % Desplazamiento de frecuencia (hacia el borde de la banda)
            f_offset = Fs/3; 
            aci_sig = int_sig .* exp(1j*2*pi*f_offset*t);
            
            % La ACI suele ser potente pero filtrada parcialmente (simulamos potencia alta)
            iq_signal = tx_sig + (aci_sig * 1.5);
            iq_signal = awgn(iq_signal, snr_high, 'measured');
            
        case 'Atmospheric'
            % Simulamos Canal Rician (Linea de vista + rebotes)
            % Esto altera la amplitud y fase aleatoriamente (fading)
            h = comm.RicianChannel(...
                'SampleRate', Fs, ...
                'KFactor', 3, ... % K bajo = más severo
                'MaximumDopplerShift', 50); % Dinámico
            
            % El canal requiere entrada en columna
            iq_faded = step(h, tx_sig.'); 
            iq_signal = iq_faded.' + 0; % Transponer de vuelta
            iq_signal = awgn(iq_signal, snr_low, 'measured'); % SNR sufre por lluvia
            
        otherwise
            error('Clase desconocida: %s', label_type);
    end

    % --- 4. Normalización Final ---
    % Crucial para Redes Neuronales: mantener amplitud entre -1 y 1 aprox
    max_val = max(abs(iq_signal));
    if max_val > 0
        iq_signal = iq_signal / max_val;
    end
    
    % Asegurar formato correcto para Python
    iq_signal = complex(double(real(iq_signal)), double(imag(iq_signal)));
end