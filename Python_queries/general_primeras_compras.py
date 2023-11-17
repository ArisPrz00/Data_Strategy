from snowflake.snowpark import Session, DataFrame
from snowflake.snowpark.functions import min, col

def get_primeras_compras(transacciones_total:DataFrame) -> DataFrame:

    if ('EMAIL' not in transacciones_total.columns) and ('FECHA' not in transacciones_total.columns):
        raise KeyError('El DataFrame de transacciones debe contener las columnas "EMAIL" y "FECHA"')
    elif 'EMAIL' not in transacciones_total.columns:
        raise KeyError('El DataFrame de transacciones debe contener una columna "EMAIL"')
    elif 'FECHA' not in transacciones_total.columns:
        raise KeyError('El DataFrame de transacciones debe contener una columna "FECHA"')

    primeras_compras = (
        transacciones_total
        .group_by(col('EMAIL'))
        .agg(min('FECHA').alias('FECHA'))
    ) 

    return primeras_compras