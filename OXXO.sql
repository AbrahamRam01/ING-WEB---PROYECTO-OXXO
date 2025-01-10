drop database OXXO;
create database OXXO;
use OXXO;

create table tipoUsuario(
id_tipUsuario INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
tipoUsuario VARCHAR(100) NOT NULL
);

create table usuario(
id_usu INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
id_tipUsuario INT NOT NULL,
nombreUsuario VARCHAR(40) NOT NULL,
contrasena VARCHAR(20) NOT NULL,
nombre VARCHAR(70) NOT NULL,
apellidoPaterno VARCHAR(70) NOT NULL,
apellidoMaterno VARCHAR(70) NOT NULL,
telefono VARCHAR(150) NOT NULL CHECK (LENGTH(telefono) = 10),
correo VARCHAR(150) NOT NULL,
direccion VARCHAR(255) NOT NULL,
fechaNacimiento DATE NOT NULL,
estado VARCHAR(100) NOT NULL,
CONSTRAINT FOREIGN KEY (id_tipUsuario) REFERENCES tipoUsuario(id_tipUsuario) ON DELETE CASCADE ON UPDATE CASCADE
);

create table proveedor(
id_prov INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
nombre VARCHAR(255) NOT NULL,
RFC VARCHAR(16) NOT NULL CHECK(LENGTH(RFC)=16),
telefono VARCHAR(255) NOT NUlL CHECK(LENGTH(telefono)=10),
correo VARCHAR(255) NOT NULL,
direccion VARCHAR(255) NOT NULL,
estado VARCHAR(100) NOT NULL
);

create table tipoProducto(
id_tipoProducto INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
tipoProducto VARCHAR(100) NOT NULL
);

create table impuesto(
id_imp INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
nombreImpuesto VARCHAR(255) NOT NULL,
porcentajeImpuesto DECIMAL(10,5) NOT NULL,
tipoImpuesto VARCHAR(30) NOT NULL,
estado VARCHAR(100) NOT NULL
);

create table productoCatalogo(
id_pro INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
id_prov INT NOT NULL,
id_tipoProducto INT NOT NULL,
id_imp INT,
nombreProducto VARCHAR(255) NOT NULL,
costoProducto DECIMAL(10,2) NOT NULL,
precioVenta DECIMAL(10,2) NOT NULL,
unidadMedida VARCHAR(100) NOT NULL,
cantidadStock DECIMAL(10,2) NOT NULL,
estado VARCHAR(100) NOT NULL,
CONSTRAINT FOREIGN KEY (id_prov) REFERENCES proveedor(id_prov) ON DELETE CASCADE ON UPDATE CASCADE,
CONSTRAINT FOREIGN KEY (id_tipoProducto) REFERENCES tipoProducto(id_tipoProducto) ON DELETE CASCADE ON UPDATE CASCADE,
CONSTRAINT FOREIGN KEY (id_imp) REFERENCES impuesto(id_imp) ON DELETE CASCADE ON UPDATE CASCADE
);

create table venta(
id_ven INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
id_usu INT NOT NULL,
fecha DATETIME NOT NULL,
subtotal DECIMAL(10,2) NOT NULL,
impuestos DECIMAL(10,2) NOT NULL,
total DECIMAL(10,2) NOT NULL,
CONSTRAINT FOREIGN KEY (id_usu) REFERENCES usuario(id_usu) ON DELETE CASCADE ON UPDATE CASCADE
);

create table relacion_producto_venta(
id_rel INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
id_ven INT NOT NULL,
id_pro INT NOT NULL,
cantidad DECIMAL(10,2) NOT NULL,
impuestos DECIMAL(10,2) NOT NULL,
subtotal DECIMAL(10,2) NOT NULL,
CONSTRAINT FOREIGN KEY (id_ven) REFERENCES venta(id_ven) ON DELETE CASCADE ON UPDATE CASCADE,
CONSTRAINT FOREIGN KEY (id_pro) REFERENCES productoCatalogo(id_pro) ON DELETE CASCADE ON UPDATE CASCADE
);

DELIMITER //
CREATE PROCEDURE validarStock(IN idProducto INT, IN cantidad DECIMAL(10,2))
BEGIN
    SELECT * FROM productoCatalogo WHERE id_pro = idProducto AND cantidadStock >= cantidad;
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE operacionAlmacen(IN idProducto INT, IN cantidad DECIMAL(10,2), IN tipoOperacion INT)
BEGIN
	IF tipoOperacion = 1 THEN
		UPDATE productoCatalogo SET cantidadStock = cantidadStock + cantidad WHERE id_pro = idProducto;
	ELSE
		UPDATE productoCatalogo SET cantidadStock = cantidadStock - cantidad WHERE id_pro = idProducto;
	END IF;
END //
DELIMITER ;

DELIMITER //
CREATE TRIGGER actualizarStock
AFTER INSERT ON relacion_producto_venta
FOR EACH ROW
BEGIN
    UPDATE productoCatalogo SET cantidadStock = cantidadStock - NEW.cantidad WHERE id_pro = NEW.id_pro;
END //
DELIMITER ;

DELIMITER //
CREATE TRIGGER aumentarImpuesto
BEFORE INSERT ON productoCatalogo
FOR EACH ROW
BEGIN
    SET NEW.precioVenta = NEW.precioVenta + NEW.precioVenta*(0.01*(SELECT porcentajeImpuesto FROM impuesto WHERE id_imp = NEW.id_imp));
END //
DELIMITER ;

INSERT INTO tipoUsuario VALUES (1,'Administrador'),(2,'Trabajador'),(3,'Comprador');

INSERT INTO usuario VALUES (default,1,'ADMIN','ADMIN1234','ADMIN','ADMIN','ADMIN',552100889,'admin@oxxo.com','Donde Sea','2000-01-01','Activo'),
(NULL, 1, 'juan_perez', 'claveSegura1', 'Juan', 'Pérez', 'Gómez', 123456789, 'juan.perez@gmail.com', 'Calle 123, Ciudad A', '1990-05-15','Activo'),
(NULL, 2, 'maria.gonzalez', 'contraseña123', 'María', 'González', 'López', 987654321, 'maria.gonzalez@hotmail.com', 'Avenida XYZ, Ciudad B', '1985-08-22','Activo'),
(NULL, 3, 'carlos92', 'seguraCarlos#', 'Carlos', 'Martínez', 'Rodríguez', 456789012, 'carlos.martinez@yahoo.com', 'Plaza Principal, Ciudad C', '1992-03-10','Activo'),
(NULL, 2, 'ana_sanchez', 'claveAna567', 'Ana', 'Sánchez', 'Hernández', 321098765, 'ana.sanchez@gmail.com', 'Carrera 456, Ciudad D', '1988-12-05','Activo'),
(NULL, 1, 'pedro95', 'passwordPedro*', 'Pedro', 'López', 'Fernández', 210987654, 'pedro.lopez@gmail.com', 'Bulevar ABC, Ciudad E', '1995-07-18','Activo'),
(NULL, 2, 'laura_gomez', 'laura1983!', 'Laura', 'Gómez', 'Vargas', 789012345, 'laura.gomez@yahoo.com', 'Calle 678, Ciudad F', '1983-09-30','Activo'),
(NULL, 1, 'miguelF', 'miguel123#', 'Miguel', 'Fernández', 'Díaz', 543210987, 'miguel.fernandez@hotmail.com', 'Avenida 901, Ciudad G', '1998-02-14','Activo'),
(NULL, 2, 'sofia_r', 'sofia_86#', 'Sofía', 'Ramírez', 'Castro', 679012345, 'sofia.ramirez@gmail.com', 'Plaza Central, Ciudad H', '1986-11-25','Activo'),
(NULL, 1, 'javierH', 'claveJavier87', 'Javier', 'Hernández', 'Luna', 123456890, 'javier.hernandez@yahoo.com', 'Carrera 234, Ciudad I', '1993-06-08','Activo'),
(NULL, 3, 'diana.t', 'diana1990*', 'Diana', 'Torres', 'Soto', 987654210, 'diana.torres@hotmail.com', 'Bulevar 567, Ciudad J', '1990-04-03','Activo'),
(NULL, 1, 'luisG', 'luisG87*', 'Luis', 'Gutiérrez', 'Gálvez', 456789013, 'luis.gutierrez@gmail.com', 'Avenida 890, Ciudad K', '1987-10-12','Activo'),
(NULL, 2, 'elena_cruz', 'elenaCruz96#', 'Elena', 'Cruz', 'Mendoza', 543210876, 'elena.cruz@yahoo.com', 'Plaza de la Paz, Ciudad L', '1996-01-27','Activo'),
(NULL, 1, 'robertoR', 'rR1984#', 'Roberto', 'Ramos', 'Jiménez', 210987643, 'roberto.ramos@gmail.com', 'Calle 123, Ciudad M', '1984-08-15','Activo'),
(NULL, 2, 'fernanda_ortega', 'fernanda1991#', 'Fernanda', 'Ortega', 'Nuñez', 789012456, 'fernanda.ortega@hotmail.com', 'Avenida XYZ, Ciudad N', '1991-02-28','Activo'),
(NULL, 3, 'hugo.V', 'hugoV97#', 'Hugo', 'Vega', 'Silva', 543210987, 'hugo.vega@gmail.com', 'Plaza Principal, Ciudad O', '1997-05-20','Activo'),
(NULL, 2, 'sara.castillo', 'saraC89*', 'Sara', 'Castillo', 'Paredes', 679012345, 'sara.castillo@yahoo.com', 'Carrera 456, Ciudad P', '1989-12-01','Activo'),
(NULL, 1, 'ricardo.p', 'ricardoP94#', 'Ricardo', 'Pérez', 'Ruíz', 123456789, 'ricardo.perez@gmail.com', 'Bulevar ABC, Ciudad Q', '1994-06-14','Activo'),
(NULL, 2, 'alicia.garcia', 'aliciaG1982#', 'Alicia', 'García', 'Ortiz', 987654321, 'alicia.garcia@hotmail.com', 'Calle 678, Ciudad R', '1982-09-23','Activo'),
(NULL, 1, 'martin.jimenez', 'martinJ1999*', 'Martín', 'Jiménez', 'González', 456789012, 'martin.jimenez@yahoo.com', 'Avenida 901, Ciudad S', '1999-04-06','Activo'),
(NULL, 2, 'isabel.morales', 'isabelM1981*', 'Isabel', 'Morales', 'Sánchez', 321098765, 'isabel.morales@gmail.com', 'Plaza Central, Ciudad T', '1981-07-30','Activo'),
(NULL, 1, 'alejandro.ruiz', 'alejandroR92*', 'Alejandro', 'Ruíz', 'Pérez', 123456890, 'alejandro.ruiz@yahoo.com', 'Carrera 234, Ciudad U', '1992-02-14','Activo'),
(NULL, 2, 'carmen.soto', 'carmenS88*', 'Carmen', 'Soto', 'López', 987654210, 'carmen.soto@hotmail.com', 'Bulevar 567, Ciudad V', '1988-05-27','Activo'),
(NULL, 1, 'diego_vargas', 'diegoV95#', 'Diego', 'Vargas', 'Gómez', 210987654, 'diego.vargas@gmail.com', 'Avenida 890, Ciudad W', '1995-10-10','Activo'),
(NULL, 2, 'gabriela.g', 'gabrielaG83*', 'Gabriela', 'Gálvez', 'Torres', 679012345, 'gabriela.galvez@yahoo.com', 'Plaza de la Paz, Ciudad X', '1983-03-25','Activo'),
(NULL, 3, 'francisco_luna', 'franciscoL90*', 'Francisco', 'Luna', 'Ramírez', 123456789, 'francisco.luna@gmail.com', 'Calle 123, Ciudad Y', '1990-08-08','Activo'),
(NULL, 2, 'julia.mendoza', 'juliaM87*', 'Julia', 'Mendoza', 'Cruz', 543210987, 'julia.mendoza@hotmail.com', 'Avenida ABC, Ciudad Z', '1987-09-15','Activo');

-- Insertar datos de ejemplo en la tabla proveedor
INSERT INTO proveedor (id_prov, nombre, RFC, telefono, correo, direccion, estado) VALUES
(NULL, 'ElectroSuministros S.A. de C.V.', 'ABC123456789', 123456789, 'electrosuministros@example.com', 'Calle 123, Ciudad 1', 'Activo'),
(NULL, 'ModaStyle Distribuciones', 'DEF987654321', 987654321, 'modastyle@example.com', 'Avenida XYZ, Ciudad 2', 'Activo'),
(NULL, 'HogarFeliz Proveedores', 'GHI456789012', 456789013, 'hogarfeliz@example.com', 'Plaza Principal, Ciudad 3', 'Activo'),
(NULL, 'AlimentosPremium Exportaciones', 'JKL321098765', 321098754, 'alimentospremium@example.com', 'Carrera 456, Ciudad 4', 'Activo'),
(NULL, 'SaludViva Internacional', 'MNO210987654', 210987643, 'saludviva@example.com', 'Bulevar ABC, Ciudad 5', 'Activo'),
(NULL, 'TecnologíaTotal Global', 'PQR789012345', 789012456, 'tecnologiatotal@example.com', 'Calle 678, Ciudad 6', 'Activo'),
(NULL, 'ModaCasa Distribuidores', 'STU543210987', 543210876, 'modacasa@example.com', 'Avenida 901, Ciudad 7', 'Activo'),
(NULL, 'MobiliarioExclusivo S.A. de C.V.', 'VWX678901234', 679012345, 'mobiliarioexclusivo@example.com', 'Plaza Central, Ciudad 8', 'Activo'),
(NULL, 'SuplementosVitalizantes', 'YZA123456789', 123456890, 'suplementosvitalizantes@example.com', 'Carrera 234, Ciudad 9', 'Activo'),
(NULL, 'DentCare Suministros Dentales', 'BCD987654321', 987654210, 'dentcare@example.com', 'Bulevar 567, Ciudad 10', 'Activo'),
(NULL, 'ElectroComponentes S.A. de C.V.', 'ABC789012345', 456789012, 'electrocomponentes@example.com', 'Avenida 234, Ciudad 11', 'Activo'),
(NULL, 'FashionTrends Distribuciones', 'DEF543210987', 543210987, 'fashiontrends@example.com', 'Calle 567, Ciudad 12', 'Activo'),
(NULL, 'HogarElegante Proveedores', 'GHI210987654', 210987654, 'hogarelegante@example.com', 'Plaza del Sol, Ciudad 13', 'Activo'),
(NULL, 'AlimentosDeliciosos Exportaciones', 'JKL678901234', 678901234, 'alimentosdeliciosos@example.com', 'Carrera 890, Ciudad 14', 'Activo'),
(NULL, 'VidaActiva Internacional', 'MNO123456789', 123456789, 'vidaactiva@example.com', 'Bulevar XYZ, Ciudad 15', 'Activo'),
(NULL, 'TecnologíaAvanzada Global', 'PQR987654321', 987654321, 'tecnologiaavanzada@example.com', 'Calle 123, Ciudad 16', 'Activo'),
(NULL, 'ModaHogar Distribuidores', 'STU210987654', 210987654, 'modahogar@example.com', 'Avenida ABC, Ciudad 17', 'Activo'),
(NULL, 'MueblesPremium S.A. de C.V.', 'VWX543210987', 543210987, 'mueblespremium@example.com', 'Plaza Libertad, Ciudad 18', 'Activo'),
(NULL, 'NutriVital Suplementos', 'YZA678901234', 678901234, 'nutrivital@example.com', 'Carrera 567, Ciudad 19', 'Activo'),
(NULL, 'DentalCare Suministros Dentales', 'BCD123456789', 123456789, 'dentalcare@example.com', 'Bulevar 890, Ciudad 20', 'Activo');


-- Insertar datos de ejemplo en la tabla tipoProducto
INSERT INTO tipoProducto (tipoProducto) VALUES
('Electrónicos'),
('Ropa'),
('Hogar'),
('Alimentación'),
('Salud y Belleza');

-- Insertar datos de ejemplo en la tabla impuesto
INSERT INTO impuesto (nombreImpuesto, porcentajeImpuesto, tipoImpuesto,estado) VALUES
('IVA', 16.00000, 'General','Activo'),
('Impuesto sobre la Renta', 20.50000, 'Ingresos','Activo'),
('Impuesto a las Ventas', 8.75000, 'Ventas','Activo'),
('Impuesto al Consumo', 5.25000, 'Consumo','Activo'),
('Impuesto a la Propiedad', 1.50000, 'Propiedad','Activo');

-- Insertar datos de ejemplo en la tabla productoCatalogo
INSERT INTO productoCatalogo (id_pro, id_prov, id_tipoProducto, id_imp, nombreProducto, costoProducto, precioVenta, unidadMedida, cantidadStock, estado) VALUES
(10001, 1, 1, 1, 'Laptop Modelo A', 800.00, 1200.00, 'Unidad', 50.00, 'Activo'),
(10002, 2, 2, 2, 'Camisa Casual', 20.00, 40.00, 'Pieza', 200.00, 'Activo'),
(10003, 3, 3, 3, 'Juego de Sábanas', 30.00, 60.00, 'Juego', 100.00, 'Activo'),
(10004, 4, 4, 4, 'Arroz Integral', 5.00, 7.50, 'Kilogramo', 500.00, 'Activo'),
(10005, 5, 5, 5, 'Vitamina C', 10.00, 15.00, 'Botella', 80.00, 'Activo'),
(10006, 6, 1, 1, 'Smartphone Modelo X', 400.00, 600.00, 'Unidad', 30.00, 'Activo'),
(10007, 7, 2, 2, 'Jeans Clásicos', 25.00, 50.00, 'Pieza', 150.00, 'Activo'),
(10008, 8, 3, 3, 'Silla de Oficina', 50.00, 80.00, 'Unidad', 40.00, 'Activo'),
(10009, 9, 4, 4, 'Aceite de Oliva', 8.00, 12.00, 'Botella', 120.00, 'Activo'),
(10010, 10, 5, 5, 'Protector Solar SPF 30', 15.00, 25.00, 'Botella', 75.00, 'Activo'),
(10011, 1, 1, 1, 'Zapatos Deportivos', 30.00, 60.00, 'Par', 90.00, 'Activo'),
(10012, 2, 2, 2, 'Cobertor Polar', 18.00, 30.00, 'Pieza', 120.00, 'Activo'),
(10013, 3, 3, 3, 'Frijoles Negros', 4.00, 6.00, 'Kilogramo', 200.00, 'Activo'),
(10014, 4, 4, 4, 'Champú Nutritivo', 12.00, 20.00, 'Botella', 60.00, 'Activo'),
(10015, 5, 5, 5, 'Tablet Modelo B', 150.00, 250.00, 'Unidad', 20.00, 'Activo'),
(10016, 6, 1, 1, 'Gorra de Moda', 8.00, 15.00, 'Unidad', 100.00, 'Activo'),
(10017, 7, 2, 2, 'Mesa de Comedor', 80.00, 120.00, 'Unidad', 25.00, 'Activo'),
(10018, 8, 3, 3, 'Pasta de Tomate', 3.00, 5.00, 'Botella', 150.00, 'Activo'),
(10019, 9, 4, 4, 'Cepillo de Dientes', 2.00, 4.00, 'Unidad', 300.00, 'Activo'),
(10020, 10, 5, 5, 'Suplemento de Calcio', 18.00, 30.00, 'Botella', 50.00, 'Activo'),
(10021, 1, 1, 1, 'Impresora Multifunción', 120.00, 200.00, 'Unidad', 25.00, 'Activo'),
(10022, 2, 2, 2, 'Vestido Elegante', 35.00, 70.00, 'Pieza', 80.00, 'Activo'),
(10023, 3, 3, 3, 'Toallas de Baño Set', 25.00, 45.00, 'Juego', 60.00, 'Activo'),
(10024, 4, 4, 4, 'Quinoa Orgánica', 6.00, 9.00, 'Kilogramo', 180.00, 'Activo'),
(10025, 5, 5, 5, 'Omega-3 Cápsulas', 20.00, 35.00, 'Botella', 50.00, 'Activo'),
(10026, 6, 1, 1, 'Auriculares Bluetooth', 25.00, 40.00, 'Par', 70.00, 'Activo'),
(10027, 7, 2, 2, 'Chaqueta de Cuero', 50.00, 90.00, 'Pieza', 40.00, 'Activo'),
(10028, 8, 3, 3, 'Escritorio de Oficina', 100.00, 150.00, 'Unidad', 30.00, 'Activo'),
(10029, 9, 4, 4, 'Vinagre Balsámico', 10.00, 18.00, 'Botella', 90.00, 'Activo'),
(10030, 10, 5, 5, 'Crema Solar FPS 50', 20.00, 35.00, 'Botella', 60.00, 'Activo'),
(10031, 1, 1, 1, 'Zapatillas Deportivas', 40.00, 70.00, 'Par', 80.00, 'Activo'),
(10032, 2, 2, 2, 'Almohadas de Plumas', 15.00, 25.00, 'Par', 100.00, 'Activo'),
(10033, 3, 3, 3, 'Garbanzos enlatados', 2.50, 5.00, 'Lata', 200.00, 'Activo'),
(10034, 4, 4, 4, 'Acondicionador Reparador', 15.00, 25.00, 'Botella', 70.00, 'Activo'),
(10035, 5, 5, 5, 'Laptop Ultradelgada', 600.00, 900.00, 'Unidad', 15.00, 'Activo'),
(10036, 6, 1, 1, 'Gafas de Sol Modernas', 12.00, 20.00, 'Par', 120.00, 'Activo'),
(10037, 7, 2, 2, 'Sofá de Cuero', 180.00, 300.00, 'Unidad', 20.00, 'Activo'),
(10038, 8, 3, 3, 'Salsa de Soja', 4.00, 7.00, 'Botella', 120.00, 'Activo'),
(10039, 9, 4, 4, 'Hilo Dental', 1.50, 3.00, 'Unidad', 250.00, 'Activo'),
(10040, 10, 5, 5, 'Vitamina D en Gomitas', 8.00, 15.00, 'Frasco', 80.00, 'Activo');

select * from productoCatalogo;