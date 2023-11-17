# Guia de estilo para el codigo en este repositorio

## Sobre las funciones que reciban algun DataFrame como parametro

Si una funcion recibe un DataFrame como parametro, se debe tener un bloque de condiciones
donde se emitan errores descriptivos de la columna que se requiere

## Sobre el momento adecuado para hacer ciertas operaciones sobre nuestros dataframes

Utilizar select solo al final de los queries cuando ya queramos entregar una tabla
"terminada", o cuando sea conveniente para evitar que 2 columnas tengan el mismo
nombre, no sabemos cuando podriamos necesitar una columna que en este momento estamos
excluyendo.

Los Emails deben pasarse a lowercase en la primera oportunidad posible, esto disminuye
la posibilidad de que 2 emails iguales con cases diferentes sean identificados como
distintos emails.

## Sobre la documentacion del codigo

Cada funcion debe tener una descripcion sencilla de lo que entrega.

Despues, las columnas que ya se sabe que son y se ocupan en algun lado, junto con
una descripcion de lo que es la columna.

Despues un listado del total de columnas que se entregan con el DataFrame.

En caso que el total de las columnas sean ocupadas, listarlas como (Total) pero
con su respectiva descripcion.

Finalmente, una descripcion de los parametros que pide la funcion.

Nota: No comentar el parametro session.

## Definiciones

STORE_ID: identificador numerico de una tienda (CC, CECO, Centro de Costo)