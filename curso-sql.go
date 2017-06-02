package main

import (
	"fmt"
	"github.com/alexyslozada/curso-sql/model"
	"github.com/alexyslozada/curso-sql/psql"
	"github.com/satori/go.uuid"
	"html/template"
	"net/http"
	"strconv"
	"strings"
)

type mensaje struct {
	Mensaje string
}

type datos struct {
	Terceros  []model.Tercero
	Productos []model.Producto
	Mensaje   string
}

var (
	dbSessions = map[string]int{} // SessionID and UserID
	tpl        *template.Template
)

func init() {
	tpl = template.Must(template.ParseGlob("public/*.gohtml"))
}

func main() {
	http.Handle("/resources/", http.StripPrefix("/resources", http.FileServer(http.Dir("resources"))))
	http.HandleFunc("/", index)
	http.HandleFunc("/autenticar", autenticar)
	http.HandleFunc("/inicio", inicio)
	http.HandleFunc("/lista-productos", listaProductos)
	http.HandleFunc("/lista-compras", listaCompras)
	http.HandleFunc("/lista-ventas", listaVentas)
	http.HandleFunc("/ventas", ventas)
	http.HandleFunc("/compras", compras)
	http.HandleFunc("/logout", logout)
	http.Handle("/favicon.ico", http.NotFoundHandler())
	http.ListenAndServe(":7909", nil)
}

func index(w http.ResponseWriter, r *http.Request) {
	u := model.Usuario{}
	m := mensaje{}

	cookie, err := r.Cookie("session_sql")
	if err != nil {
		id := uuid.NewV4()
		cookie = &http.Cookie{
			Name:     "session_sql",
			Value:    id.String(),
			HttpOnly: true,
			Path:     "/",
		}
		http.SetCookie(w, cookie)
	}

	u, err = getUserFromSession(r)
	if err != nil {
		if !strings.Contains(err.Error(), "named cookie not present") {
			m.Mensaje = err.Error()
		}
		tpl.ExecuteTemplate(w, "index.gohtml", nil)
		return
	}

	if u.ID > 0 {
		http.Redirect(w, r, "/lista-productos", http.StatusTemporaryRedirect)
		return
	}

	tpl.ExecuteTemplate(w, "index.gohtml", m)
}

func autenticar(w http.ResponseWriter, r *http.Request) {
	if r.Method == http.MethodPost {
		cookie, err := r.Cookie("session_sql")
		if err != nil {
			fmt.Fprint(w, err.Error())
			return
		}
		usuario := r.FormValue("usuario")
		clave := r.FormValue("clave")

		u, err := psql.Autentication(usuario, clave)
		if err != nil {
			m := mensaje{Mensaje: err.Error()}
			tpl.ExecuteTemplate(w, "index.gohtml", m)
			return
		}
		dbSessions[cookie.Value] = u.ID

		http.Redirect(w, r, "/lista-productos", http.StatusSeeOther)
	}
}

func inicio(w http.ResponseWriter, r *http.Request) {
	cookie, err := r.Cookie("session_sql")
	u := model.Usuario{}
	if err != nil {
		fmt.Fprint(w, err.Error())
		return
	}

	if userID, ok := dbSessions[cookie.Value]; ok {
		u, err = psql.UserGetByID(userID)
		if err != nil {
			http.Error(w, err.Error(), http.StatusForbidden)
			return
		}
	}

	tpl.ExecuteTemplate(w, "inicio.gohtml", u)
}

func logout(w http.ResponseWriter, r *http.Request) {
	c, _ := r.Cookie("session_sql")
	delete(dbSessions, c.Value)
	c = &http.Cookie{
		Name:   "session_sql",
		Value:  "",
		MaxAge: -1,
	}
	http.SetCookie(w, c)

	http.Redirect(w, r, "/", http.StatusSeeOther)
}

func listaProductos(w http.ResponseWriter, r *http.Request) {
	ps, err := psql.ProductoListar()
	if err != nil {
		fmt.Fprint(w, "No se pudo listar la lsita de productos: "+err.Error())
		return
	}
	tpl.ExecuteTemplate(w, "lista-productos.gohtml", ps)
}

func listaCompras(w http.ResponseWriter, r *http.Request) {
	type data struct {
		Compras  []model.Compra
		Cantidad int
		Valor    int
	}
	d := data{}
	l, p := 10, 1

	if r.Method == http.MethodPost {
		l, _ = strconv.Atoi(r.FormValue("limite"))
		p, _ = strconv.Atoi(r.FormValue("pagina"))
	}
	cs, err := psql.CompraConsulta(l, p)
	if err != nil {
		fmt.Fprint(w, "No se pudo listar la lsita de productos: "+err.Error())
		return
	}
	for _, c := range cs {
		d.Cantidad += c.Cantidad
		d.Valor += c.Valor
	}
	d.Compras = cs
	tpl.ExecuteTemplate(w, "lista-compras.gohtml", d)
}

func listaVentas(w http.ResponseWriter, r *http.Request) {
	type data struct {
		Ventas   []model.Venta
		Cantidad int
		Valor    int
	}
	d := data{}
	l, p := 10, 1

	if r.Method == http.MethodPost {
		l, _ = strconv.Atoi(r.FormValue("limite"))
		p, _ = strconv.Atoi(r.FormValue("pagina"))
	}

	cs, err := psql.VentaListar(l, p)
	if err != nil {
		fmt.Fprint(w, "No se pudo listar la lsita de productos: "+err.Error())
		return
	}

	for _, c := range cs {
		d.Cantidad += c.Cantidad
		d.Valor += c.Valor
	}

	d.Ventas = cs
	tpl.ExecuteTemplate(w, "lista-ventas.gohtml", d)
}

func ventas(w http.ResponseWriter, r *http.Request) {
	d, _ := loadDataForSales()

	if r.Method == http.MethodPost {
		u, err := getUserFromSession(r)
		if err != nil {
			http.Redirect(w, r, "/logout", http.StatusSeeOther)
			return
		}

		c, _ := strconv.Atoi(r.FormValue("cliente"))
		p, _ := strconv.Atoi(r.FormValue("producto"))
		n, _ := strconv.Atoi(r.FormValue("cantidad"))

		i, err := psql.Vender(c, p, n, u.ID)
		if err != nil {
			d.Mensaje = err.Error()
			tpl.ExecuteTemplate(w, "ventas.gohtml", d)
			return
		}

		is := strconv.Itoa(i)
		d.Mensaje = "Venta creada con el id: " + is
	}
	tpl.ExecuteTemplate(w, "ventas.gohtml", d)
}

func loadDataForSales() (datos, error) {
	d := datos{}

	p, err := psql.ProductoListar()
	if err != nil {
		d.Mensaje = err.Error()
		return d, err
	}

	t, err := psql.TerceroListar()
	if err != nil {
		d.Mensaje = err.Error()
		return d, err
	}

	d.Terceros = t
	d.Productos = p

	return d, nil
}

func compras(w http.ResponseWriter, r *http.Request) {
	type dataBuy struct {
		Proveedores []model.Tercero
		Productos   []model.Producto
		Mensaje     string
	}

	d := dataBuy{}

	p, err := psql.TerceroListar()
	if err != nil {
		d.Mensaje = err.Error()
		tpl.ExecuteTemplate(w, "compras.gohtml", d)
		return
	}

	o, err := psql.ProductoListar()
	if err != nil {
		d.Mensaje = err.Error()
		tpl.ExecuteTemplate(w, "compras.gohtml", d)
		return
	}

	d.Proveedores = p
	d.Productos = o

	if r.Method == http.MethodPost {
		u, err := getUserFromSession(r)
		if err != nil {
			http.Redirect(w, r, "/logout", http.StatusSeeOther)
			return
		}

		proveedor, _ := strconv.Atoi(r.FormValue("proveedor"))
		producto, _ := strconv.Atoi(r.FormValue("producto"))
		cantidad, _ := strconv.Atoi(r.FormValue("cantidad"))
		valor, _ := strconv.Atoi(r.FormValue("valor"))

		i, err := psql.Comprar(proveedor, producto, cantidad, valor, u.ID)
		if err != nil {
			d.Mensaje = err.Error()
			tpl.ExecuteTemplate(w, "compras.gohtml", d)
			return
		}

		is := strconv.Itoa(i)
		d.Mensaje = "Compra realizada correctamente con el id: " + is
		tpl.ExecuteTemplate(w, "compras.gohtml", d)
		return
	}

	tpl.ExecuteTemplate(w, "compras.gohtml", d)
}

func getUserFromSession(r *http.Request) (model.Usuario, error) {
	u := model.Usuario{}
	cookie, err := r.Cookie("session_sql")
	if err != nil {
		return u, err
	}

	if userID, ok := dbSessions[cookie.Value]; ok {
		u, err = psql.UserGetByID(userID)
		if err != nil {
			return u, err
		}
	}

	return u, nil
}
