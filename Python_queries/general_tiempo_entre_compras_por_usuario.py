from snowflake.snowpark import DataFrame, Window
from snowflake.snowpark.functions import row_number, col, avg

def get_tiempo_entre_compras_por_usuario(transacciones: DataFrame) -> DataFrame:
    """
    Genera un DataFrame de snowpark con el tiempo promedio entre compras de un usuario

    Columnas:

    (Total)

    EMAIL: Email del usuario

    DIAS_ENTRE_COMPRAS: Cantidad de dias que tarda el usuario en promedio para comprar
    nuevamente

    Parametros:

    transacciones: DataFrame con las transacciones para las que se busca el tiempo
    promedio entre compras (Columnas Requeridas: [EMAIL, FECHA])
    """

    if 'EMAIL' not in transacciones.columns:
        raise KeyError('El DataFrame de transacciones debe contener una columna "EMAIL"')
    elif 'FECHA' not in transacciones.columns:
        raise KeyError('El DataFrame de transacciones debe contener una columna "FECHA"')

    transacciones_ordenadas_1 = (
        transacciones
        .with_column('ROW_NUM', row_number().over(Window.partition_by('EMAIL').order_by('FECHA')))
    )

    transacciones_ordenadas_2 = (
        transacciones_ordenadas_1
        .with_column('ROW_NUM', col('ROW_NUM') + 1) 
        .with_column_renamed('FECHA', 'FECHA_2')
    )

    tiempo_entre_compras = (
        transacciones_ordenadas_1
        .join(transacciones_ordenadas_2, on = ['EMAIL', 'ROW_NUM'])
        .with_column('DIAS_ENTRE_COMPRAS', col('FECHA') - col('FECHA_2'))
        .group_by('EMAIL')
        .agg(avg('DIAS_ENTRE_COMPRAS').alias('DIAS_ENTRE_COMPRAS'))
    )
 
    return tiempo_entre_compras