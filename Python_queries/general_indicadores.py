from snowflake.snowpark import DataFrame
from snowflake.snowpark.functions import sum, count_distinct, col

def indicadores(transacciones:DataFrame) -> DataFrame:
    if 'EMAIL' not in transacciones.columns:
        raise KeyError('El DataFrame de transacciones debe contener una columna "EMAIL"')
    elif 'VENTA' not in transacciones.columns:
        raise KeyError('El DataFrame de transacciones debe contener una columna "VENTA"')
    elif 'ORDER_ID' not in transacciones.columns:
        raise KeyError('El DataFrame de transacciones debe contener una columna "ORDER_ID"')

    return (
        transacciones
        .agg(
            sum('VENTA').alias('VENTA'),
            count_distinct('ORDER_ID').alias('ORDENES'),
            count_distinct('EMAIL').alias('CLIENTES')
        )
        .with_column('TICKET_PROMEDIO', col('VENTA') / col('ORDENES'))
        .with_column('FRECUENCIA', col('ORDENES') / col('CLIENTES'))
        .with_column('CLV', col('VENTA') / col('CLIENTES'))
    )