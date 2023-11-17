from snowflake.snowpark.functions import count_distinct
from snowflake.snowpark import DataFrame

def get_volumen_transacciones_dp_por_dia_y_fuente(transacciones: DataFrame) -> DataFrame:
    """
    Genera un DataFrame de snowpark con el volumen de transacciones que hubo en
    cada dia divididas por fuente.

    Columnas:

    (Total)

    FECHA: Fecha de la medicion

    FUENTE: Fuente de la transaccion

    TRANSACCIONES: Volumen de transacciones

    Parametros:

    transacciones: DataFrame con las transacciones para las que se busca el volumen
    (Columnas Requeridas: [FECHA, FUENTE, ORDER_ID])
    """

    if 'FECHA' not in transacciones.columns:
        raise KeyError('El DataFrame de transacciones debe contener una columna "FECHA"')
    elif 'FUENTE' not in transacciones.columns:
        raise KeyError('El DataFrame de transacciones debe contener una columna "FUENTE"')
    elif 'ORDER_ID' not in transacciones.columns:
        raise KeyError('El DataFrame de transacciones debe contener una columna "ORDER_ID"')

    transacciones_dp_total = (
        transacciones
        .group_by(['FECHA', 'FUENTE'])
        .agg(count_distinct('ORDER_ID').alias('TRANSACCIONES'))
        .order_by('FECHA', ascending = False)
    )

    return transacciones_dp_total