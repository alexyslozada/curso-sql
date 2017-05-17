package psql

import (
	"github.com/alexyslozada/curso-sql/model"
)

func ProductoListar() ([]model.Producto, error) {
	q := `SELECT id_producto, nombre, cantidad, precio FROM consulta_productos()`
	ps := make([]model.Producto, 0)
	p := model.Producto{}

	db := getConnection()
	defer db.Close()

	stmt, err := db.Prepare(q)
	if err != nil {
		return ps, err
	}
	defer stmt.Close()

	rows, err := stmt.Query()
	if err != nil {
		return ps, err
	}
	defer rows.Close()

	for rows.Next() {
		err = rows.Scan(&p.ID, &p.Nombre, &p.Cantidad, &p.Precio)
		if err != nil {
			return ps, err
		}

		ps = append(ps, p)
	}

	return ps, nil
}
