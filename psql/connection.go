package psql

import (
	"database/sql"
	"encoding/json"
	"fmt"
	_ "github.com/lib/pq"
	"io/ioutil"
	"log"
)

type Configuration struct {
	Server   string `json:"server"`
	Port     string `json:"port"`
	Database string `json:"database"`
	User     string `json:"user"`
	Password string `json:"password"`
}

var c Configuration

func init() {
	c = loadConfiguration()
}

func loadConfiguration() Configuration {
	c := Configuration{}

	bs, err := ioutil.ReadFile("configuration.json")
	if err != nil {
		log.Fatal("Error al leer el archivo json: " + err.Error())
	}
	err = json.Unmarshal(bs, &c)
	if err != nil {
		log.Fatal("Error al decodificar el json: " + err.Error())
	}

	return c
}

func getConnection() *sql.DB {
	dsn := fmt.Sprintf("postgres://%s:%s@%s:%s/%s?sslmode=%s",
		c.User,
		c.Password,
		c.Server,
		c.Port,
		c.Database,
		"disable")
	db, err := sql.Open("postgres", dsn)
	if err != nil {
		log.Fatal(err)
		return nil
	}
	return db
}
