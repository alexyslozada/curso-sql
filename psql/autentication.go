package psql

import "github.com/alexyslozada/curso-sql/model"

func Autentication(user, pass string) (model.Usuario, error) {
	q := `SELECT id_usuario, nombre, id_perfil, perfil FROM autenticacion($1, $2)`
	u := model.Usuario{}

	db := getConnection()
	defer db.Close()

	stmt, err := db.Prepare(q)
	if err != nil {
		return u, err
	}
	defer stmt.Close()

	err = stmt.QueryRow(user, pass).Scan(&u.ID, &u.Nombre, &u.PerfilID, &u.Perfil)
	if err != nil {
		return u, err
	}

	return u, nil
}
