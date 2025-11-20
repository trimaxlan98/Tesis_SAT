import numpy as np
import tensorflow as tf
from tensorflow.keras import layers, models, callbacks
from sklearn.model_selection import train_test_split
from sklearn.metrics import confusion_matrix, classification_report
import matplotlib.pyplot as plt
import seaborn as sns
import os

# --- Configuración ---
DATA_PATH = './dataset_v2/'
CLASSES = ['Clean', 'AWGN', 'BBNJ', 'CW', 'Pulsed', 'Sweep', 'CCI', 'ACI', 'Atmospheric']
INPUT_LEN = 1024

def load_data():
    print("📂 Cargando dataset...")
    X = np.load(os.path.join(DATA_PATH, 'X_train.npy'))
    y = np.load(os.path.join(DATA_PATH, 'y_train.npy'))
    
    # X tiene forma (Num_Muestras, 1024, 2) -> (I, Q) son los canales
    print(f"   Shape de entrada: {X.shape}")
    return train_test_split(X, y, test_size=0.2, random_state=42, stratify=y)

def build_model(input_shape, num_classes):
    inputs = layers.Input(shape=input_shape)
    
    # --- Bloque 1: Características Temporales Finas ---
    x = layers.Conv1D(64, kernel_size=16, padding='same', activation='relu')(inputs)
    x = layers.BatchNormalization()(x)
    x = layers.MaxPooling1D(pool_size=2)(x)
    
    # --- Bloque 2: Patrones de Modulación ---
    x = layers.Conv1D(128, kernel_size=8, padding='same', activation='relu')(x)
    x = layers.BatchNormalization()(x)
    x = layers.MaxPooling1D(pool_size=2)(x)
    
    # CORRECCIÓN AQUÍ: Faltaba el (x) al final
    x = layers.Dropout(0.3)(x) 
    
    # --- Bloque 3: Características Globales ---
    x = layers.Conv1D(256, kernel_size=4, padding='same', activation='relu')(x)
    x = layers.GlobalAveragePooling1D()(x) 
    
    # --- Clasificador ---
    x = layers.Dense(128, activation='relu')(x)
    x = layers.Dropout(0.4)(x) # Asegúrate que este también tenga (x)
    outputs = layers.Dense(num_classes, activation='softmax')(x)
    
    return models.Model(inputs, outputs)

def main():
    # 1. Preparar Datos
    X_train, X_test, y_train, y_test = load_data()
    
    # 2. Construir Modelo
    model = build_model(input_shape=(INPUT_LEN, 2), num_classes=len(CLASSES))
    model.compile(optimizer='adam', 
                  loss='sparse_categorical_crossentropy', 
                  metrics=['accuracy'])
    
    model.summary()
    
    # 3. Entrenar
    print("🚀 Iniciando entrenamiento...")
    history = model.fit(
        X_train, y_train,
        epochs=20, # Ajustar según necesidad
        batch_size=32,
        validation_data=(X_test, y_test),
        callbacks=[
            callbacks.EarlyStopping(patience=5, restore_best_weights=True),
            callbacks.ReduceLROnPlateau(factor=0.5, patience=3)
        ]
    )
    
    # 4. Guardar Modelo para el Controlador
    model.save('sat_defense_cnn.h5')
    print("💾 Modelo guardado como 'sat_defense_cnn.h5'")
    
    # 5. Evaluación Crítica para la Tesis
    print("📊 Generando reporte de evaluación...")
    y_pred_prob = model.predict(X_test)
    y_pred = np.argmax(y_pred_prob, axis=1)
    
    # Matriz de Confusión
    cm = confusion_matrix(y_test, y_pred)
    plt.figure(figsize=(10, 8))
    sns.heatmap(cm, annot=True, fmt='d', cmap='Blues', 
                xticklabels=CLASSES, yticklabels=CLASSES)
    plt.title('Matriz de Confusión: Clasificación de Interferencias')
    plt.ylabel('Clase Real')
    plt.xlabel('Predicción')
    plt.tight_layout()
    plt.show()
    
    print(classification_report(y_test, y_pred, target_names=CLASSES))

if __name__ == '__main__':
    main()