import matlab.engine
import numpy as np
import tensorflow as tf
import time
import random
import os

# Configuración
MODEL_PATH = 'sat_defense_cnn.h5'
CLASSES = ['Clean', 'AWGN', 'BBNJ', 'CW', 'Pulsed', 'Sweep', 'CCI', 'ACI', 'Atmospheric']

# Variables de Estado para Nivel 4
threat_history = []
MAX_PERSISTENCE = 3 # Si la amenaza se repite 3 veces, subimos a Nivel 4

def load_system():
    print("🚀 Iniciando Sistema de Defensa Cognitiva V3 (Alineado a Arquitectura)...")
    eng = matlab.engine.start_matlab()
    model = tf.keras.models.load_model(MODEL_PATH)
    return eng, model

def preprocess_signal(iq_signal):
    iq_np = np.array(iq_signal).flatten()
    signal_processed = np.stack([np.real(iq_np), np.imag(iq_np)], axis=1)
    return np.expand_dims(signal_processed, axis=0)

def decision_engine_v3(threat_type, confidence, eng):
    global threat_history
    
    # Actualizar historial para detectar persistencia
    threat_history.append(threat_type)
    if len(threat_history) > MAX_PERSISTENCE:
        threat_history.pop(0)
    
    # Verificar persistencia (¿Las últimas 3 son iguales y NO son Clean?)
    is_persistent = (len(threat_history) == MAX_PERSISTENCE) and \
                    (all(x == threat_type for x in threat_history)) and \
                    (threat_type != 'Clean')

    print(f"\n🤖 DIAGNÓSTICO: {threat_type} (Confianza: {confidence*100:.1f}%)")
    
    action_code = "NOMINAL"
    
    # --- LÓGICA DE NIVELES (Según ImpNiveles.png) ---

    # NIVEL 4: RESPUESTA INTEGRAL (Activado por Persistencia o Severidad Extrema)
    if is_persistent:
        print("🚨 ALERTA: Amenaza persistente detectada. Mitigación estándar fallida.")
        print("🔥 ACCIÓN (NIVEL 4): RECONFIGURACIÓN TOTAL + MODO DE EMERGENCIA")
        action_code = "EMERGENCY"
        # Resetear historial para no quedarse pegado en emergencia eternamente
        threat_history = [] 

    # NIVEL 3: CONTRAMEDIDAS AVANZADAS (CCI requiere STBC + Beamforming)
    elif threat_type == 'CCI':
        print("📡 ACCIÓN (NIVEL 3): Activando Beamforming + Codificación STBC")
        action_code = "BEAM_STBC"

    # NIVEL 2: ADAPTACIÓN DINÁMICA (ACM)
    # AWGN, BBNJ, Pulsed afectan la potencia/SNR global
    elif threat_type in ['AWGN', 'BBNJ', 'Pulsed']:
        print("📉 ACCIÓN (NIVEL 2): Ajuste Dinámico de Parámetros (ACM: QPSK->BPSK)")
        action_code = "ACM"

    # NIVEL 1: MITIGACIÓN BÁSICA (Filtros y AGC)
    # CW, Sweep, ACI son banda estrecha -> Filtros
    # Atmospheric -> AGC
    elif threat_type in ['CW', 'Sweep', 'ACI']:
        print("🛡️ ACCIÓN (NIVEL 1): Detección y Filtrado Básico (Notch)")
        action_code = "FILTER"
    
    elif threat_type == 'Atmospheric':
        print("☁️ ACCIÓN (NIVEL 1): Ajustes automáticos de ganancia (AGC)")
        action_code = "AGC"

    # NIVEL 0 / MONITOREO
    elif threat_type == 'Clean':
        print("✅ ESTADO: Nominal. Monitoreo de Espectro.")
        action_code = "NOMINAL"
        threat_history = [] # Limpiar historial si está limpio

    # --- LLAMADA A VISUALIZACIÓN V3 ---
    try:
        eng.visualize_mitigation_v4(action_code, nargout=0)
    except Exception as e:
        print(f"⚠️ Error visual: {e}")

def main():
    eng, model = load_system()
    
    try:
        while True:
            # Simulación: forzamos repetición para probar Nivel 4 a veces
            if random.random() < 0.2: 
                real_threat = 'BBNJ' # Forzar jamming persistente
            else:
                real_threat = random.choice(CLASSES)
            
            print(f"📡 SEÑAL ENTRANTE: {real_threat}...")
            
            # Generar y Predecir
            iq_signal = eng.sat_scenario_gen_v2(real_threat, nargout=1)
            pred = model.predict(preprocess_signal(iq_signal), verbose=0)
            detected = CLASSES[np.argmax(pred)]
            conf = np.max(pred)
            
            # Ejecutar Motor de Decisión V3
            decision_engine_v3(detected, conf, eng)
            
            time.sleep(2.5) # Pausa para apreciar la gráfica

    except KeyboardInterrupt:
        eng.quit()

if __name__ == "__main__":
    main()