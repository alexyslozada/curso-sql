package psql

import (
	_ "github.com/lib/pq"
	"database/sql"
	"fmt"
	"log"
)

func getConnection() *sql.DB {
	dsn := fmt.Sprintf("postgres://%s:%s@%s:%s/%s?sslmode=%s",
				"escueladigital",
				"escueladigital",
				"127.0.0.1",
				"5432",
				"escueladigital",
				"disable")
	db, err := sql.Open("postgres", dsn)
	if err != nil {
		log.Fatal(err)
		return nil
	}
	return db
}
