from flask import Flask
from flask import jsonify
from flask import render_template, request, redirect, session, url_for
from flaskext.mysql import MySQL
from flask import send_from_directory
import os
import json
from datetime import datetime

app = Flask(__name__)
mysql = MySQL()
app.secret_key = "genecos"

# CONEXION BASE DE DATOS
app.config["MYSQL_DATABASE_HOST"] = "localhost"
app.config["MYSQL_DATABASE_USER"] = "root"
app.config["MYSQL_DATABASE_PASSWORD"] = "n0m3l0"
app.config["MYSQL_DATABASE_DB"] = "oxxo"
mysql.init_app(app)

@app.route("/")
def inicio():
    return render_template("sitio/index.html")

@app.route("/img/<imagen>")
def imagenes(imagen):
    return send_from_directory(os.path.join("img"), imagen)

@app.route("/static/js/<archivo>")
def archivos(archivo):
    return send_from_directory(os.path.join("static"), archivo)

@app.route("/templates/sitio/<archivo>")
def archivo(archivo):
    return send_from_directory(archivo)

# INICIO DE SESION
@app.route("/login", methods=["POST"])
def login():

    _nombreUsuario = request.form["nombreUsuario"]
    _contraseña = request.form["contraseña"]

    conexion = mysql.connect()
    cursor = conexion.cursor()
    cursor.execute("SELECT count(*) FROM usuario WHERE nombreUsuario = %s AND contrasena = %s AND estado = 'Activo'",(_nombreUsuario,_contraseña))
    usuario = cursor.fetchall()
    conexion.commit()

    if usuario[0][0] == 1:
        # CONSULTA DE INICIO DE SESION
        conexion = mysql.connect()
        cursor = conexion.cursor()
        cursor.execute("SELECT * FROM usuario INNER JOIN tipoUsuario ON usuario.id_tipUsuario = tipoUsuario.id_tipUsuario WHERE nombreUsuario = %s AND contrasena = %s",(_nombreUsuario,_contraseña))
        usuario = cursor.fetchall()
        conexion.commit()

        session["login"] = True
        session['username'] = usuario[0][2]
        session['idUser'] = usuario[0][0]
        session['tipoUsuario'] =  usuario[0][13]

        return redirect("/inicio")
    else:
        mensaje = "¡Nombre de usuario o contraseña incorrectos!"
        return render_template("sitio/index.html", mensaje = mensaje)

@app.route("/admin/cerrar")
def login_cerrar():
    session.clear()
    return redirect(url_for('inicio'))

# OPERACION DE ALMACEN
@app.route("/admin/operacionAlmacen", methods = ['POST'])
def operacionAlmacen():
    if not "login" in session:
        return redirect(url_for('inicio'))

    # Verificar que la solicitud sea de tipo POST y tiene datos JSON
    if request.method == 'POST' and request.is_json:
        try:
            # Obtener los datos JSON de la solicitud
            data = request.get_json()

            for dat in data:
                if dat.get('tipoOperacion',0) == 1:
                    conexion = mysql.connect()
                    cursor = conexion.cursor()
                    cursor.execute("call operacionAlmacen(%s,%s,%s)",(dat.get('codigo',''),dat.get('cantidad',0),1))
                    conexion.commit()
                elif dat.get('tipoOperacion',0) == 2:
                    conexion = mysql.connect()
                    cursor = conexion.cursor()
                    cursor.execute("call validarStock(%s,%s)",(dat.get('codigo',''),dat.get('cantidad',0)))
                    validacionStock = cursor.fetchall()
                    conexion.commit()
                    if validacionStock[0][0] == int(dat.get('codigo','')):
                        conexion = mysql.connect()
                        cursor = conexion.cursor()
                        cursor.execute("call operacionAlmacen(%s,%s,%s)",(dat.get('codigo',''),dat.get('cantidad',0),2))
                        conexion.commit()

            # Puedes realizar operaciones con los datos o devolver una respuesta JSON
            respuesta = {'mensaje': 'Datos recibidos correctamente', 'data': data}
            return jsonify(respuesta)
            
        except Exception as e:
            return jsonify({'error': str(e)}), 400  # Devolver un código de estado 400 en caso de error

    else:
        return jsonify({'error': 'Solicitud no válida'}), 400  # Devolver un código de estado 400 si la solicitud no es válida

# AGREGAR USUARIO
@app.route("/admin/agregarUsuario", methods = {'POST'})
def agregarUsuario():
    if not "login" in session:
        return redirect(url_for('inicio'))

    _user = request.form['user']

    conexion = mysql.connect()
    cursor = conexion.cursor()
    cursor.execute("SELECT count(id_usu) FROM usuario WHERE nombreUsuario = %s",(_user))
    validacion = cursor.fetchall()
    conexion.commit()

    if validacion[0][0] == 0:
        _tipo = request.form['tipoUsuario']
        _contra = request.form['contra']
        _nombre = request.form['nombre']
        _apellidoP = request.form['apellidoP']
        _apellidoM = request.form['apellidoM']
        _telefono = request.form['telefono']
        _correo = request.form['correo']
        _direccion = request.form['direccion']
        _fechaNac = request.form['fechaNacimiento']

        sql = "INSERT INTO usuario VALUES (default,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,'Activo')"
        datos = (_tipo,_user,_contra,_nombre,_apellidoP,_apellidoM,_telefono,_correo,_direccion,_fechaNac)
        conexion = mysql.connect()
        cursor = conexion.cursor()
        cursor.execute(sql,datos)
        conexion.commit()

        return redirect(url_for("inicio_admin"))
    else:
        return redirect(url_for("inicio_admin"))

# BAJA DE USUARIO
@app.route("/admini/bajaUsuario/<string:idU>")
def bajaUsuario(idU):
    if not "login" in session:
        return redirect(url_for('inicio'))
    else:
        conexion = mysql.connect()
        cursor = conexion.cursor()
        cursor.execute("UPDATE usuario SET estado = 'Baja' WHERE id_usu = %s",(idU))
        conexion.commit()

        return redirect(url_for("inicio_admin"))

# Editar usuario
@app.route("/admin/editarPerfil/<string:idU>", methods = ['POST'])
def editarPerfil(idU):
    if not "login" in session:
        return redirect(url_for('inicio'))
    
    _nombre = request.form["nombre"]
    _apellidoP = request.form["apellidoP"]
    _apellidoM = request.form["apellidoM"]
    _fechaNac = request.form["fecNac"]
    _nombreUsuario = request.form["nombreUsuario"]
    _telefono = request.form["telefono"]
    _contra = request.form["contra"]
    _direccion = request.form["direccion"]
    _correo = request.form["correo"]


    sql = "UPDATE usuario SET nombreUsuario = %s, contrasena = %s, nombre = %s, apellidoPaterno = %s, apellidoMaterno = %s, telefono = %s, correo = %s, direccion = %s, fechaNacimiento = %s WHERE id_usu = %s"
    datos = [_nombreUsuario,_contra,_nombre,_apellidoP,_apellidoM,_telefono,_correo,_direccion,_fechaNac,idU]
    conexion = mysql.connect()
    cursor = conexion.cursor()
    cursor.execute(sql,datos)
    conexion.commit()

    return redirect(url_for("inicio_admin"))

# AGREGAR IMPUESTO
@app.route("/admin/agregarImpuesto", methods = {'POST'})
def agregarImpuesto():
    if not "login" in session:
        return redirect(url_for('inicio'))

    _nombre = request.form["nombre"]
    _porcentaje = request.form["porcentaje"]
    _tipo = request.form["tipoImpuesto"]

    sql = "INSERT INTO impuesto VALUES(default,%s,%s,%s,'Activo')"
    datos = (_nombre,_porcentaje,_tipo)
    conexion = mysql.connect()
    cursor = conexion.cursor()
    cursor.execute(sql,datos)
    conexion.commit()

    return redirect(url_for("inicio_admin"))

# EDITAR IMPUESTO
@app.route("/admini/editarImpuesto/<string:idI>", methods = {'POST'})
def editarImpuesto(idI):
    if not "login" in session:
        return redirect(url_for('inicio'))
    else:
        
        _nombre = request.form["nombre"]
        _porcentaje = request.form["porcentaje"]
        _tipo = request.form["tipoImpuesto"]

        sql = "UPDATE impuesto SET nombreImpuesto=%s, porcentajeImpuesto=%s, tipoImpuesto=%s WHERE id_imp = %s"
        datos = (_nombre,_porcentaje,_tipo,idI)
        conexion = mysql.connect()
        cursor = conexion.cursor()
        cursor.execute(sql,datos)
        conexion.commit()

        return redirect(url_for("inicio_admin"))

# DAR DE BAJA IMPUESTO
@app.route("/admini/bajaImpuesto/<string:idI>")
def bajaImpuesto(idI):
    if not "login" in session:
        return redirect(url_for('inicio'))
    else:
        conexion = mysql.connect()
        cursor = conexion.cursor()
        cursor.execute("UPDATE impuesto SET estado = 'Baja' WHERE id_imp = %s",(idI))
        conexion.commit()

        return redirect(url_for("inicio_admin"))

# AGREGAR PRODUCTO
@app.route("/admin/agregarProducto", methods = {'POST'})
def agregarProducto():
    if not "login" in session:
        return redirect(url_for('inicio'))

    _tipoPro = request.form["tipoProducto"]
    _proveedor = request.form["proveedor"]
    _impuesto = request.form["impuesto"]
    _nombre = request.form["nombre"]
    _costo = request.form["costo"]
    _precioV = request.form["precioV"]
    _unidad = request.form["unidad"]
    _stock = request.form["stock"]

    sql = "INSERT INTO productoCatalogo VALUES(default,%s,%s,%s,%s,%s,%s,%s,%s,'Activo')"
    datos = (_proveedor,_tipoPro,_impuesto,_nombre,_costo,_precioV,_unidad,_stock)
    conexion = mysql.connect()
    cursor = conexion.cursor()
    cursor.execute(sql,datos)
    conexion.commit()

    return redirect(url_for("inicio_admin"))

# EDITAR PRODUCTO
@app.route("/admin/agregarProducto/<string:idP>", methods = {'POST'})
def editarProducto(idP):
    if not "login" in session:
        return redirect(url_for('inicio'))

    _nombre = request.form["nombre"]
    _costo = request.form["costo"]
    _precioV = request.form["precioV"]

    sql = "UPDATE productoCatalogo SET nombreProducto=%s, costoProducto=%s, precioVenta= %s WHERE id_pro=%s"
    datos = (_nombre,_costo,_precioV,idP)
    conexion = mysql.connect()
    cursor = conexion.cursor()
    cursor.execute(sql,datos)
    conexion.commit()

    return redirect(url_for("inicio_admin"))

# DAR DE BAJA PRODUCTO
@app.route("/admin/bajaProducto/<string:idP>")
def bajaProducto(idP):
    if not "login" in session:
        return redirect(url_for('inicio'))

    conexion = mysql.connect()
    cursor = conexion.cursor()
    cursor.execute("UPDATE productoCatalogo SET estado = 'Baja' WHERE id_pro = %s",(idP))
    conexion.commit()

    return redirect(url_for("inicio_admin"))

# AGREGAR PROVEEDOR
@app.route("/admin/agregarProveedor", methods = {'POST'})
def agregarProveedor():
    if not "login" in session:
        return redirect(url_for('inicio'))

    _rfc = request.form['rfc']

    conexion = mysql.connect()
    cursor = conexion.cursor()
    cursor.execute("SELECT count(id_prov) FROM proveedor WHERE rfc = %s",(_rfc))
    validacion = cursor.fetchall()
    conexion.commit()

    if validacion[0][0] == 0:

        _nombre = request.form['nombre']
        _telefono = request.form['telefono']
        _correo = request.form['correo']
        _direccion = request.form['direccion']

        sql = "INSERT INTO proveedor VALUES (default,%s,%s,%s,%s,%s,'Activo')"
        datos = (_nombre,_rfc,_telefono,_correo,_direccion)
        conexion = mysql.connect()
        cursor = conexion.cursor()
        cursor.execute(sql,datos)
        conexion.commit()

        return redirect(url_for("inicio_admin"))
    else:
        return redirect(url_for("inicio_admin"))

# EDITAR PROVEEDOR
@app.route("/admini/editarProveedor/<string:idP>", methods = {'POST'})
def editarProveedor(idP):
    if not "login" in session:
        return redirect(url_for('inicio'))
    else:
        
        _rfc = request.form['rfc']

        conexion = mysql.connect()
        cursor = conexion.cursor()
        cursor.execute("SELECT count(id_prov) FROM proveedor WHERE rfc = %s",(_rfc))
        validacion = cursor.fetchall()
        conexion.commit()

        if validacion[0][0] == 0:

            _nombre = request.form['nombre']
            _telefono = request.form['telefono']
            _correo = request.form['correo']
            _direccion = request.form['direccion']

            sql = "UPDATE proveedor SET nombre=%s, rfc=%s, telefono=%s, correo=%s, direccion=%s WHERE id_prov=%s"
            datos = (_nombre,_rfc,_telefono,_correo,_direccion,idP)
            conexion = mysql.connect()
            cursor = conexion.cursor()
            cursor.execute(sql,datos)
            conexion.commit()

            return redirect(url_for("inicio_admin"))
        else:
            return redirect(url_for("inicio_admin"))

# DAR DE BAJA PROVEEDOR
@app.route("/admini/bajaProveedor/<string:idP>")
def bajaProveedor(idP):
    if not "login" in session:
        return redirect(url_for('inicio'))
    else:
        conexion = mysql.connect()
        cursor = conexion.cursor()
        cursor.execute("UPDATE proveedor SET estado = 'Baja' WHERE id_prov = %s",(idP))
        conexion.commit()

        return redirect(url_for("inicio_admin"))

# AGREGAR VENTA
@app.route("/admin/agregarVenta", methods = ['POST'])
def agregarVenta():
    if not "login" in session:
        return redirect(url_for('inicio'))

    # Verificar que la solicitud sea de tipo POST y tiene datos JSON
    if request.method == 'POST' and request.is_json:
        try:
            # Obtener los datos JSON de la solicitud
            data = request.get_json()

            fecha_actual = datetime.now()
            stockValidado = True
            
            for dat in data:
                conexion = mysql.connect()
                cursor = conexion.cursor()
                cursor.execute("call validarStock(%s,%s)",(dat.get('codigo',''),dat.get('cantidad',0)))
                validacionStock = cursor.fetchall()
                conexion.commit()
                if validacionStock[0][0] != int(dat.get('codigo','')):
                    stockValidado = False

            if stockValidado != False:
                sql = "INSERT INTO venta VALUES(default,%s,%s,0.00,0.00,0.00)"
                datos = (session["idUser"],fecha_actual)
                conexion = mysql.connect()
                cursor = conexion.cursor()
                cursor.execute(sql,datos)
                conexion.commit()

                conexion = mysql.connect()
                cursor = conexion.cursor()
                cursor.execute("SELECT MAX(id_ven) FROM venta")
                idVenta = cursor.fetchall()
                conexion.commit()

                subTotalTotal = 0.00
                impuesto = 0.00
                total = 0.00

                for dat in data:
                    conexion = mysql.connect()
                    cursor = conexion.cursor()
                    cursor.execute("select id_pro,porcentajeImpuesto from productocatalogo as t1 inner join impuesto as t2 on t1.id_imp = t2.id_imp where id_pro=%s",(dat.get('codigo','')))
                    producto = cursor.fetchall()
                    conexion.commit()

                    subImpuesto = ((float(producto[0][1])*0.01)*float(dat.get('precio',0)))*float(dat.get('cantidad',0))
                    subTotal = float(dat.get('cantidad',0))*float(dat.get('precio',0))

                    sql = "INSERT INTO relacion_producto_venta VALUES(default,%s,%s,%s,%s,%s)"
                    datos = (idVenta[0][0],producto[0][0],dat.get('cantidad',0),subImpuesto,subTotal + subImpuesto)
                    conexion = mysql.connect()
                    cursor = conexion.cursor()
                    cursor.execute(sql,datos)
                    conexion.commit()

                    impuesto = impuesto + subImpuesto
                    subTotalTotal = subTotalTotal + subTotal
                    
                total = total + (subTotalTotal + impuesto)
                sql = "UPDATE venta SET subtotal = %s, impuestos = %s, total = %s  WHERE id_ven = %s"
                datos = (subTotalTotal,impuesto,total,idVenta[0][0])
                conexion = mysql.connect()
                cursor = conexion.cursor()
                cursor.execute(sql,datos)
                conexion.commit()

                # Puedes realizar operaciones con los datos o devolver una respuesta JSON
                respuesta = {'mensaje': 'Datos recibidos correctamente', 'data': data}
                return jsonify(respuesta)
            else:
                return jsonify({'error': 'No hay stock para el/los producto(s) seleccionado(s)'}), 400  # Devolver un código de estado 400 si la solicitud no es válida
            
        except Exception as e:
            return jsonify({'error': str(e)}), 400  # Devolver un código de estado 400 en caso de error

    else:
        return jsonify({'error': 'Solicitud no válida'}), 400  # Devolver un código de estado 400 si la solicitud no es válida

@app.route("/inicio")
def inicio_admin():
    if not "login" in session:
        return redirect(url_for('inicio'))
    else:

        conexion = mysql.connect()
        cursor = conexion.cursor()
        cursor.execute("SELECT * FROM productoCatalogo AS T1 INNER JOIN tipoProducto AS T2 ON T1.id_tipoProducto = T2.id_tipoProducto INNER JOIN impuesto AS T3 ON T1.id_imp = T3.id_imp INNER JOIN proveedor AS T4 ON T1.id_prov = T4.id_prov  WHERE T1.estado = 'Activo' ORDER BY T1.id_pro ASC")
        productos = cursor.fetchall()
        conexion.commit()

        conexion = mysql.connect()
        cursor = conexion.cursor()
        cursor.execute("SELECT * FROM usuario INNER JOIN tipoUsuario ON usuario.id_tipUsuario = tipoUsuario.id_tipUsuario WHERE estado = 'Activo' ORDER BY id_usu ASC")
        usuarios = cursor.fetchall()
        conexion.commit()

        conexion = mysql.connect()
        cursor = conexion.cursor()
        cursor.execute("SELECT * FROM usuario WHERE id_usu = %s",(session["idUser"]))
        user = cursor.fetchall()
        conexion.commit()

        conexion = mysql.connect()
        cursor = conexion.cursor()
        cursor.execute("SELECT * FROM proveedor WHERE estado = 'Activo'")
        proveedor = cursor.fetchall()
        conexion.commit()

        conexion = mysql.connect()
        cursor = conexion.cursor()
        cursor.execute("SELECT * FROM venta as T1 INNER JOIN usuario as T2 ON T1.id_usu = T2.id_usu")
        ventas = cursor.fetchall()
        conexion.commit()

        conexion = mysql.connect()
        cursor = conexion.cursor()
        cursor.execute("SELECT * FROM venta AS T1 INNER JOIN relacion_producto_venta AS T2 ON T1.id_ven = T2.id_ven INNER JOIN productoCatalogo as T3 ON T2.id_pro = T3.id_pro")
        ventasDetalle = cursor.fetchall()
        conexion.commit()

        conexion = mysql.connect()
        cursor = conexion.cursor()
        cursor.execute("SELECT * FROM impuesto WHERE estado = 'Activo'")
        impuestos = cursor.fetchall()
        conexion.commit()

        conexion = mysql.connect()
        cursor = conexion.cursor()
        cursor.execute("SELECT * FROM tipoUsuario")
        tipoUsuario = cursor.fetchall()
        conexion.commit()

        conexion = mysql.connect()
        cursor = conexion.cursor()
        cursor.execute("SELECT * FROM tipoProducto")
        tipoProducto = cursor.fetchall()
        conexion.commit()

        fecha_actual = datetime.now()
        fecha = fecha_actual.date()

        return render_template("admin/inicioOxxo.html",productos = productos, usuarios = usuarios, proveedor = proveedor, ventas = ventas, ventasDetalle = ventasDetalle, user = user, impuestos = impuestos,fecha = fecha,tipoUsuario = tipoUsuario, tipoProducto = tipoProducto)

if __name__ == "__main__":
    app.run(debug=True)