function [Rx_Signal, Target_Signal, Params] = sat_scenario_gen(threat_type, JNR_dB)
    % INPUTS:
    % threat_type: 'CW', 'BBNJ', 'Directional', 'Sweep', 'Clean'
    % JNR_dB: Jammer-to-Noise Ratio
    
    %% 1. Parámetros del Sistema
    Params.fs = 10e6;           % 10 MHz
    Params.fc = 2e9;            % 2 GHz
    
    % CAMBIO CRÍTICO: 5000 símbolos para simulación más larga (Slow Motion)
    % Esto permite que el espectrograma capture el movimiento del Chirp.
    Params.num_symbols = 5000;  
    
    Params.M = 4;               % QPSK
    Params.N_antennas = 4;      % Array ULA
    Params.lambda = 3e8 / Params.fc; 
    Params.d = Params.lambda / 2; 
    
    % Ángulos de llegada
    Params.theta_S = 0;    % Satélite (Boresight)
    Params.theta_J = 45;   % Jammer
    
    %% 2. Generación de la Señal Legítima (Target)
    data = randi([0 Params.M-1], Params.num_symbols, 1);
    mod_sig = pskmod(data, Params.M, pi/4); 
    
    % Pulse Shaping
    rolloff = 0.35; span = 10; sps = 4; 
    rrcFilter = rcosdesign(rolloff, span, sps);
    tx_signal = upfirdn(mod_sig, rrcFilter, sps);
    
    % Normalización
    tx_signal = tx_signal / std(tx_signal);
    L = length(tx_signal);
    
    %% 3. Vectores de Dirección (Steering Vectors)
    % Vector del Satélite
    v_st_S = exp(-1j * 2*pi * Params.d * (0:Params.N_antennas-1)' * sind(Params.theta_S) / Params.lambda);
    % Vector del Jammer
    v_st_J = exp(-1j * 2*pi * Params.d * (0:Params.N_antennas-1)' * sind(Params.theta_J) / Params.lambda);
    
    %% 4. Generación de la Amenaza (Jammer)
    t = (0:L-1)' / Params.fs;
    Jammer_Waveform = zeros(L, 1);
    
    % Potencia
    noise_pwr = 1; 
    jammer_pwr = noise_pwr * 10^(JNR_dB/10);
    A_J = sqrt(jammer_pwr); 
    
    switch threat_type
        case 'CW'
            f_jam = 1e6; % Tono en 1 MHz
            Jammer_Waveform = A_J * exp(1j * 2*pi * f_jam * t);
            
        case 'BBNJ'
            % Ruido blanco
            Jammer_Waveform = sqrt(jammer_pwr/2) * (randn(L,1) + 1j*randn(L,1));
            
        case 'Directional'
            % Señal modulada (similar a la legítima)
            data_J = randi([0 Params.M-1], Params.num_symbols, 1);
            mod_J = pskmod(data_J, Params.M, pi/4);
            sig_J = upfirdn(mod_J, rrcFilter, sps);
            sig_J = sig_J(1:L); % Ajuste de longitud
            Jammer_Waveform = A_J * (sig_J / std(sig_J));
            
        case 'Sweep' 
            % --- LOGICA DE DIENTE DE SIERRA (SAWTOOTH) ---
            % Generamos 4 barridos completos en el tiempo de simulación
            f_start = -2e6; % Barrido desde -2 MHz
            f_stop =  2e6;  % Hasta +2 MHz
            
            num_sweeps = 4;
            duration = (L/Params.fs);
            T_single = duration / num_sweeps;
            
            % Pendiente (Chirp rate)
            k = (f_stop - f_start) / T_single;
            
            % Generación de fase manual (modulo time)
            t_mod = mod(t, T_single);
            phase = 2*pi * (f_start .* t_mod + 0.5 * k * t_mod.^2);
            
            Jammer_Waveform = A_J * exp(1j * phase);
            
        case 'Clean'
            Jammer_Waveform = zeros(L, 1);
            
        otherwise
            Jammer_Waveform = zeros(L, 1);
    end
    
    %% 5. Modelo de Canal
    ricianChan = comm.RicianChannel(...
        'SampleRate', Params.fs, ...
        'KFactor', 10, ...
        'DirectPathDopplerShift', 0);
    
    faded_signal = ricianChan(tx_signal);
    
    %% 6. Mezcla Final
    % Expansión espacial
    Signal_Component = faded_signal * v_st_S.';
    Jammer_Component = Jammer_Waveform * v_st_J.';
    Thermal_Noise = (randn(L, Params.N_antennas) + 1j*randn(L, Params.N_antennas)) * sqrt(noise_pwr/2);
    
    % Suma Total
    Rx_Signal = Signal_Component + Jammer_Component + Thermal_Noise;
    
    % Referencia limpia para cálculo de BER/MSE
    Target_Signal = tx_signal; 
end