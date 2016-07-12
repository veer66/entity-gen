# entity-gen
An Emacs Lisp script for generating simple JPA entity/class code


## Configuration (in .emacs)
````lisp
(setq *db-config* (list "dbname-fakedb" "postgres-user"
                         "postgres-password" "hostname-localhost"))
````


## Usage

````lisp
(gen-entity "table-name")
````
