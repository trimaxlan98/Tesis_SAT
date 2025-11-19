function [clean_signal, weights] = mitigate_beamforming_mvdr(Rx_Matrix, Params)
    [N_samples, N_antennas] = size(Rx_Matrix);
    Rxx = (Rx_Matrix' * Rx_Matrix) / N_samples;
    Rxx = Rxx + 0.01 * eye(N_antennas); 
    theta_deseado = Params.theta_S;
    v_steer = exp(-1j * 2*pi * Params.d * (0:N_antennas-1)' * sind(theta_deseado) / Params.lambda);
    R_inv = inv(Rxx);
    numerador = R_inv * v_steer;
    denominador = v_steer' * R_inv * v_steer;
    w_opt = numerador / denominador;
    clean_signal = Rx_Matrix * w_opt; 
    weights = w_opt;
end