function [clean_signal, error_log] = mitigate_sweep_rls(noisy_signal, fs)
    % INPUTS:
    % noisy_signal: Matriz [Muestras x Antenas]
    % fs: Frecuencia de muestreo (solo para referencia, RLS opera por muestras)
    
    % 1. Selección de señal (Trabajamos con una antena combinada o la primera)
    % Para RLS, usar una sola antena es suficiente para demostrar el concepto
    obs = noisy_signal(:, 1);
    
    % 2. Configuración del Filtro RLS (Recursive Least Squares)
    % Orden del filtro (Taps): 16 suele ser suficiente para chirps lineales
    M = 32; 
    
    % Factor de Olvido (Lambda): 
    % 1.0 = Memoria infinita (para señales estáticas)
    % < 1.0 = Permite rastrear cambios rápidos (Tracking). 0.98 es agresivo.
    lambda = 0.94; 
    
    rls = dsp.RLSFilter('Length', M, 'ForgettingFactor', lambda);
    
    % 3. Configuración de Cancelación de Interferencia (Predictor)
    % Intentamos predecir x(n) usando x(n-DELAY)
    % El Delay descorrelaciona el ruido blanco (QPSK) pero mantiene la correlación del Chirp.
    delay = 1;
    
    % Preparamos vectores de referencia y deseados
    % Reference: La señal retardada
    % Desired: La señal actual
    ref_signal = obs(1:end-delay);
    desired_signal = obs(delay+1:end);
    
    % 4. Ejecución del Filtro
    [y_estimate, e_error] = rls(ref_signal, desired_signal);
    
    % y_estimate = La predicción del Chirp (La interferencia aislada)
    % e_error    = La parte que no pudo predecir (NUESTRA SEÑAL QPSK)
    
    % Ajustamos longitud (el delay se comió 1 muestra)
    clean_signal = [0; e_error]; 
    
    % Devolvemos el estimado del jammer solo por si queremos graficarlo
    error_log = [0; y_estimate]; 
end