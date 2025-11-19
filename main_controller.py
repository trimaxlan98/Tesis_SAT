import matlab.engine
import numpy as np
import time
import tensorflow as tf 
import os

def preprocess_realtime(rx_matlab_data):
    # Convierte los datos crudos de MATLAB al formato que la IA espera
    rx_np = np.array(rx_matlab_data)
    
    # --- CORRECCIÓN DE TAMAÑO (Para Simulación "Slow Motion") ---
    # La IA fue entrenada con 1000 símbolos (~4037 muestras tras upsampling).
    # La simulación actual genera 5000 símbolos (~20000 muestras).
    # Debemos recortar para que coincida con la capa de entrada de la CNN.
    target_len = 4037 
    
    if rx_np.shape[0] >= target_len:
        rx_np = rx_np[:target_len, :]
    else:
        # Padding si fuera menor (por seguridad)
        padding = np.zeros((target_len - rx_np.shape[0], rx_np.shape[1]))
        rx_np = np.vstack([rx_np, padding])
    # -----------------------------------------------------------
    
    sig = rx_np[:, 0] # Usamos la primera antena
    
    # Normalización idéntica al entrenamiento
    I = np.real(sig)
    Q = np.imag(sig)
    I = (I - np.mean(I)) / np.std(I)
    Q = (Q - np.mean(Q)) / np.std(Q)
    
    # Shape: (1, 4037, 2) -> Batch de 1 muestra
    features = np.stack([I, Q], axis=1)
    return features.reshape(1, features.shape[0], features.shape[1])

def main():
    print("🚀 Iniciando Sistema de Defensa Cognitiva (Versión Final)...")
    
    # 1. INICIAR MATLAB
    print("🔌 Conectando con MATLAB Engine...")
    eng = matlab.engine.start_matlab()
    eng.addpath(r'.', nargout=0)

    # 2. CARGAR IA
    print("🧠 Cargando Red Neuronal (CNN)...")
    model = None
    classes = ['Clean', 'CW', 'BBNJ', 'Directional']
    try:
        model = tf.keras.models.load_model('shield_ai_model.h5')
    except:
        print("⚠️ Advertencia: No se encontró 'shield_ai_model.h5'. Se usará modo bypass de IA.")
    
    # --- CONFIGURACIÓN DEL ESCENARIO ---
    # CAMBIA ESTO para probar cada caso: 'CW', 'Directional', 'Sweep'
    true_threat = 'Sweep' 
    jnr_db = 30.0  # Ajustado a 30dB para mejor visualización de la limpieza
    
    print(f"\n📡 EVENTO: Señal entrante detectada (Escenario Real: {true_threat} @ {jnr_db}dB)")
    
    # Generar señal desde MATLAB
    rx, target, params = eng.sat_scenario_gen(true_threat, jnr_db, nargout=3)
    
    # --- FASE DE INFERENCIA ---
    predicted_label = "Unknown"
    
    if model is not None:
        try:
            input_tensor = preprocess_realtime(rx)
            t0 = time.time()
            prediction_probs = model.predict(input_tensor, verbose=0)
            inference_time = (time.time() - t0) * 1000 
            
            predicted_idx = np.argmax(prediction_probs)
            predicted_label = classes[predicted_idx]
            confidence = np.max(prediction_probs) * 100
            
            print(f"🤖 DIAGNÓSTICO IA (Raw): Amenaza tipo **{predicted_label}**")
            print(f"   Confianza: {confidence:.2f}% | Tiempo: {inference_time:.1f} ms")
        except Exception as e:
            print(f"❌ Error en inferencia IA: {e}")
    
    # --- MODO PRUEBA / OVERRIDE ---
    # Como la IA aún no conoce la clase "Sweep", forzamos la etiqueta 
    if true_threat == 'Sweep':
        print("⚠️  MODO PRUEBA ACTIVO: Forzando etiqueta 'Sweep' para activar DSP RLS.")
        predicted_label = 'Sweep'

    # --- FASE DE ACTUACIÓN (MATLAB DSP) ---
    clean_signal = None
    weights = None 
    
    if predicted_label == 'CW':
        print("🛡️ ACCIÓN: Desplegando Filtro Notch Adaptativo...")
        fs = params['fs']
        clean_signal, _ = eng.mitigate_cw_notch(rx, fs, nargout=2)
        
    elif predicted_label == 'Directional':
        print("🛡️ ACCIÓN: Calculando pesos de Beamforming MVDR...")
        clean_signal, weights = eng.mitigate_beamforming_mvdr(rx, params, nargout=2)
        
    elif predicted_label == 'Sweep':
        print("🛡️ ACCIÓN: Iniciando Filtro Predictivo RLS (Anti-Chirp)...")
        fs = params['fs']
        clean_signal, _ = eng.mitigate_sweep_rls(rx, fs, nargout=2)
        
    elif predicted_label == 'BBNJ':
        print("🛡️ ACCIÓN: Interferencia banda ancha. Activando diversidad.")
        clean_signal = eng.bypass(rx, nargout=1)
        
    else: 
        print("✅ Señal limpia o desconocida. Passthrough.")
        clean_signal = eng.bypass(rx, nargout=1)

    # --- FASE DE VISUALIZACIÓN INTELIGENTE ---
    
    if clean_signal is not None:
        # 1. Calcular MSE (Con Normalización)
        clean_np = np.array(clean_signal)
        target_np = np.array(target)
        
        # --- CORRECCIÓN DE MSE ---
        # Normalizamos la señal limpia para que tenga la misma escala que el target
        # Esto soluciona el MSE de 15000
        if np.std(clean_np) > 0:
            clean_np = clean_np / np.std(clean_np)
        
        L_min = min(len(clean_np), len(target_np))
        mse = np.mean(np.abs(clean_np[:L_min] - target_np[:L_min])**2)
        print(f"📊 Reporte de Calidad: MSE Final = {mse:.4f}")

        # 2. PLOTEO ADAPTATIVO
        print("📈 Generando gráficas especializadas en MATLAB...")
        
        eng.workspace['rx_dirty'] = rx
        eng.workspace['rx_clean'] = clean_signal
        eng.workspace['fs'] = params['fs']
        
        eng.eval("figure('Name', 'Resultados de Ciberdefensa', 'NumberTitle', 'off', 'Color', 'w', 'Position', [100, 100, 1000, 600]);", nargout=0)

        # CASO A: PATRÓN DE RADIACIÓN (Directional)
        if predicted_label == 'Directional' and weights is not None:
            print("   -> Dibujando Patrón de Radiación...")
            eng.workspace['w'] = weights
            eng.workspace['d'] = params['d']
            eng.workspace['lambda'] = params['lambda']
            eng.workspace['N'] = params['N_antennas']
            eng.workspace['theta_J'] = params['theta_J']
            
            eng.eval("""
                theta = -90:0.5:90;
                Array_Factor = zeros(size(theta));
                for i = 1:length(theta)
                    v_test = exp(-1j * 2*pi * d * (0:N-1)' * sind(theta(i)) / lambda);
                    Array_Factor(i) = abs(w' * v_test);
                end
                AF_dB = 20*log10(Array_Factor / max(Array_Factor) + 1e-6);
                plot(theta, AF_dB, 'LineWidth', 2); grid on; hold on;
                xline(theta_J, '--r', 'Jammer'); xline(0, '--g', 'Satelite');
                ylim([-60 0]);
                title('Beamforming MVDR: Respuesta Espacial');
                xlabel('Angulo (Grados)'); ylabel('Ganancia (dB)');
                legend('Respuesta del Array', 'Dirección Jammer', 'Dirección Satélite');
            """, nargout=0)

        # CASO B: ESPECTROGRAMA (Sweep)
        elif predicted_label == 'Sweep':
            print("   -> Dibujando Espectrograma (Diente de Sierra)...")
            # Usamos una ventana corta (64) para alta resolución temporal
            eng.eval("subplot(2,1,1);", nargout=0)
            eng.eval("spectrogram(rx_dirty(:,1), 64, 50, 512, fs, 'yaxis');", nargout=0)
            eng.eval("title('Input: Barrido Repetitivo (Sawtooth Jamming)');", nargout=0)
            eng.eval("colormap jet; colorbar off;", nargout=0)
            
            eng.eval("subplot(2,1,2);", nargout=0)
            eng.eval("spectrogram(rx_clean(:,1), 64, 50, 512, fs, 'yaxis');", nargout=0)
            eng.eval("title('Output: Señal QPSK Recuperada (RLS Prediction Error)');", nargout=0)
            eng.eval("colorbar off;", nargout=0)

        # CASO C: ESPECTRO PSD (CW / Otros)
        else:
            print("   -> Dibujando Espectro de Potencia (PSD)...")
            eng.eval("subplot(2,1,1);", nargout=0)
            eng.eval("[p1,f1] = pwelch(rx_dirty(:,1), 500, 250, 1024, fs, 'centered');", nargout=0)
            eng.eval("plot(f1/1e6, 10*log10(p1), 'r'); grid on;", nargout=0)
            eng.eval("title('Input: Espectro Sucio'); ylabel('dB');", nargout=0)
            
            eng.eval("subplot(2,1,2);", nargout=0)
            eng.eval("[p2,f2] = pwelch(rx_clean(:,1), 500, 250, 1024, fs, 'centered');", nargout=0)
            eng.eval("plot(f2/1e6, 10*log10(p2), 'g'); grid on;", nargout=0)
            eng.eval("title('Output: Espectro Mitigado'); ylabel('dB');", nargout=0)

        print("\n✅ ¡Simulación completada!")
        input("⌨️  Presiona [ENTER] para cerrar y salir...")
    
    eng.quit()

if __name__ == "__main__":
    main()