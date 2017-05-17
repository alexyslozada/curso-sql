package psql

import "github.com/alexyslozada/curso-sql/model"

func Comprar(proveedor, producto, cantidad, valor, usuario int) (int, error)  {
	q := `SELECT comprar ($1, $2, $3, $4, $5)`
	r := 0

	db := getConnection()
	defer db.Close()

	stmt, err := db.Prepare(q)
	if err != nil {
		return r, err
	}
	defer stmt.Close()

	err = stmt.QueryRow(proveedor, producto, cantidad, valor, usuario).Scan(&r)
	if err != nil {
		return r, err
	}

	return r, nil
}

func CompraConsulta(limite, pagina int) ([]model.Compra, error) {
	q := `SELECT id_compra, fecha, cliente, producto, cantidad, valor
		FROM consulta_compras($1, $2)`
	cs := make([]model.Compra, 0)
	c := model.Compra{}

	db := getConnection()
	defer db.Close()

	stmt, err := db.Prepare(q)
	if err != nil {
		return cs, err
	}
	defer stmt.Close()

	rows, err := stmt.Query(limite, pagina)
	if err != nil {
		return cs, err
	}
	defer rows.Close()

	for rows.Next() {
		err = rows.Scan(&c.ID, &c.Fecha, &c.TerceroNombre, &c.ProductoNombre, &c.Cantidad, &c.Valor)
		if err != nil {
			return cs, err
		}

		cs = append(cs, c)
	}

	return cs, nil
}