package psql

import "github.com/alexyslozada/curso-sql/model"

func Vender(cliente, producto, cantidad, usuario int) (int, error) {
	q := `SELECT vender($1, $2, $3, $4)`
	r := 0

	db := getConnection()
	defer db.Close()

	stmt, err := db.Prepare(q)
	if err != nil {
		return r, err
	}
	defer stmt.Close()

	err = stmt.QueryRow(cliente, producto, cantidad, usuario).Scan(&r)
	if err != nil {
		return r, err
	}

	return r, nil
}

func VentaListar(limite, pagina int) ([]model.Venta, error) {
	q := `SELECT id_venta, fecha, cliente, producto, cantidad, valor FROM consulta_ventas($1, $2)`
	vs := make([]model.Venta,0)
	v := model.Venta{}

	db := getConnection()
	defer db.Close()

	stmt, err := db.Prepare(q)
	if err != nil {
		return vs, err
	}
	defer stmt.Close()

	rows, err := stmt.Query(limite, pagina)
	if err != nil {
		return vs, err
	}
	defer rows.Close()

	for rows.Next() {
		err = rows.Scan(&v.ID, &v.Fecha, &v.TerceroNombre, &v.ProductoNombre, &v.Cantidad, &v.Valor)
		if err != nil {
			return vs, err
		}

		vs = append(vs, v)
	}

	return vs, nil
}