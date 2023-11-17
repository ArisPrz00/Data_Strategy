from snowflake.snowpark.functions import col, sum, count_distinct
from snowflake.snowpark import DataFrame
from datetime import date

def clv_en_rango_de_tiempo(transacciones:DataFrame, inicio: date, final: date) -> DataFrame:
    if 'VENTA' not in transacciones.columns:
        raise KeyError('El DataFrame de transacciones debe contener una columna "VENTA"')
    elif 'EMAIL' not in transacciones.columns:
        raise KeyError('El DataFrame de transacciones debe contener una columna "EMAIL"')
    elif 'FECHA' not in transacciones.columns:
        raise KeyError('El DataFrame de transacciones debe contener una columna "FECHA"')

    clv_en_rango_de_tiempo = (
        transacciones
        .filter(inicio <= col('FECHA'))
        .filter(col('FECHA') <= final)
        .agg(sum('VENTA').alias('VENTA'), count_distinct('EMAIL').alias('USUARIOS'), count_distinct('ORDER_ID').alias('ORDENES'))
        .with_column('CLV', col('VENTA') / col('USUARIOS'))
        .with_column('FRECUENCIA', col('ORDENES') / col('USUARIOS'))
    )

    return clv_en_rango_de_tiempo