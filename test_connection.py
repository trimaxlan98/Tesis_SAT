import matlab.engine
import numpy as np
import matplotlib.pyplot as plt

def test_connection():
    print("🔌 Conectando con MATLAB...")
    eng = matlab.engine.start_matlab()
    
    # Pedimos una señal CCI para ver si genera la interferencia compleja
    print("📡 Solicitando muestra de 'CCI'...")
    iq_signal = eng.sat_scenario_gen_v2('CCI', nargout=1)
    
    # Conversión
    iq_np = np.array(iq_signal).flatten()
    
    # Visualización rápida
    I = np.real(iq_np)
    Q = np.imag(iq_np)
    
    print(f"✅ Datos recibidos. Shape original: {iq_np.shape}")
    print(f"   Muestra [0]: {iq_np[0]}")
    
    # Graficar constelación (Debería verse ruidosa por la CCI)
    plt.figure(figsize=(6,6))
    plt.scatter(I, Q, alpha=0.5, s=1)
    plt.title("Constelación Recibida desde MATLAB (Clase CCI)")
    plt.xlabel("In-Phase (I)")
    plt.ylabel("Quadrature (Q)")
    plt.grid(True)
    plt.show()
    
    eng.quit()

if __name__ == "__main__":
    test_connection()