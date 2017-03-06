(require 'pg)
(require 'cl-lib)
(require 's)

;; Basic database config:
;; (setq *db-config* (list "dbname-fakedb" "postgres-user"
;;                         "postgres-password" "hostname-localhost"))
;;
;; Basic usage:
;; (gen-entity "table-name")
;;
;; or
;; 
;; (gen-entity "table-name" "schema-name")
;;
;; Interactive command:
;; entity-gen-generate
;;

(cl-defstruct column-info name data-type column-default)

(defun list-to-column-info (column)
  (make-column-info :name (car column)
		    :data-type (cadr column)
		    :column-default (caddr column)))

(defun read-table-info (table-name schema-name)
  (let* ((conn (apply 'pg:connect *db-config*))
	 (columns (pg:result (pg:exec conn
				      "SELECT "
				      "column_name, data_type, column_default "
				      "FROM information_schema.columns "
				      "WHERE table_name = "
				      "'" table-name "'"
                                      "and table_schema = "
                                      "'" schema-name "' ")

			     :tuples)))
    (pg:disconnect conn)
    (mapcar 'list-to-column-info columns)))

(defun read-primary-key-columns (table-name schema-name)
  (let* ((conn (apply 'pg:connect *db-config*))
	 (columns (pg:result (pg:exec conn
				      "SELECT "
				      "column_name from "
				      "information_schema.key_column_usage "
				      "as k natural full join "
				      "information_schema.table_constraints "
				      "as tc WHERE "
				      "constraint_type = 'PRIMARY KEY' "
				      "and table_name = "
				      "'" table-name "' "
                                      "and table_schema = "
                                      "'" schema-name "' ")
			     :tuples)))
    (pg:disconnect conn)
    (mapcar 'car columns)))

(setq *data-map*
      (list (cons "integer" "Integer")
	    (cons "text" "String")
	    (cons "char" "String")
	    (cons "varchar" "String")
	    (cons "date" "Date")
	    (cons "timestamp" "Timestamp")
	    (cons "numeric" "Float")))
		  
(defun gen-type (col)  
  (let* ((pg-type (car (s-split " " (column-info-data-type col))))
	 (java-type-info (assoc pg-type *data-map*)))
    (if (null java-type-info)
	pg-type
	(cdr java-type-info))))

(defun gen-attr (col id-col)
  (let* ((pg-name (column-info-name col))
	 (java-name (s-lower-camel-case pg-name)))
    (insert "\n")
    (when (equal pg-name id-col)
      (insert "    @Id\n"))
    (insert (format "    @Column(name=\"%s\")\n"
		    pg-name))
    (insert (format "    private %s %s;\n"
		    (gen-type col)
		    java-name))))

(defun find-id-column (keys)
  (when (and (not (null (car keys)))
	     (null (cdr keys)))
    (car keys)))

(defun gen-entity (table-name &optional schema-name)
  (when (not schema-name)
    (setq schema-name "public"))
  (let ((id-col (find-id-column (read-primary-key-columns table-name schema-name)))
	(class-name (s-upper-camel-case table-name))
	(columns (read-table-info table-name schema-name)))
    (switch-to-buffer-other-window "*codegen*")
    (erase-buffer)
    (insert "@Entity\n")
    (if (equal schema-name "public")
        (insert (format "@Table(name=\"%s\")\n" table-name))
      (insert (format "@Table(name=\"%s.%s\")\n" schema-name table-name)))
    (insert (format "class %s {\n" class-name))
    (dolist (col columns)
      (gen-attr col id-col))
    (insert "}\n")
    (other-window 1)))

(defun entity-gen-generate ()
  (interactive)
  (gen-entity (read-from-minibuffer "Enter table name: ")))
