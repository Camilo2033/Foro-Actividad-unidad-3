use CamRapidaDB
go

--PROCEDIMIENTOS ALMACENADOS
-- Inserta o Actualizar
-- Insertar un nuevo cliente o actualizar sus datos si ya existe.

CREATE PROCEDURE sp_guardarCliente
    @idCliente INT,
    @nombre VARCHAR(100),
    @telefono VARCHAR(20),
    @direccion VARCHAR(100)
AS
BEGIN
    IF EXISTS (SELECT 1 FROM Cliente WHERE idCliente = @idCliente)
        UPDATE Cliente
        SET nombre = @nombre,
            telefono = @telefono,
            direccion = @direccion
        WHERE idCliente = @idCliente;
    ELSE
        INSERT INTO Cliente(nombre, telefono, direccion)
        VALUES (@nombre, @telefono, @direccion);
END;
GO

EXEC sp_guardarCliente 
	@idCliente = 1,
    @nombre = 'Juan Pérezzuuammmnnzz',
    @direccion = 'Medellín',
	@telefono = '3116495414'
go

select * from Cliente
go

--Eliminar
--Eliminar un cliente solo si no tiene pedidos asociados.

CREATE PROCEDURE sp_eliminarCliente
    @idCliente INT
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Pedido WHERE idCliente = @idCliente)
        DELETE FROM Cliente WHERE idCliente = @idCliente;
    ELSE
        PRINT 'No se puede eliminar, tiene pedidos asociados';
END;
GO



--Insertar o Actualizar un Producto

CREATE PROCEDURE sp_guardarProducto
    @idProducto INT,
    @nombre VARCHAR(100),
    @precio DECIMAL(10,2),
    @stock INT,
    @idCategoria INT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM Producto WHERE idProducto = @idProducto)
        UPDATE Producto
        SET nombre = @nombre,
            precio = @precio,
            stock = @stock,
            idCategoria = @idCategoria
        WHERE idProducto = @idProducto;
    ELSE
        INSERT INTO Producto(nombre, precio, stock, idCategoria)
        VALUES (@nombre, @precio, @stock, @idCategoria);
END;
GO

EXEC sp_guardarProducto 
	 @idProducto = 11,
    @nombre = 'Jugo Marucaya' ,
    @precio = '3444' ,
    @stock =  '-5',
    @idCategoria = 2
go

select * from Producto
select * from Categoria
select * from Cliente
go

INSERT INTO Producto(nombre, precio, stock, idCategoria)
VALUES ('Hamburguesa', '15000', '-5', '1');
go

ALTER TABLE Producto
DROP CONSTRAINT CHK_Stock_Positive;
go
--Eliminar un Producto

CREATE PROCEDURE sp_eliminarProducto
    @idProducto INT
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM DetallePedido WHERE idProducto = @idProducto)
        DELETE FROM Producto WHERE idProducto = @idProducto;
    ELSE
        PRINT 'No se puede eliminar, está en pedidos';
END;
GO
--Insertar o Actualizar Pedido

CREATE PROCEDURE sp_guardarPedido
    @idPedido INT,
    @fecha DATE,
    @estado VARCHAR(50),
    @idCliente INT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM Pedido WHERE idPedido = @idPedido)
        UPDATE Pedido
        SET fecha = @fecha,
            estado = @estado,
            idCliente = @idCliente
        WHERE idPedido = @idPedido;
    ELSE
        INSERT INTO Pedido(fecha, estado, idCliente)
        VALUES (@fecha, @estado, @idCliente);
END;
GO
--Eliminar pedido

CREATE PROCEDURE sp_eliminarPedido
    @idPedido INT
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM DetallePedido WHERE idPedido = @idPedido)
        DELETE FROM Pedido WHERE idPedido = @idPedido;
    ELSE
        PRINT 'No se puede eliminar, tiene detalles asociados';
END;
GO
--Insertar o Actualizar

CREATE PROCEDURE sp_guardarDetalle
    @idDetalle INT,
    @idPedido INT,
    @idProducto INT,
    @cantidad INT,
    @subtotal DECIMAL(10,2)
AS
BEGIN
    IF EXISTS (SELECT 1 FROM DetallePedido WHERE idDetalle = @idDetalle)
        UPDATE DetallePedido
        SET idPedido = @idPedido,
            idProducto = @idProducto,
            cantidad = @cantidad,
            subtotal = @subtotal
        WHERE idDetalle = @idDetalle;
    ELSE
        INSERT INTO DetallePedido(idPedido, idProducto, cantidad, subtotal)
        VALUES (@idPedido, @idProducto, @cantidad, @subtotal);
END;
GO
--Eliminar

CREATE PROCEDURE sp_eliminarDetalle
    @idDetalle INT
AS
BEGIN
    DELETE FROM DetallePedido WHERE idDetalle = @idDetalle;
END;
GO

select p.idPedido, c.nombre, p.estado
from Pedido p
inner join Cliente c on p.idCliente = p.idCliente
go

Select c.nombre, COUNT(p.idPedido) as totalPedido
from Cliente c
inner join Pedido p on p.idCliente = p.idCliente
Group by c.nombre
having count (p.idPedido)>1
go

select p.idPedido, c.nombre, p.estado
from Pedido p
inner join Cliente c  on p.idCliente = p.idCliente
go

--GROUP BY + HAVING Mostrar los clientes con más de 1 pedido.
SELECT c.nombre, COUNT(p.idPedido) AS totalPedidos
FROM Cliente c
INNER JOIN Pedido p ON c.idCliente = p.idCliente
GROUP BY c.nombre
HAVING COUNT(p.idPedido) > 0;
GO


--CONSULTAS CON VARIAS TABLAS con INNER JOIN (mínimo 2 tablas)
--Mostrar los productos vendidos en cada pedido con su cliente.
SELECT c.nombre, p.idPedido, pr.nombre AS producto, d.cantidad
FROM Cliente c
INNER JOIN Pedido p ON c.idCliente = p.idCliente
INNER JOIN DetallePedido d ON p.idPedido = d.idPedido
INNER JOIN Producto pr ON d.idProducto = pr.idProducto;
GO

--Consulta resumen (GROUP BY + HAVING)
--Mostrar los productos que se han vendido más de 10 veces.
SELECT pr.nombre, SUM(d.cantidad) AS totalVendido
FROM Producto pr
INNER JOIN DetallePedido d ON pr.idProducto = d.idProducto
GROUP BY pr.nombre
HAVING SUM(d.cantidad) > 2;
GO

/*Crear un procedimiento almacenado que reciba como parámetro el id de un pedido, 
busque dicho pedido en la base de datos, y si existe,muestre la información del cliente
y el pedido utilizando un INNER JOIN. Si no existe, debe devolver un mensaje indicando 
que el pedido no fue encontrado.*/

CREATE PROCEDURE sp_BuscarPedidoCliente
    @idPedido INT
AS
BEGIN
    /*
    Este procedimiento tiene como objetivo buscar un pedido en la base de datos.
    
    Funcionamiento:
    - Recibe como parámetro el id de un pedido.
    - Primero valida si el pedido existe en la tabla Pedido.
    - Si existe, realiza una consulta con INNER JOIN entre las tablas Pedido y Cliente
      para mostrar la información completa del pedido junto con los datos del cliente.
    - Si no existe, devuelve un mensaje indicando que el pedido no fue encontrado.
    
    Tablas involucradas:
    - Pedido
    - Cliente
    
    Esto permite garantizar que la información mostrada esté relacionada correctamente
    mediante la clave foránea entre Pedido y Cliente.
    */

    IF EXISTS (SELECT 1 FROM Pedido WHERE idPedido = @idPedido)
    BEGIN
        SELECT 
            P.idPedido,
            P.fecha,
            C.idCliente,
            C.nombre,
            C.direccion
        FROM Pedido P
        INNER JOIN Cliente C ON P.idCliente = C.idCliente
        WHERE P.idPedido = @idPedido;
    END
    ELSE
    BEGIN
        PRINT 'El pedido no fue encontrado en la base de datos';
    END
END;
GO

/*Crear una función que reciba el id de un cliente y retorne la cantidad total
de pedidos que ha realizado, utilizando más de una tabla.*/

CREATE FUNCTION fn_TotalPedidosCliente(@idCliente INT)
RETURNS INT
AS
BEGIN
    /*
    Esta función tiene como objetivo calcular el total de pedidos realizados por un cliente.

    Funcionamiento:
    - Recibe como parámetro el id de un cliente.
    - Realiza una consulta utilizando INNER JOIN entre las tablas Cliente y Pedido.
    - Cuenta la cantidad de pedidos asociados al cliente.
    - Retorna el total de pedidos.

    Tablas utilizadas:
    - Cliente
    - Pedido

    Esto permite conocer la actividad de compra de un cliente dentro del sistema.
    */

    DECLARE @total INT;

    SELECT @total = COUNT(P.idPedido)
    FROM Cliente C
    INNER JOIN Pedido P ON C.idCliente = P.idCliente
    WHERE C.idCliente = @idCliente;

    RETURN @total;
END;
GO

--SELECT * FROM fn_TotalPedidosCliente(1);
SELECT dbo.fn_TotalPedidosCliente(4) AS TotalPedidos;
go

/*Crear una función que reciba el id de una categoría y retorne el valor 
total del inventario (precio * stock) de los productos de esa categoría.*/
CREATE FUNCTION fn_ValorInventarioCategoria(@idCategoria INT)
RETURNS DECIMAL(10,2)
AS
BEGIN
    /*
    Esta función calcula el valor total del inventario de una categoría.

    Funcionamiento:
    - Recibe como parámetro el id de una categoría.
    - Realiza un INNER JOIN entre las tablas Categoria y Producto.
    - Multiplica el precio por el stock de cada producto.
    - Suma todos los valores para obtener el total del inventario.
    - Retorna el resultado.

    Tablas utilizadas:
    - Categoria
    - Producto

    Esto permite conocer el valor económico del inventario por categoría.
    */

    DECLARE @total DECIMAL(10,2);

    SELECT @total = SUM(P.precio * P.stock)
    FROM Categoria C
    INNER JOIN Producto P ON C.idCategoria = P.idCategoria
    WHERE C.idCategoria = @idCategoria;

    RETURN ISNULL(@total, 0);
END;
GO


/*Crear un trigger que se ejecute después de insertar un producto, validando que el stock no sea negativo.
Si el stock es negativo, se cancela la operación y se muestra un mensaje de error.*/
CREATE TRIGGER trg_ValidarStockProducto
ON Producto
AFTER INSERT
AS
BEGIN
    /*
    Este trigger se ejecuta automáticamente después de insertar un nuevo registro en la tabla Producto.

    Funcionamiento:
    - Se activa después de una operación INSERT en la tabla Producto.
    - Verifica si el valor del campo stock es negativo en los registros recién insertados.
    - Si encuentra algún producto con stock menor a 0, genera un error.
    - Se realiza un ROLLBACK para cancelar la inserción y evitar que se guarden datos inválidos.

    Tablas involucradas:
    - Producto

    Objetivo:
    - Garantizar la integridad de los datos evitando que existan productos con stock negativo.
    */

    IF EXISTS (
        SELECT 1 FROM inserted WHERE stock < 0
    )
    BEGIN
        PRINT 'Error: No se permite registrar productos con stock negativo';
        ROLLBACK TRANSACTION;
    END
END; 

Exec sp_BuscarPedidoCliente
	@idPedido = 56
go