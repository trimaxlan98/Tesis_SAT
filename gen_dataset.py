import matlab.engine
import numpy as np
import os

def generate_dataset():
    print("🚀 Iniciando Motor MATLAB para generación de datos...")
    eng = matlab.engine.start_matlab()
    eng.addpath(r'.', nargout=0)

    # Configuración
    classes = ['Clean', 'CW', 'BBNJ', 'Directional']
    samples_per_class = 200  # 200 x 4 = 800 ejemplos en total (Suficiente para demo)
    dataset_X = []
    dataset_y = []

    print(f"📊 Generando {samples_per_class} muestras por cada una de las {len(classes)} clases...")

    for label_idx, threat in enumerate(classes):
        for i in range(samples_per_class):
            # Variamos el JNR para que la IA aprenda a detectar señales fuertes y débiles
            # JNR aleatorio entre 10dB y 30dB
            jnr_db = float(np.random.randint(10, 30)) 
            
            # Llamada a MATLAB
            # Solo necesitamos Rx_Signal (la sucia)
            rx_matlab = eng.sat_scenario_gen(threat, jnr_db, nargout=3)[0]
            
            # --- PRE-PROCESAMIENTO (Crucial) ---
            # 1. Convertir a Numpy
            rx_np = np.array(rx_matlab) # Shape: [1000, 4] (Muestras, Antenas)
            
            # 2. Tomamos solo la Antena 1 (Suficiente para clasificar tipo de señal)
            # Si quisiéramos detectar Ángulo, usaríamos las 4.
            signal_ant1 = rx_np[:, 0]
            
            # 3. Separar I (Real) y Q (Imaginario)
            # Las redes neuronales no entienden complejos nativamente, así que los apilamos.
            I = np.real(signal_ant1)
            Q = np.imag(signal_ant1)
            
            # 4. Normalización (Para que la IA vea formas, no amplitudes absolutas)
            # Restamos media y dividimos por desviación estándar
            I = (I - np.mean(I)) / np.std(I)
            Q = (Q - np.mean(Q)) / np.std(Q)
            
            # Stack: Shape final (1000, 2)
            features = np.stack([I, Q], axis=1)
            
            dataset_X.append(features)
            dataset_y.append(label_idx) # 0, 1, 2 o 3
            
            if i % 50 == 0:
                print(f"   [{threat}] Progreso: {i}/{samples_per_class}")

    # Convertir a arrays de Numpy
    X = np.array(dataset_X) # Shape: (Total, 1000, 2)
    y = np.array(dataset_y) # Shape: (Total,)

    # Guardar en disco
    np.savez('sat_dataset.npz', X=X, y=y)
    print("✅ Dataset guardado en 'sat_dataset.npz'")
    eng.quit()

if __name__ == "__main__":
    generate_dataset()