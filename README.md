# entity-gen
An Emacs Lisp script for generating simple JPA entity/class code from a PostgreSQL table


## Configuration (in .emacs)
````lisp
(setq *db-config* '("dbname-fakedb" "postgres-user"
                    "postgres-password" "hostname-localhost"))
````


## Usage

````lisp
(gen-entity "table-name")
````

````lisp
(gen-entity "table-name" "schema-name")
````

## Interactive command

      M-x entity-gen-generate