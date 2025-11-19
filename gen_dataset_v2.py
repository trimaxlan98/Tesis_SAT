import matlab.engine
import numpy as np
import os
from tqdm import tqdm # Para barra de progreso

# Configuración
CLASSES = ['Clean', 'AWGN', 'BBNJ', 'CW', 'Pulsed', 'Sweep', 'CCI', 'ACI', 'Atmospheric']
SAMPLES_PER_CLASS = 1000
DATA_PATH = './dataset_v2/'

def generate_data():
    print("🔌 Iniciando MATLAB Engine...")
    eng = matlab.engine.start_matlab()
    
    if not os.path.exists(DATA_PATH):
        os.makedirs(DATA_PATH)

    print(f"🚀 Generando {SAMPLES_PER_CLASS} muestras para {len(CLASSES)} clases...")

    all_data = []
    all_labels = []

    for idx, label in enumerate(CLASSES):
        print(f"📡 Generando clase: {label}")
        for i in tqdm(range(SAMPLES_PER_CLASS)):
            # Llamada a tu script de MATLAB
            # Asumimos que devuelve un array complejo de tamaño 1x1024 (ejemplo)
            # Pasamos el label para que MATLAB sepa qué inyectar
            iq_signal = eng.sat_scenario_gen_v2(label, nargout=1)
            
            # Convertir de MATLAB array a Numpy
            iq_np = np.array(iq_signal).flatten()
            
            # Separar I y Q para la CNN (Canales reales)
            # Formato final: [Longitud, 2] -> (I, Q)
            signal_processed = np.stack([np.real(iq_np), np.imag(iq_np)], axis=1)
            
            all_data.append(signal_processed)
            all_labels.append(idx)

    # Guardar como .npy para carga ultra-rápida en el entrenamiento
    np.save(os.path.join(DATA_PATH, 'X_train.npy'), np.array(all_data))
    np.save(os.path.join(DATA_PATH, 'y_train.npy'), np.array(all_labels))
    
    eng.quit()
    print("✅ Dataset generado y guardado exitosamente.")

if __name__ == '__main__':
    generate_data()