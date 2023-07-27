import streamlit as st
import pandas as pd
from sqlalchemy import create_engine, text

# Configuración de la conexión a la base de datos
server = 'sistema-reservas-only.database.windows.net'
database = 'SistemaReservasONLY'
username = 'admin-sistema-reservas-only'
password = 'nosequeponer1234.'
engine = create_engine(f'mssql+pymssql://{username}:{password}@{server}/{database}')

# Agregar un título a la aplicación
st.title('Sistema de reservas del hotel X')

# Crear un cuadro de entrada de texto para que el usuario introduzca un ID de cliente
client_id = st.text_input('Introduce un ID de cliente')

# Crear una entrada de fecha para que el usuario introduzca una fecha de reserva
reservation_date = st.date_input('Introduce una fecha de reserva')

# Crear un cuadro de entrada de texto para que el usuario introduzca un ID de habitación
room_id = st.text_input('Introduce un ID de habitación')

if client_id:
    # Ejecutar una consulta SQL basada en el ID de cliente introducido por el usuario
    with engine.connect() as connection:
        query = text('SELECT * FROM reservations WHERE client_id = :client_id')
        result = connection.execute(query, client_id=client_id)
        df = pd.DataFrame(result, columns=result.keys())
    
    # Mostrar los resultados de la consulta en la aplicación
    st.subheader(f'Reservations for client {client_id}')
    st.dataframe(df)

if reservation_date:
    # Ejecutar una consulta SQL para buscar reservas en la fecha introducida por el usuario
    with engine.connect() as connection:
        query = text('SELECT * FROM reservations WHERE start_date <= :reservation_date AND end_date >= :reservation_date')
        result = connection.execute(query, reservation_date=reservation_date)
        df = pd.DataFrame(result, columns=result.keys())

    # Mostrar los resultados de la consulta en la aplicación
    st.subheader(f'Reservations for date {reservation_date}')
    st.dataframe(df)

if room_id:
    # Ejecutar una consulta SQL para buscar información sobre la habitación introducida por el usuario
    with engine.connect() as connection:
        query = text('SELECT * FROM rooms WHERE room_id = :room_id')
        result = connection.execute(query, room_id=room_id)
        df = pd.DataFrame(result, columns=result.keys())

    # Mostrar los resultados de la consulta en la aplicación
    st.subheader(f'Information for room {room_id}')
    st.dataframe(df)

