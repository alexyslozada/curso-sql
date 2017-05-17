package psql

import "github.com/alexyslozada/curso-sql/model"

func UserGetByID(id int) (model.Usuario, error) {
	q := `SELECT a.id_usuario, a.nombre, b.id_perfil, b.perfil
		FROM usuarios as a NATURAL JOIN perfiles as b
		WHERE a.id_usuario = $1`
	u := model.Usuario{}

	db := getConnection()
	defer db.Close()

	stmt, err := db.Prepare(q)
	if err != nil {
		return u, err
	}
	defer stmt.Close()

	err = stmt.QueryRow(id).Scan(&u.ID, &u.Nombre, &u.PerfilID, &u.Perfil)
	if err != nil {
		return u, err
	}

	return u, nil
}
