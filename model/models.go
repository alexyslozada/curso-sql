package model

import "time"

type Usuario struct {
	ID       int
	Usuario  string
	Nombre   string
	Clave    string
	PerfilID int
	Perfil   string
}

type Perfil struct {
	ID     int
	Perfil string
}

type Producto struct {
	ID        int
	Nombre    string
	Cantidad  int
	Precio    int
	UsuarioID int
}

type Tercero struct {
	ID             int
	Identificacion string
	Nombre         string
	Direccion      string
	Telefono       string
}

type Compra struct {
	ID             int
	Fecha          time.Time
	TerceroID      int
	TerceroNombre  string
	ProductoID     int
	ProductoNombre string
	Cantidad       int
	Valor          int
	UsuarioID      int
}

type Venta struct {
	ID             int
	Fecha          time.Time
	TerceroID      int
	TerceroNombre  string
	ProductoID     int
	ProductoNombre string
	Cantidad       int
	Valor          int
	UsuarioID      int
}
