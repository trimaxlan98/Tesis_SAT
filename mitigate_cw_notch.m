function [clean_signal, f_interference] = mitigate_cw_notch(noisy_signal, fs)
    % Asegurarnos de trabajar con double precision
    fs = double(fs);
    
    % 1. Si recibimos una Matriz de Antenas [N x 4], usamos solo la primera
    % para detectar la frecuencia (ahorramos cómputo).
    if size(noisy_signal, 2) > 1
        signal_for_detection = noisy_signal(:, 1);
    else
        signal_for_detection = noisy_signal;
    end

    % 2. Estimación Espectral
    L = length(signal_for_detection);
    [pxx, f] = pwelch(signal_for_detection, 500, 250, 1024, fs, 'centered');
    
    % 3. Encontrar pico máximo
    [~, idx] = max(10*log10(pxx));
    f_interference = f(idx);
    
    % 4. Calcular frecuencia normalizada w0
    % (Forzamos conversión a double escalar para evitar errores de tipo)
    w0 = double(f_interference / (fs/2)); 
    
    % 5. SAFETY CLAMP: iirnotch falla si w0 es exactamente 0 o 1 (o fuera de rango)
    % Mantenemos w0 dentro de un rango seguro (0.001 < w0 < 0.999)
    if w0 <= 0.001
        w0 = 0.001; 
    elseif w0 >= 0.999
        w0 = 0.999;
    end
    
    % 6. Diseño del Filtro
    BW = w0 / 15; 
    [b, a] = iirnotch(w0, BW);
    
    % 7. Aplicar el filtro
    % NOTA: Aquí sí aplicamos el filtro a TODAS las antenas si entraron varias
    clean_signal = filtfilt(b, a, noisy_signal);
end