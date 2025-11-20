import os
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '2' # Silenciar logs de TensorFlow

import matlab.engine
import numpy as np
import tensorflow as tf
import time
import random

# --- CONFIGURACIÓN ---
MODEL_PATH = 'sat_defense_cnn.h5'
CLASSES = ['Clean', 'AWGN', 'BBNJ', 'CW', 'Pulsed', 'Sweep', 'CCI', 'ACI', 'Atmospheric']
INPUT_LEN = 1024

def load_system():
    print("🚀 Iniciando Sistema de Defensa Cognitiva...")
    
    print("🔌 Conectando con MATLAB Engine...")
    eng = matlab.engine.start_matlab()
    
    print("🧠 Cargando Red Neuronal (CNN)...")
    model = tf.keras.models.load_model(MODEL_PATH)
    
    return eng, model

def preprocess_signal(iq_signal):
    """Convierte la salida de MATLAB al formato que espera la CNN (1, 1024, 2)"""
    iq_np = np.array(iq_signal).flatten()
    
    # Separar I y Q
    signal_processed = np.stack([np.real(iq_np), np.imag(iq_np)], axis=1)
    
    # Agregar dimensión de batch: (1024, 2) -> (1, 1024, 2)
    signal_batch = np.expand_dims(signal_processed, axis=0)
    return signal_batch

def mitigation_strategy(threat_type, confidence, eng):
    """Cerebro de toma de decisiones (Niveles de Mitigación)"""
    
    print(f"🤖 DIAGNÓSTICO IA: Amenaza tipo **{threat_type}**")
    print(f"   Confianza: {confidence*100:.2f}%")

    action_log = ""
    
    # --- LÓGICA JERÁRQUICA DE TESIS ---
    
    # NIVEL 0: Monitoreo
    if threat_type == 'Clean':
        action_log = "✅ ESTADO: Nominal. Manteniendo MCS actual."
    
    elif threat_type == 'Atmospheric':
        action_log = "☁️ ACCIÓN: Compensación de Fading (Automatic Gain Control)."

    # NIVEL 1: Filtrado (Frecuencia)
    elif threat_type in ['CW', 'Sweep', 'ACI']:
        action_log = f"🛡️ ACCIÓN (Nivel 1): Activando Filtros Notch Adaptativos para eliminar {threat_type}."
        # Aquí podrías llamar a eng.activate_filter() si lo tuvieras en MATLAB

    # NIVEL 2: ACM (Potencia/Codificación)
    elif threat_type in ['AWGN', 'BBNJ', 'Pulsed']:
        action_log = f"📉 ACCIÓN (Nivel 2): Degradación de enlace detectada. Cambiando Modulación QPSK -> BPSK + FEC 1/2."

    # NIVEL 3: Espacial (Beamforming)
    elif threat_type == 'CCI':
        action_log = "📡 ACCIÓN CRÍTICA (Nivel 3): Interferencia Co-Canal. Calculando Pesos de Beamforming (MVDR/Null-Steering)."
        # Simulación visual en MATLAB
        # eng.plot_beamforming_null(nargout=0) # Si tuvieras la función gráfica

    print(action_log)
    # =============== NUEVA LÍNEA MÁGICA ===============
    print("📈 Generando gráficas especializadas en MATLAB...")
    try:
        eng.visualize_mitigation(threat_type, nargout=0)
    except Exception as e:
        print(f"⚠️ Error visualizando: {e}")
    # ==================================================
    print("-" * 50)

def main():
    eng, model = load_system()
    
    try:
        # Bucle de simulación continua
        while True:
            # 1. Simular llegada de una señal aleatoria (Demo)
            # En la vida real, esto vendría del hardware SDR
            real_threat = random.choice(CLASSES)
            print(f"\n📡 EVENTO: Señal entrante desconocida detectada (Simulada como {real_threat})")
            
            # 2. Obtener datos brutos de MATLAB
            start_time = time.time()
            iq_signal = eng.sat_scenario_gen_v2(real_threat, nargout=1)
            
            # 3. Procesar y Predecir
            input_tensor = preprocess_signal(iq_signal)
            prediction = model.predict(input_tensor, verbose=0)
            
            process_time = (time.time() - start_time) * 1000
            
            # 4. Decodificar resultado
            class_idx = np.argmax(prediction)
            confidence = np.max(prediction)
            detected_threat = CLASSES[class_idx]
            
            print(f"   Tiempo de procesamiento: {process_time:.1f} ms")
            
            # 5. Ejecutar Mitigación
            mitigation_strategy(detected_threat, confidence, eng)
            
            time.sleep(2) # Pausa para leer la consola
            
    except KeyboardInterrupt:
        print("\n🛑 Sistema detenido por el usuario.")
        eng.quit()

if __name__ == "__main__":
    main()