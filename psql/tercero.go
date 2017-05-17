package psql

import "github.com/alexyslozada/curso-sql/model"

func TerceroListar() ([]model.Tercero, error) {
	q := `SELECT id_tercero, nombre FROM consulta_terceros()`
	ts := make([]model.Tercero, 0)
	t := model.Tercero{}

	db := getConnection()
	defer db.Close()

	stmt, err := db.Prepare(q)
	if err != nil {
		return ts, err
	}
	defer stmt.Close()

	rows, err := stmt.Query()
	if err != nil {
		return ts, err
	}
	defer rows.Close()

	for rows.Next() {
		err = rows.Scan(&t.ID, &t.Nombre)
		if err != nil {
			return ts, err
		}

		ts = append(ts, t)
	}

	return ts, nil
}