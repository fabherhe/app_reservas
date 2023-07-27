/*
# **Sistema de Reservas**

Documentaremos el desarrollo de un sistema de reservas para un hotel. Este sistema permitirá a los usuarios reservar habitaciones, y al personal del hotel administrar las reservas.

### Esquema de la Base de Datos

Nuestra base de datos consta de tres tablas principales: \`clients\`, \`rooms\`, y \`reservations\`.

\- \`clients\`: Esta tabla contiene información sobre los clientes que pueden hacer reservas. Cada cliente tiene un \`client\_id\` único, \`name\`, \`email\`, y \`phone\_number\`.

\- \`rooms\`: Esta tabla contiene información sobre las habitaciones que pueden ser reservadas. Cada habitación tiene un \`room\_id\` único, \`capacity\`, \`description\`, y \`price\_per\_night\`.

\- \`reservations\`: Esta tabla registra las reservas realizadas por los clientes. Cada reserva tiene un \`reservation\_id\` único, el \`client\_id\` del cliente que hizo la reserva, el \`room\_id\` de la habitación reservada, las fechas de inicio y fin de la reserva (\`start\_date\`, \`end\_date\`), y el \`total\_payment\` para la reserva.

## Creación de Tablas

A continuación, crearemos nuestras tablas en la base de datos.
*/

CREATE TABLE clients (

    client_id INT PRIMARY KEY,

    name NVARCHAR(100),

    email NVARCHAR(100),

    phone_number NVARCHAR(20)

)



CREATE TABLE rooms (

    room_id INT PRIMARY KEY,

    capacity INT,

    description NVARCHAR(200),

    price_per_night DECIMAL(5,2)

)



CREATE TABLE reservations (

    reservation_id INT PRIMARY KEY,

    client_id INT,

    room_id INT,

    start_date DATE,

    end_date DATE,

    total_payment DECIMAL(7,2),

    FOREIGN KEY(client_id) REFERENCES clients(client_id),

    FOREIGN KEY(room_id) REFERENCES rooms(room_id)

)

/*
Al crear la base de datos, realizamos una conexion con Python e hicimos la inserción de datos creados con una libreria de Python, continuaremos trabajando con estos datos aleatorios (que cumplen ciertas condiciones) para hacerlos coherentes con sus columnas.
*/

/*
## Operaciones de la Base de Datos

A continuación, demostraremos algunas operaciones comunes que nuestro sistema de reservas necesita realizar.
*/

-- Insertar un nuevo cliente

INSERT INTO clients (client_id, name, email, phone_number) VALUES (1, 'John Doe', 'johndoe@example.com', '1234567890');



-- Crear una nueva reserva

INSERT INTO reservations (reservation_id, client_id, room_id, start_date, end_date, total_payment) VALUES (1, 1, 1, '2023-07-15', '2023-07-20', 500.00);



-- Buscar reservas por cliente

SELECT * FROM reservations WHERE client_id = 1;



-- Calcular el total de pagos

SELECT SUM(total_payment) FROM reservations WHERE client_id = 1;

/*
Revisamos la composición de nuestro modelo de datos, de donde empezaremos a robustecer este sistema de reservas.
*/

SELECT table_name 

FROM information_schema.tables

WHERE table_type = 'BASE TABLE' AND table_catalog = 'SistemaReservasONLY';

/*
Creamos la columna 'disponibilidad' de tipo booleano para identificar si la habitación esta disponible o no. 

Este comando agrega una nueva columna llamada 'availability' a la tabla 'rooms' con un tipo de datos BIT (booleano) y un valor predeterminado de 1, que indica que la habitación esta disponible.
*/

ALTER TABLE rooms

ADD availability BIT DEFAULT 1;

/*
Cuando añades una nueva columna a una tabla existente en SQL Server y <mark>especificas un valor por defecto, ese valor por defecto se aplica a las nuevas filas que se añaden después de que la columna ha sido creada. No se aplica a las filas existentes en la tabla en el momento de la creación de la columna.</mark>

  

Por lo tanto, si queremos que todas las filas existentes en la tabla rooms tengan un valor de 1 en la columna availability, tendremos que realizar una actualización en la tabla después de agregar la columna.

  

La razón de esto es que SQL Server (y muchos otros sistemas de gestión de bases de datos) está diseñado para realizar operaciones de modificación de esquema, como agregar una nueva columna, de la manera más eficiente posible. Llenar una nueva columna con un valor por defecto en todas las filas existentes podría ser una operación muy costosa en términos de tiempo y recursos de la base de datos, especialmente para tablas grandes. Por lo tanto, SQL Server simplemente añade la nueva columna y deja que sus valores sean NULL en las filas existentes.
*/

UPDATE rooms

SET availability = 1

WHERE availability IS NULL;

/*
**Modificar la consulta de búsqueda de habitaciones disponibles:** Para buscar habitaciones disponibles en un rango de fechas específico, puedes usar una consulta como esta:
*/

SELECT * FROM rooms

WHERE availability = 1

AND room_id NOT IN (

    SELECT room_id FROM reservations

    WHERE (start_date <= @end_date) AND (end_date >= @start_date)

);

-- as an example: 

SELECT *

FROM rooms

WHERE availability = 1

AND room_id NOT IN (

    SELECT room_id

    FROM reservations

    WHERE (start_date <= '2023-07-27') AND (end_date >= '2023-07-20')

);

/*
En este ejemplo, @start\_date y @end\_date son las fechas de inicio y fin del período que el cliente quiere reservar. Esta consulta selecciona las habitaciones que están marcadas como disponibles y que no tienen reservas que se superpongan con el rango de fechas deseado.
*/

/*
**Actualizar la creación de reservas:** Cuando creas una nueva reserva, debes actualizar la disponibilidad de la habitación reservada. Puedes hacerlo con una consulta como esta:
*/

BEGIN TRANSACTION;
INSERT INTO reservations (reservation_id, client_id, room_id, start_date, end_date, total_payment)
VALUES (@reservation_id, @client_id, @room_id, @start_date, @end_date, @total_payment);
UPDATE rooms
SET availability = 0
WHERE room_id = @room_id;
COMMIT;


/*
En este ejemplo, @reservation\_id, @client\_id, @room\_id, @start\_date, @end\_date y @total\_payment son los datos de la nueva reserva. Esta consulta inserta los datos de la nueva reserva en la tabla reservations, y luego actualiza la disponibilidad de la habitación reservada para indicar que está ocupada.
*/

/*
**Liberar la habitación al finalizar la reserva:** Para liberar la habitación al finalizar la reserva, necesitarías un proceso automatizado que se ejecute a diario y que actualice la disponibilidad de las habitaciones cuyas reservas hayan finalizado. Aquí te dejo un ejemplo de cómo podría ser esa consulta:
*/

UPDATE rooms
SET availability = 1
WHERE room_id IN (
    SELECT room_id FROM reservations
    WHERE end_date < GETDATE()
);