(in-package :cl-ecs)

(defmacro defcomponent (name &body (fields))
  "Define a new component with the specified fields.
Also defines accessors for each field to be used on an entity."
  `(progn
     ,@(loop :for f :in fields
             :for field = (intern (format nil "~A-~A" name f))
             :for key = (make-keyword field)
             :do (add-component-field name field)
             :collect `(defun ,field (id)
                         (entity-attr id ,key))
             :collect `(defun (setf ,field) (value id)
                         (setf (entity-attr id ,key) value)))
     ',name))

(defun all-components ()
  "Get a list of all defined components."
  (hash-table-keys (ecs-component-fields *ecs*)))

(defun component-fields (component)
  "Get a list of fields for the specified component."
  (gethash component (ecs-component-fields *ecs*)))

(defun (setf component-fields) (value component)
  "Assign a list of fields to the specified component."
  (setf (gethash component (ecs-component-fields *ecs*)) value))

(defun add-component-field (component field)
  "Add a new field to the specified component."
  (pushnew field (component-fields component)))

(defun add-component (id component attrs)
  "Add a new component to the specified entity."
  (when (member component (all-components))
    (pushnew component (entity-components id)))
  (update-systems)
  (loop :for (field . value) :in (reverse (plist-alist attrs))
        :for fields = (mapcar #'make-keyword (component-fields component))
        :when (member field fields)
          :do (setf (entity-attr id field) value)))

(defun remove-component (id component)
  "Remove a component from the specified entity."
  (deletef (entity-components id) component)
  (update-systems)
  (loop :for field :in (component-fields component)
        :when (entity-attr id field)
          :do (remove-entity-attr id field)))