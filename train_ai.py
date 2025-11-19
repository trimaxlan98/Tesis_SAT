import numpy as np
import tensorflow as tf
from tensorflow.keras import layers, models
from sklearn.model_selection import train_test_split
import matplotlib.pyplot as plt

def train_model():
    # 1. Cargar Datos
    print("📂 Cargando dataset...")
    data = np.load('sat_dataset.npz')
    X = data['X']
    y = data['y']
    
    # Clases: 0:Clean, 1:CW, 2:BBNJ, 3:Directional
    
    # 2. Split Train/Test (80% entrenar, 20% validar)
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
    
    input_shape = X_train.shape[1:] # (1000, 2)
    num_classes = 4

    # 3. Arquitectura CNN 1D (Optimizada para RF)
    model = models.Sequential([
        # Capa de entrada
        layers.Input(shape=input_shape),
        
        # Bloque Convolucional 1: Detecta características simples (picos, ruido)
        layers.Conv1D(filters=32, kernel_size=32, activation='relu'),
        layers.MaxPooling1D(pool_size=2),
        
        # Bloque Convolucional 2: Detecta patrones más complejos
        layers.Conv1D(filters=64, kernel_size=16, activation='relu'),
        layers.MaxPooling1D(pool_size=2),
        
        # Reducción de dimensiones
        layers.GlobalAveragePooling1D(), # Promedia toda la señal temporalmente
        
        # Clasificador Denso
        layers.Dense(64, activation='relu'),
        layers.Dropout(0.3), # Evita memorización (overfitting)
        layers.Dense(num_classes, activation='softmax') # Salida de probabilidad
    ])

    model.compile(optimizer='adam',
                  loss='sparse_categorical_crossentropy',
                  metrics=['accuracy'])
    
    model.summary()

    # 4. Entrenamiento
    print("🧠 Entrenando red neuronal...")
    history = model.fit(X_train, y_train, epochs=10, validation_data=(X_test, y_test), batch_size=32)

    # 5. Guardar el modelo
    model.save('shield_ai_model.h5')
    print("✅ Modelo guardado como 'shield_ai_model.h5'")
    
    # Evaluación Final
    test_loss, test_acc = model.evaluate(X_test, y_test, verbose=2)
    print(f'\nPrecisión en Test: {test_acc*100:.2f}%')

if __name__ == "__main__":
    train_model()