--
-- PostgreSQL database dump
--

-- Dumped from database version 9.4.1
-- Dumped by pg_dump version 9.4.1
-- Started on 2016-04-28 23:57:36

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- TOC entry 186 (class 3079 OID 11855)
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- TOC entry 2109 (class 0 OID 0)
-- Dependencies: 186
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

--
-- TOC entry 201 (class 1255 OID 51563)
-- Name: autenticacion(character varying, character varying); Type: FUNCTION; Schema: public; Owner: escueladigital
--

CREATE FUNCTION autenticacion(_usuario character varying, _clave character varying) RETURNS TABLE(id_usuario smallint, nombre character varying, id_perfil smallint, perfil character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
	RETURN QUERY SELECT a.id_usuario, a.nombre, b.id_perfil, b.perfil
	FROM usuarios as a NATURAL JOIN perfiles as b
	WHERE a.usuario = _usuario AND a.clave = md5(_clave);
	IF NOT FOUND THEN
		RAISE EXCEPTION 'El usuario o la contraseña no coinciden';
	END IF;

END;
$$;


ALTER FUNCTION public.autenticacion(_usuario character varying, _clave character varying) OWNER TO escueladigital;

--
-- TOC entry 204 (class 1255 OID 51568)
-- Name: comprar(smallint, smallint, smallint, smallint, smallint); Type: FUNCTION; Schema: public; Owner: escueladigital
--

CREATE FUNCTION comprar(_proveedor smallint, _producto smallint, _cantidad smallint, _valor smallint, _usuario smallint) RETURNS smallint
    LANGUAGE plpgsql
    AS $$
DECLARE
	_idfactura smallint;
BEGIN
	-- SE INSERTA EL REGISTRO DE COMPRAS
	INSERT INTO compras (id_tercero, id_producto, cantidad, valor, id_usuario)
	VALUES (_proveedor, _producto, _cantidad, _valor, _usuario)
	RETURNING id_compra INTO _idfactura;
	IF FOUND THEN
		-- SE ACTUALIZA EL STOCK DEL PRODUCTO
		UPDATE productos
		SET cantidad = cantidad + _cantidad, precio = _valor, id_usuario = _usuario
		WHERE id_producto = _producto;
	ELSE
		RAISE EXCEPTION 'No fue posible insertar el registro de compras';
	END IF;

	RETURN _idfactura;
END;
$$;


ALTER FUNCTION public.comprar(_proveedor smallint, _producto smallint, _cantidad smallint, _valor smallint, _usuario smallint) OWNER TO escueladigital;

--
-- TOC entry 208 (class 1255 OID 51573)
-- Name: consulta_compras(smallint, smallint); Type: FUNCTION; Schema: public; Owner: escueladigital
--

CREATE FUNCTION consulta_compras(_limite smallint, _pagina smallint) RETURNS TABLE(id_compra smallint, fecha date, cliente character varying, producto character varying, cantidad smallint, valor smallint)
    LANGUAGE plpgsql
    AS $$
DECLARE
	_inicio smallint;
BEGIN
	_inicio = _limite * _pagina - _limite;

	RETURN QUERY SELECT c.id_compra, c.fecha, t.nombre as cliente,
		p.nombre as producto, c.cantidad, c.valor
	FROM compras as c INNER JOIN terceros as t
		ON c.id_tercero = t.id_tercero
		INNER JOIN productos as p
		ON c.id_producto = p.id_producto
	LIMIT _limite
	OFFSET _inicio;
END;
$$;


ALTER FUNCTION public.consulta_compras(_limite smallint, _pagina smallint) OWNER TO escueladigital;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- TOC entry 179 (class 1259 OID 51475)
-- Name: productos; Type: TABLE; Schema: public; Owner: escueladigital; Tablespace: 
--

CREATE TABLE productos (
    id_producto smallint NOT NULL,
    nombre character varying(20) NOT NULL,
    cantidad smallint,
    precio smallint,
    id_usuario smallint,
    CONSTRAINT ck_cantidad CHECK ((cantidad > 0)),
    CONSTRAINT ck_precio CHECK ((precio > 0))
);


ALTER TABLE productos OWNER TO escueladigital;

--
-- TOC entry 209 (class 1255 OID 51574)
-- Name: consulta_inventario(smallint, smallint); Type: FUNCTION; Schema: public; Owner: escueladigital
--

CREATE FUNCTION consulta_inventario(_limite smallint, _pagina smallint) RETURNS SETOF productos
    LANGUAGE plpgsql
    AS $$
DECLARE
	_inicio smallint;
BEGIN
	_inicio = _limite * _pagina - _limite;
	RETURN QUERY SELECT id_producto, nombre, cantidad, precio, id_usuario
	FROM productos
	ORDER BY id_producto
	LIMIT _limite
	OFFSET _inicio;
END;
$$;


ALTER FUNCTION public.consulta_inventario(_limite smallint, _pagina smallint) OWNER TO escueladigital;

--
-- TOC entry 199 (class 1255 OID 51562)
-- Name: consulta_productos(); Type: FUNCTION; Schema: public; Owner: escueladigital
--

CREATE FUNCTION consulta_productos() RETURNS SETOF productos
    LANGUAGE plpgsql
    AS $$
BEGIN
	RETURN QUERY SELECT id_producto, nombre, cantidad, precio, id_usuario
	FROM productos ORDER BY nombre;
END;
$$;


ALTER FUNCTION public.consulta_productos() OWNER TO escueladigital;

--
-- TOC entry 177 (class 1259 OID 51465)
-- Name: terceros; Type: TABLE; Schema: public; Owner: escueladigital; Tablespace: 
--

CREATE TABLE terceros (
    id_tercero smallint NOT NULL,
    identificacion character varying(20) NOT NULL,
    nombre character varying(100) NOT NULL,
    direccion character varying(100) NOT NULL,
    telefono character varying(20) NOT NULL
);


ALTER TABLE terceros OWNER TO escueladigital;

--
-- TOC entry 200 (class 1255 OID 51561)
-- Name: consulta_terceros(); Type: FUNCTION; Schema: public; Owner: escueladigital
--

CREATE FUNCTION consulta_terceros() RETURNS SETOF terceros
    LANGUAGE plpgsql
    AS $$
BEGIN
	RETURN QUERY SELECT id_tercero, identificacion, nombre, direccion, telefono FROM terceros ORDER BY nombre;
END;
$$;


ALTER FUNCTION public.consulta_terceros() OWNER TO escueladigital;

--
-- TOC entry 207 (class 1255 OID 51572)
-- Name: consulta_ventas(smallint, smallint); Type: FUNCTION; Schema: public; Owner: escueladigital
--

CREATE FUNCTION consulta_ventas(_limite smallint, _pagina smallint) RETURNS TABLE(id_venta smallint, fecha date, cliente character varying, producto character varying, cantidad smallint, valor smallint)
    LANGUAGE plpgsql
    AS $$
DECLARE
	_inicio smallint;
BEGIN
	_inicio = _limite * _pagina - _limite;

	RETURN QUERY SELECT v.id_venta, v.fecha, t.nombre as proveedor,
		p.nombre as producto, v.cantidad, v.valor
	FROM ventas as v INNER JOIN terceros as t
		ON v.id_tercero = t.id_tercero
		INNER JOIN productos as p
		ON v.id_producto = p.id_producto
	LIMIT _limite
	OFFSET _inicio;
END;
$$;


ALTER FUNCTION public.consulta_ventas(_limite smallint, _pagina smallint) OWNER TO escueladigital;

--
-- TOC entry 203 (class 1255 OID 51566)
-- Name: tg_compras_auditoria(); Type: FUNCTION; Schema: public; Owner: escueladigital
--

CREATE FUNCTION tg_compras_auditoria() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	IF TG_OP = 'INSERT' THEN
		INSERT INTO auditoria (id_usuario, accion, tabla, anterior, nuevo)
		SELECT NEW.id_usuario, 'INSERTAR', 'COMPRAS', row_to_json(NEW.*), null;
	END IF;
	RETURN NEW;
END;
$$;


ALTER FUNCTION public.tg_compras_auditoria() OWNER TO escueladigital;

--
-- TOC entry 202 (class 1255 OID 51564)
-- Name: tg_productos_auditoria(); Type: FUNCTION; Schema: public; Owner: escueladigital
--

CREATE FUNCTION tg_productos_auditoria() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	IF TG_OP = 'UPDATE' THEN
		INSERT INTO auditoria (id_usuario, accion, tabla, anterior, nuevo)
		SELECT NEW.id_usuario, 'ACTUALIZAR', 'PRODUCTO', row_to_json(OLD.*), row_to_json(NEW.*);
	END IF;
	RETURN NEW;
END;
$$;


ALTER FUNCTION public.tg_productos_auditoria() OWNER TO escueladigital;

--
-- TOC entry 205 (class 1255 OID 51569)
-- Name: tg_ventas_auditoria(); Type: FUNCTION; Schema: public; Owner: escueladigital
--

CREATE FUNCTION tg_ventas_auditoria() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	IF TG_OP = 'INSERT' THEN
		INSERT INTO auditoria (id_usuario, accion, tabla, anterior, nuevo)
		SELECT NEW.id_usuario, 'INSERTAR', 'VENTAS', row_to_json(NEW.*), null;
	END IF;
	RETURN NEW;
END;
$$;


ALTER FUNCTION public.tg_ventas_auditoria() OWNER TO escueladigital;

--
-- TOC entry 206 (class 1255 OID 51571)
-- Name: vender(smallint, smallint, smallint, smallint); Type: FUNCTION; Schema: public; Owner: escueladigital
--

CREATE FUNCTION vender(_cliente smallint, _producto smallint, _cantidad smallint, _usuario smallint) RETURNS smallint
    LANGUAGE plpgsql
    AS $$
DECLARE
	_valor smallint;
	_existencia smallint;
	_idfactura smallint;
BEGIN
	-- SE BUSCA EL PRECIO DE VENTA Y SE VALIDA SI HAY STOCK DE VENTAS
	SELECT CAST(precio * 1.3 AS smallint), cantidad
	INTO STRICT _valor, _existencia
	FROM productos
	WHERE id_producto = _producto;

	-- SI HAY SUFICIENTE STOCK, SE VENDE
	IF _existencia >= _cantidad THEN
		-- SE INSERTA EL REGISTRO DE VENTAS
		INSERT INTO ventas (id_tercero, id_producto, cantidad, valor, id_usuario)
		VALUES (_cliente, _producto, _cantidad, _valor, _usuario)
		RETURNING id_venta INTO _idfactura;
		IF FOUND THEN
			-- SE ACTUALIZA EL STOCK DEL PRODUCTO
			UPDATE productos
			SET cantidad = cantidad - _cantidad, id_usuario = _usuario
			WHERE id_producto = _producto;
		ELSE
			RAISE EXCEPTION 'No fue posible insertar el registro de ventas';
		END IF;
	ELSE
		RAISE EXCEPTION 'No existe suficiente cantidad para la venta %', _existencia;
	END IF;

	RETURN _idfactura;

	EXCEPTION
	WHEN NO_DATA_FOUND THEN
		RAISE EXCEPTION 'No se encontró el producto a vender';
END;
$$;


ALTER FUNCTION public.vender(_cliente smallint, _producto smallint, _cantidad smallint, _usuario smallint) OWNER TO escueladigital;

--
-- TOC entry 185 (class 1259 OID 51546)
-- Name: auditoria; Type: TABLE; Schema: public; Owner: escueladigital; Tablespace: 
--

CREATE TABLE auditoria (
    id_auditoria smallint NOT NULL,
    fecha timestamp without time zone DEFAULT now() NOT NULL,
    id_usuario smallint NOT NULL,
    accion character varying(20) NOT NULL,
    tabla character varying(20) NOT NULL,
    anterior json NOT NULL,
    nuevo json
);


ALTER TABLE auditoria OWNER TO escueladigital;

--
-- TOC entry 184 (class 1259 OID 51544)
-- Name: auditoria_id_auditoria_seq; Type: SEQUENCE; Schema: public; Owner: escueladigital
--

CREATE SEQUENCE auditoria_id_auditoria_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE auditoria_id_auditoria_seq OWNER TO escueladigital;

--
-- TOC entry 2110 (class 0 OID 0)
-- Dependencies: 184
-- Name: auditoria_id_auditoria_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: escueladigital
--

ALTER SEQUENCE auditoria_id_auditoria_seq OWNED BY auditoria.id_auditoria;


--
-- TOC entry 181 (class 1259 OID 51494)
-- Name: compras; Type: TABLE; Schema: public; Owner: escueladigital; Tablespace: 
--

CREATE TABLE compras (
    id_compra smallint NOT NULL,
    fecha date DEFAULT now() NOT NULL,
    id_tercero smallint NOT NULL,
    id_producto smallint NOT NULL,
    cantidad smallint NOT NULL,
    valor smallint NOT NULL,
    id_usuario smallint NOT NULL,
    CONSTRAINT ck_compras_cantidad CHECK ((cantidad > 0)),
    CONSTRAINT ck_compras_valor CHECK ((valor > 0))
);


ALTER TABLE compras OWNER TO escueladigital;

--
-- TOC entry 180 (class 1259 OID 51492)
-- Name: compras_id_compra_seq; Type: SEQUENCE; Schema: public; Owner: escueladigital
--

CREATE SEQUENCE compras_id_compra_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE compras_id_compra_seq OWNER TO escueladigital;

--
-- TOC entry 2111 (class 0 OID 0)
-- Dependencies: 180
-- Name: compras_id_compra_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: escueladigital
--

ALTER SEQUENCE compras_id_compra_seq OWNED BY compras.id_compra;


--
-- TOC entry 173 (class 1259 OID 51440)
-- Name: perfiles; Type: TABLE; Schema: public; Owner: escueladigital; Tablespace: 
--

CREATE TABLE perfiles (
    id_perfil smallint NOT NULL,
    perfil character varying(20) NOT NULL
);


ALTER TABLE perfiles OWNER TO escueladigital;

--
-- TOC entry 172 (class 1259 OID 51438)
-- Name: perfiles_id_perfil_seq; Type: SEQUENCE; Schema: public; Owner: escueladigital
--

CREATE SEQUENCE perfiles_id_perfil_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE perfiles_id_perfil_seq OWNER TO escueladigital;

--
-- TOC entry 2112 (class 0 OID 0)
-- Dependencies: 172
-- Name: perfiles_id_perfil_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: escueladigital
--

ALTER SEQUENCE perfiles_id_perfil_seq OWNED BY perfiles.id_perfil;


--
-- TOC entry 178 (class 1259 OID 51473)
-- Name: productos_id_producto_seq; Type: SEQUENCE; Schema: public; Owner: escueladigital
--

CREATE SEQUENCE productos_id_producto_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE productos_id_producto_seq OWNER TO escueladigital;

--
-- TOC entry 2113 (class 0 OID 0)
-- Dependencies: 178
-- Name: productos_id_producto_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: escueladigital
--

ALTER SEQUENCE productos_id_producto_seq OWNED BY productos.id_producto;


--
-- TOC entry 176 (class 1259 OID 51463)
-- Name: terceros_id_tercero_seq; Type: SEQUENCE; Schema: public; Owner: escueladigital
--

CREATE SEQUENCE terceros_id_tercero_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE terceros_id_tercero_seq OWNER TO escueladigital;

--
-- TOC entry 2114 (class 0 OID 0)
-- Dependencies: 176
-- Name: terceros_id_tercero_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: escueladigital
--

ALTER SEQUENCE terceros_id_tercero_seq OWNED BY terceros.id_tercero;


--
-- TOC entry 175 (class 1259 OID 51450)
-- Name: usuarios; Type: TABLE; Schema: public; Owner: escueladigital; Tablespace: 
--

CREATE TABLE usuarios (
    id_usuario smallint NOT NULL,
    usuario character varying(20) NOT NULL,
    nombre character varying(100) NOT NULL,
    clave character varying(32) NOT NULL,
    id_perfil smallint
);


ALTER TABLE usuarios OWNER TO escueladigital;

--
-- TOC entry 174 (class 1259 OID 51448)
-- Name: usuarios_id_usuario_seq; Type: SEQUENCE; Schema: public; Owner: escueladigital
--

CREATE SEQUENCE usuarios_id_usuario_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE usuarios_id_usuario_seq OWNER TO escueladigital;

--
-- TOC entry 2115 (class 0 OID 0)
-- Dependencies: 174
-- Name: usuarios_id_usuario_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: escueladigital
--

ALTER SEQUENCE usuarios_id_usuario_seq OWNED BY usuarios.id_usuario;


--
-- TOC entry 183 (class 1259 OID 51520)
-- Name: ventas; Type: TABLE; Schema: public; Owner: escueladigital; Tablespace: 
--

CREATE TABLE ventas (
    id_venta smallint NOT NULL,
    fecha date DEFAULT now() NOT NULL,
    id_tercero smallint NOT NULL,
    id_producto smallint NOT NULL,
    cantidad smallint NOT NULL,
    valor smallint NOT NULL,
    id_usuario smallint NOT NULL,
    CONSTRAINT ck_ventas_cantidad CHECK ((cantidad > 0)),
    CONSTRAINT ck_ventas_valor CHECK ((valor > 0))
);


ALTER TABLE ventas OWNER TO escueladigital;

--
-- TOC entry 182 (class 1259 OID 51518)
-- Name: ventas_id_venta_seq; Type: SEQUENCE; Schema: public; Owner: escueladigital
--

CREATE SEQUENCE ventas_id_venta_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE ventas_id_venta_seq OWNER TO escueladigital;

--
-- TOC entry 2116 (class 0 OID 0)
-- Dependencies: 182
-- Name: ventas_id_venta_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: escueladigital
--

ALTER SEQUENCE ventas_id_venta_seq OWNED BY ventas.id_venta;


--
-- TOC entry 1943 (class 2604 OID 51549)
-- Name: id_auditoria; Type: DEFAULT; Schema: public; Owner: escueladigital
--

ALTER TABLE ONLY auditoria ALTER COLUMN id_auditoria SET DEFAULT nextval('auditoria_id_auditoria_seq'::regclass);


--
-- TOC entry 1935 (class 2604 OID 51497)
-- Name: id_compra; Type: DEFAULT; Schema: public; Owner: escueladigital
--

ALTER TABLE ONLY compras ALTER COLUMN id_compra SET DEFAULT nextval('compras_id_compra_seq'::regclass);


--
-- TOC entry 1929 (class 2604 OID 51443)
-- Name: id_perfil; Type: DEFAULT; Schema: public; Owner: escueladigital
--

ALTER TABLE ONLY perfiles ALTER COLUMN id_perfil SET DEFAULT nextval('perfiles_id_perfil_seq'::regclass);


--
-- TOC entry 1932 (class 2604 OID 51478)
-- Name: id_producto; Type: DEFAULT; Schema: public; Owner: escueladigital
--

ALTER TABLE ONLY productos ALTER COLUMN id_producto SET DEFAULT nextval('productos_id_producto_seq'::regclass);


--
-- TOC entry 1931 (class 2604 OID 51468)
-- Name: id_tercero; Type: DEFAULT; Schema: public; Owner: escueladigital
--

ALTER TABLE ONLY terceros ALTER COLUMN id_tercero SET DEFAULT nextval('terceros_id_tercero_seq'::regclass);


--
-- TOC entry 1930 (class 2604 OID 51453)
-- Name: id_usuario; Type: DEFAULT; Schema: public; Owner: escueladigital
--

ALTER TABLE ONLY usuarios ALTER COLUMN id_usuario SET DEFAULT nextval('usuarios_id_usuario_seq'::regclass);


--
-- TOC entry 1939 (class 2604 OID 51523)
-- Name: id_venta; Type: DEFAULT; Schema: public; Owner: escueladigital
--

ALTER TABLE ONLY ventas ALTER COLUMN id_venta SET DEFAULT nextval('ventas_id_venta_seq'::regclass);


--
-- TOC entry 2101 (class 0 OID 51546)
-- Dependencies: 185
-- Data for Name: auditoria; Type: TABLE DATA; Schema: public; Owner: escueladigital
--

INSERT INTO auditoria (id_auditoria, fecha, id_usuario, accion, tabla, anterior, nuevo) VALUES (1, '2016-04-28 15:55:55.712', 2, 'INSERTAR', 'COMPRAS', '{"id_compra":1,"fecha":"2016-04-28","id_tercero":2,"id_producto":2,"cantidad":1,"valor":13500,"id_usuario":2}', NULL);
INSERT INTO auditoria (id_auditoria, fecha, id_usuario, accion, tabla, anterior, nuevo) VALUES (2, '2016-04-28 15:55:55.712', 2, 'ACTUALIZAR', 'PRODUCTO', '{"id_producto":2,"nombre":"LAVADORA","cantidad":1,"precio":8900,"id_usuario":2}', '{"id_producto":2,"nombre":"LAVADORA","cantidad":2,"precio":13500,"id_usuario":2}');
INSERT INTO auditoria (id_auditoria, fecha, id_usuario, accion, tabla, anterior, nuevo) VALUES (3, '2016-04-28 15:58:51.901', 1, 'INSERTAR', 'VENTAS', '{"id_venta":1,"fecha":"2016-04-28","id_tercero":1,"id_producto":1,"cantidad":2,"valor":15600,"id_usuario":1}', NULL);
INSERT INTO auditoria (id_auditoria, fecha, id_usuario, accion, tabla, anterior, nuevo) VALUES (4, '2016-04-28 15:58:51.901', 1, 'ACTUALIZAR', 'PRODUCTO', '{"id_producto":1,"nombre":"NEVERA","cantidad":5,"precio":12000,"id_usuario":1}', '{"id_producto":1,"nombre":"NEVERA","cantidad":3,"precio":12000,"id_usuario":1}');
INSERT INTO auditoria (id_auditoria, fecha, id_usuario, accion, tabla, anterior, nuevo) VALUES (5, '2016-04-28 22:27:31.469', 1, 'INSERTAR', 'COMPRAS', '{"id_compra":5,"fecha":"2016-04-28","id_tercero":1,"id_producto":1,"cantidad":1,"valor":15200,"id_usuario":1}', NULL);
INSERT INTO auditoria (id_auditoria, fecha, id_usuario, accion, tabla, anterior, nuevo) VALUES (6, '2016-04-28 22:27:31.469', 1, 'ACTUALIZAR', 'PRODUCTO', '{"id_producto":1,"nombre":"NEVERA","cantidad":3,"precio":12000,"id_usuario":1}', '{"id_producto":1,"nombre":"NEVERA","cantidad":4,"precio":15200,"id_usuario":1}');
INSERT INTO auditoria (id_auditoria, fecha, id_usuario, accion, tabla, anterior, nuevo) VALUES (7, '2016-04-28 22:27:56.728', 1, 'INSERTAR', 'COMPRAS', '{"id_compra":6,"fecha":"2016-04-28","id_tercero":2,"id_producto":3,"cantidad":1,"valor":13000,"id_usuario":1}', NULL);
INSERT INTO auditoria (id_auditoria, fecha, id_usuario, accion, tabla, anterior, nuevo) VALUES (8, '2016-04-28 22:27:56.728', 1, 'ACTUALIZAR', 'PRODUCTO', '{"id_producto":3,"nombre":"SECADORA","cantidad":3,"precio":7400,"id_usuario":1}', '{"id_producto":3,"nombre":"SECADORA","cantidad":4,"precio":13000,"id_usuario":1}');
INSERT INTO auditoria (id_auditoria, fecha, id_usuario, accion, tabla, anterior, nuevo) VALUES (9, '2016-04-28 23:00:43.293', 1, 'INSERTAR', 'VENTAS', '{"id_venta":2,"fecha":"2016-04-28","id_tercero":3,"id_producto":1,"cantidad":1,"valor":19760,"id_usuario":1}', NULL);
INSERT INTO auditoria (id_auditoria, fecha, id_usuario, accion, tabla, anterior, nuevo) VALUES (10, '2016-04-28 23:00:43.293', 1, 'ACTUALIZAR', 'PRODUCTO', '{"id_producto":1,"nombre":"NEVERA","cantidad":4,"precio":15200,"id_usuario":1}', '{"id_producto":1,"nombre":"NEVERA","cantidad":3,"precio":15200,"id_usuario":1}');
INSERT INTO auditoria (id_auditoria, fecha, id_usuario, accion, tabla, anterior, nuevo) VALUES (11, '2016-04-28 23:00:53.588', 1, 'INSERTAR', 'VENTAS', '{"id_venta":3,"fecha":"2016-04-28","id_tercero":2,"id_producto":3,"cantidad":3,"valor":16900,"id_usuario":1}', NULL);
INSERT INTO auditoria (id_auditoria, fecha, id_usuario, accion, tabla, anterior, nuevo) VALUES (12, '2016-04-28 23:00:53.588', 1, 'ACTUALIZAR', 'PRODUCTO', '{"id_producto":3,"nombre":"SECADORA","cantidad":4,"precio":13000,"id_usuario":1}', '{"id_producto":3,"nombre":"SECADORA","cantidad":1,"precio":13000,"id_usuario":1}');
INSERT INTO auditoria (id_auditoria, fecha, id_usuario, accion, tabla, anterior, nuevo) VALUES (13, '2016-04-28 23:22:42.418', 1, 'INSERTAR', 'VENTAS', '{"id_venta":4,"fecha":"2016-04-28","id_tercero":2,"id_producto":1,"cantidad":2,"valor":19760,"id_usuario":1}', NULL);
INSERT INTO auditoria (id_auditoria, fecha, id_usuario, accion, tabla, anterior, nuevo) VALUES (14, '2016-04-28 23:22:42.418', 1, 'ACTUALIZAR', 'PRODUCTO', '{"id_producto":1,"nombre":"NEVERA","cantidad":3,"precio":15200,"id_usuario":1}', '{"id_producto":1,"nombre":"NEVERA","cantidad":1,"precio":15200,"id_usuario":1}');
INSERT INTO auditoria (id_auditoria, fecha, id_usuario, accion, tabla, anterior, nuevo) VALUES (15, '2016-04-28 23:23:01.103', 1, 'INSERTAR', 'COMPRAS', '{"id_compra":7,"fecha":"2016-04-28","id_tercero":1,"id_producto":2,"cantidad":3,"valor":12500,"id_usuario":1}', NULL);
INSERT INTO auditoria (id_auditoria, fecha, id_usuario, accion, tabla, anterior, nuevo) VALUES (16, '2016-04-28 23:23:01.103', 1, 'ACTUALIZAR', 'PRODUCTO', '{"id_producto":2,"nombre":"LAVADORA","cantidad":2,"precio":13500,"id_usuario":2}', '{"id_producto":2,"nombre":"LAVADORA","cantidad":5,"precio":12500,"id_usuario":1}');
INSERT INTO auditoria (id_auditoria, fecha, id_usuario, accion, tabla, anterior, nuevo) VALUES (17, '2016-04-28 23:24:26.373', 1, 'INSERTAR', 'COMPRAS', '{"id_compra":8,"fecha":"2016-04-28","id_tercero":2,"id_producto":2,"cantidad":2,"valor":13600,"id_usuario":1}', NULL);
INSERT INTO auditoria (id_auditoria, fecha, id_usuario, accion, tabla, anterior, nuevo) VALUES (18, '2016-04-28 23:24:26.373', 1, 'ACTUALIZAR', 'PRODUCTO', '{"id_producto":2,"nombre":"LAVADORA","cantidad":5,"precio":12500,"id_usuario":1}', '{"id_producto":2,"nombre":"LAVADORA","cantidad":7,"precio":13600,"id_usuario":1}');
INSERT INTO auditoria (id_auditoria, fecha, id_usuario, accion, tabla, anterior, nuevo) VALUES (19, '2016-04-28 23:24:36.571', 1, 'INSERTAR', 'COMPRAS', '{"id_compra":9,"fecha":"2016-04-28","id_tercero":3,"id_producto":3,"cantidad":3,"valor":12400,"id_usuario":1}', NULL);
INSERT INTO auditoria (id_auditoria, fecha, id_usuario, accion, tabla, anterior, nuevo) VALUES (20, '2016-04-28 23:24:36.571', 1, 'ACTUALIZAR', 'PRODUCTO', '{"id_producto":3,"nombre":"SECADORA","cantidad":1,"precio":13000,"id_usuario":1}', '{"id_producto":3,"nombre":"SECADORA","cantidad":4,"precio":12400,"id_usuario":1}');
INSERT INTO auditoria (id_auditoria, fecha, id_usuario, accion, tabla, anterior, nuevo) VALUES (21, '2016-04-28 23:24:44.282', 1, 'INSERTAR', 'COMPRAS', '{"id_compra":10,"fecha":"2016-04-28","id_tercero":3,"id_producto":2,"cantidad":1,"valor":15200,"id_usuario":1}', NULL);
INSERT INTO auditoria (id_auditoria, fecha, id_usuario, accion, tabla, anterior, nuevo) VALUES (22, '2016-04-28 23:24:44.282', 1, 'ACTUALIZAR', 'PRODUCTO', '{"id_producto":2,"nombre":"LAVADORA","cantidad":7,"precio":13600,"id_usuario":1}', '{"id_producto":2,"nombre":"LAVADORA","cantidad":8,"precio":15200,"id_usuario":1}');


--
-- TOC entry 2117 (class 0 OID 0)
-- Dependencies: 184
-- Name: auditoria_id_auditoria_seq; Type: SEQUENCE SET; Schema: public; Owner: escueladigital
--

SELECT pg_catalog.setval('auditoria_id_auditoria_seq', 22, true);


--
-- TOC entry 2097 (class 0 OID 51494)
-- Dependencies: 181
-- Data for Name: compras; Type: TABLE DATA; Schema: public; Owner: escueladigital
--

INSERT INTO compras (id_compra, fecha, id_tercero, id_producto, cantidad, valor, id_usuario) VALUES (1, '2016-04-28', 2, 2, 1, 13500, 2);
INSERT INTO compras (id_compra, fecha, id_tercero, id_producto, cantidad, valor, id_usuario) VALUES (5, '2016-04-28', 1, 1, 1, 15200, 1);
INSERT INTO compras (id_compra, fecha, id_tercero, id_producto, cantidad, valor, id_usuario) VALUES (6, '2016-04-28', 2, 3, 1, 13000, 1);
INSERT INTO compras (id_compra, fecha, id_tercero, id_producto, cantidad, valor, id_usuario) VALUES (7, '2016-04-28', 1, 2, 3, 12500, 1);
INSERT INTO compras (id_compra, fecha, id_tercero, id_producto, cantidad, valor, id_usuario) VALUES (8, '2016-04-28', 2, 2, 2, 13600, 1);
INSERT INTO compras (id_compra, fecha, id_tercero, id_producto, cantidad, valor, id_usuario) VALUES (9, '2016-04-28', 3, 3, 3, 12400, 1);
INSERT INTO compras (id_compra, fecha, id_tercero, id_producto, cantidad, valor, id_usuario) VALUES (10, '2016-04-28', 3, 2, 1, 15200, 1);


--
-- TOC entry 2118 (class 0 OID 0)
-- Dependencies: 180
-- Name: compras_id_compra_seq; Type: SEQUENCE SET; Schema: public; Owner: escueladigital
--

SELECT pg_catalog.setval('compras_id_compra_seq', 10, true);


--
-- TOC entry 2089 (class 0 OID 51440)
-- Dependencies: 173
-- Data for Name: perfiles; Type: TABLE DATA; Schema: public; Owner: escueladigital
--

INSERT INTO perfiles (id_perfil, perfil) VALUES (1, 'ADMINISTRADOR');
INSERT INTO perfiles (id_perfil, perfil) VALUES (2, 'CAJERO');


--
-- TOC entry 2119 (class 0 OID 0)
-- Dependencies: 172
-- Name: perfiles_id_perfil_seq; Type: SEQUENCE SET; Schema: public; Owner: escueladigital
--

SELECT pg_catalog.setval('perfiles_id_perfil_seq', 2, true);


--
-- TOC entry 2095 (class 0 OID 51475)
-- Dependencies: 179
-- Data for Name: productos; Type: TABLE DATA; Schema: public; Owner: escueladigital
--

INSERT INTO productos (id_producto, nombre, cantidad, precio, id_usuario) VALUES (4, 'CALENTADOR', 1, 3200, 2);
INSERT INTO productos (id_producto, nombre, cantidad, precio, id_usuario) VALUES (1, 'NEVERA', 1, 15200, 1);
INSERT INTO productos (id_producto, nombre, cantidad, precio, id_usuario) VALUES (3, 'SECADORA', 4, 12400, 1);
INSERT INTO productos (id_producto, nombre, cantidad, precio, id_usuario) VALUES (2, 'LAVADORA', 8, 15200, 1);


--
-- TOC entry 2120 (class 0 OID 0)
-- Dependencies: 178
-- Name: productos_id_producto_seq; Type: SEQUENCE SET; Schema: public; Owner: escueladigital
--

SELECT pg_catalog.setval('productos_id_producto_seq', 4, true);


--
-- TOC entry 2093 (class 0 OID 51465)
-- Dependencies: 177
-- Data for Name: terceros; Type: TABLE DATA; Schema: public; Owner: escueladigital
--

INSERT INTO terceros (id_tercero, identificacion, nombre, direccion, telefono) VALUES (1, '123456789', 'PROVETODO LTDA', 'CRA 1 # 2 - 3', '2114477 EXT 123');
INSERT INTO terceros (id_tercero, identificacion, nombre, direccion, telefono) VALUES (2, '987654321', 'COMPRATODO S.A.S.', 'AV BUSQUELA CRA ENCUENTRELA', '4857965');
INSERT INTO terceros (id_tercero, identificacion, nombre, direccion, telefono) VALUES (3, '741852963', 'CLIENTE FRECUENTE', 'EL VECINO', '5478414');


--
-- TOC entry 2121 (class 0 OID 0)
-- Dependencies: 176
-- Name: terceros_id_tercero_seq; Type: SEQUENCE SET; Schema: public; Owner: escueladigital
--

SELECT pg_catalog.setval('terceros_id_tercero_seq', 3, true);


--
-- TOC entry 2091 (class 0 OID 51450)
-- Dependencies: 175
-- Data for Name: usuarios; Type: TABLE DATA; Schema: public; Owner: escueladigital
--

INSERT INTO usuarios (id_usuario, usuario, nombre, clave, id_perfil) VALUES (1, 'alozada', 'ALEXYS LOZADA', '2cbcd694efea34abdf2f1857595eaa17', 1);
INSERT INTO usuarios (id_usuario, usuario, nombre, clave, id_perfil) VALUES (2, 'vendedor', 'PEDRO PEREZ', '2cbcd694efea34abdf2f1857595eaa17', 2);


--
-- TOC entry 2122 (class 0 OID 0)
-- Dependencies: 174
-- Name: usuarios_id_usuario_seq; Type: SEQUENCE SET; Schema: public; Owner: escueladigital
--

SELECT pg_catalog.setval('usuarios_id_usuario_seq', 2, true);


--
-- TOC entry 2099 (class 0 OID 51520)
-- Dependencies: 183
-- Data for Name: ventas; Type: TABLE DATA; Schema: public; Owner: escueladigital
--

INSERT INTO ventas (id_venta, fecha, id_tercero, id_producto, cantidad, valor, id_usuario) VALUES (1, '2016-04-28', 1, 1, 2, 15600, 1);
INSERT INTO ventas (id_venta, fecha, id_tercero, id_producto, cantidad, valor, id_usuario) VALUES (2, '2016-04-28', 3, 1, 1, 19760, 1);
INSERT INTO ventas (id_venta, fecha, id_tercero, id_producto, cantidad, valor, id_usuario) VALUES (3, '2016-04-28', 2, 3, 3, 16900, 1);
INSERT INTO ventas (id_venta, fecha, id_tercero, id_producto, cantidad, valor, id_usuario) VALUES (4, '2016-04-28', 2, 1, 2, 19760, 1);


--
-- TOC entry 2123 (class 0 OID 0)
-- Dependencies: 182
-- Name: ventas_id_venta_seq; Type: SEQUENCE SET; Schema: public; Owner: escueladigital
--

SELECT pg_catalog.setval('ventas_id_venta_seq', 4, true);


--
-- TOC entry 1966 (class 2606 OID 51555)
-- Name: pk_auditoria; Type: CONSTRAINT; Schema: public; Owner: escueladigital; Tablespace: 
--

ALTER TABLE ONLY auditoria
    ADD CONSTRAINT pk_auditoria PRIMARY KEY (id_auditoria);


--
-- TOC entry 1962 (class 2606 OID 51502)
-- Name: pk_compras; Type: CONSTRAINT; Schema: public; Owner: escueladigital; Tablespace: 
--

ALTER TABLE ONLY compras
    ADD CONSTRAINT pk_compras PRIMARY KEY (id_compra);


--
-- TOC entry 1946 (class 2606 OID 51445)
-- Name: pk_perfiles; Type: CONSTRAINT; Schema: public; Owner: escueladigital; Tablespace: 
--

ALTER TABLE ONLY perfiles
    ADD CONSTRAINT pk_perfiles PRIMARY KEY (id_perfil);


--
-- TOC entry 1958 (class 2606 OID 51482)
-- Name: pk_productos; Type: CONSTRAINT; Schema: public; Owner: escueladigital; Tablespace: 
--

ALTER TABLE ONLY productos
    ADD CONSTRAINT pk_productos PRIMARY KEY (id_producto);


--
-- TOC entry 1954 (class 2606 OID 51470)
-- Name: pk_terceros; Type: CONSTRAINT; Schema: public; Owner: escueladigital; Tablespace: 
--

ALTER TABLE ONLY terceros
    ADD CONSTRAINT pk_terceros PRIMARY KEY (id_tercero);


--
-- TOC entry 1950 (class 2606 OID 51455)
-- Name: pk_usuarios; Type: CONSTRAINT; Schema: public; Owner: escueladigital; Tablespace: 
--

ALTER TABLE ONLY usuarios
    ADD CONSTRAINT pk_usuarios PRIMARY KEY (id_usuario);


--
-- TOC entry 1964 (class 2606 OID 51528)
-- Name: pk_ventas; Type: CONSTRAINT; Schema: public; Owner: escueladigital; Tablespace: 
--

ALTER TABLE ONLY ventas
    ADD CONSTRAINT pk_ventas PRIMARY KEY (id_venta);


--
-- TOC entry 1948 (class 2606 OID 51447)
-- Name: uk_perfiles; Type: CONSTRAINT; Schema: public; Owner: escueladigital; Tablespace: 
--

ALTER TABLE ONLY perfiles
    ADD CONSTRAINT uk_perfiles UNIQUE (perfil);


--
-- TOC entry 1960 (class 2606 OID 51484)
-- Name: uk_productos; Type: CONSTRAINT; Schema: public; Owner: escueladigital; Tablespace: 
--

ALTER TABLE ONLY productos
    ADD CONSTRAINT uk_productos UNIQUE (nombre);


--
-- TOC entry 1956 (class 2606 OID 51472)
-- Name: uk_terceros; Type: CONSTRAINT; Schema: public; Owner: escueladigital; Tablespace: 
--

ALTER TABLE ONLY terceros
    ADD CONSTRAINT uk_terceros UNIQUE (identificacion);


--
-- TOC entry 1952 (class 2606 OID 51457)
-- Name: uk_usuarios; Type: CONSTRAINT; Schema: public; Owner: escueladigital; Tablespace: 
--

ALTER TABLE ONLY usuarios
    ADD CONSTRAINT uk_usuarios UNIQUE (usuario);


--
-- TOC entry 1977 (class 2620 OID 51567)
-- Name: tg_compras_auditoria; Type: TRIGGER; Schema: public; Owner: escueladigital
--

CREATE TRIGGER tg_compras_auditoria AFTER INSERT ON compras FOR EACH ROW EXECUTE PROCEDURE tg_compras_auditoria();


--
-- TOC entry 1976 (class 2620 OID 51565)
-- Name: tg_productos_auditoria; Type: TRIGGER; Schema: public; Owner: escueladigital
--

CREATE TRIGGER tg_productos_auditoria AFTER UPDATE ON productos FOR EACH ROW EXECUTE PROCEDURE tg_productos_auditoria();


--
-- TOC entry 1978 (class 2620 OID 51570)
-- Name: tg_ventas_auditoria; Type: TRIGGER; Schema: public; Owner: escueladigital
--

CREATE TRIGGER tg_ventas_auditoria AFTER INSERT ON ventas FOR EACH ROW EXECUTE PROCEDURE tg_ventas_auditoria();


--
-- TOC entry 1975 (class 2606 OID 51556)
-- Name: fk_auditoria_usuarios; Type: FK CONSTRAINT; Schema: public; Owner: escueladigital
--

ALTER TABLE ONLY auditoria
    ADD CONSTRAINT fk_auditoria_usuarios FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 1970 (class 2606 OID 51508)
-- Name: fk_compras_productos; Type: FK CONSTRAINT; Schema: public; Owner: escueladigital
--

ALTER TABLE ONLY compras
    ADD CONSTRAINT fk_compras_productos FOREIGN KEY (id_producto) REFERENCES productos(id_producto) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 1969 (class 2606 OID 51503)
-- Name: fk_compras_terceros; Type: FK CONSTRAINT; Schema: public; Owner: escueladigital
--

ALTER TABLE ONLY compras
    ADD CONSTRAINT fk_compras_terceros FOREIGN KEY (id_tercero) REFERENCES terceros(id_tercero) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 1971 (class 2606 OID 51513)
-- Name: fk_compras_usuarios; Type: FK CONSTRAINT; Schema: public; Owner: escueladigital
--

ALTER TABLE ONLY compras
    ADD CONSTRAINT fk_compras_usuarios FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 1968 (class 2606 OID 51485)
-- Name: fk_productos_usuarios; Type: FK CONSTRAINT; Schema: public; Owner: escueladigital
--

ALTER TABLE ONLY productos
    ADD CONSTRAINT fk_productos_usuarios FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 1967 (class 2606 OID 51458)
-- Name: fk_usuarios_perfiles; Type: FK CONSTRAINT; Schema: public; Owner: escueladigital
--

ALTER TABLE ONLY usuarios
    ADD CONSTRAINT fk_usuarios_perfiles FOREIGN KEY (id_perfil) REFERENCES perfiles(id_perfil) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 1973 (class 2606 OID 51534)
-- Name: fk_ventas_productos; Type: FK CONSTRAINT; Schema: public; Owner: escueladigital
--

ALTER TABLE ONLY ventas
    ADD CONSTRAINT fk_ventas_productos FOREIGN KEY (id_producto) REFERENCES productos(id_producto) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 1972 (class 2606 OID 51529)
-- Name: fk_ventas_terceros; Type: FK CONSTRAINT; Schema: public; Owner: escueladigital
--

ALTER TABLE ONLY ventas
    ADD CONSTRAINT fk_ventas_terceros FOREIGN KEY (id_tercero) REFERENCES terceros(id_tercero) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 1974 (class 2606 OID 51539)
-- Name: fk_ventas_usuario; Type: FK CONSTRAINT; Schema: public; Owner: escueladigital
--

ALTER TABLE ONLY ventas
    ADD CONSTRAINT fk_ventas_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 2108 (class 0 OID 0)
-- Dependencies: 5
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


-- Completed on 2016-04-28 23:57:37

--
-- PostgreSQL database dump complete
--

