function clean_signal = bypass(noisy_signal)
     if size(noisy_signal, 2) > 1
         clean_signal = noisy_signal(:, 1); 
     else
         clean_signal = noisy_signal;
     end
end