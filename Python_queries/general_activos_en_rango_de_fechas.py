from snowflake.snowpark import DataFrame
from snowflake.snowpark.functions import col
from datetime import date

def get_activos_en_rango_de_fechas(transacciones_total:DataFrame, fecha_inicio: date, fecha_fin: date) -> DataFrame:
    if ('EMAIL' not in transacciones_total.columns) and ('FECHA' not in transacciones_total.columns):
        raise KeyError('El DataFrame de transacciones debe contener las columnas "EMAIL" y "FECHA"')
    elif 'EMAIL' not in transacciones_total.columns:
        raise KeyError('El DataFrame de transacciones debe contener una columna "EMAIL"')
    elif 'FECHA' not in transacciones_total.columns:
        raise KeyError('El DataFrame de transacciones debe contener una columna "FECHA"')

    activos_en_rango_de_fechas = (
        transacciones_total
        .filter(col('FECHA') <= fecha_fin)
        .filter(fecha_inicio <= col('FECHA'))
        .select('EMAIL').distinct()
    )
    
    return activos_en_rango_de_fechas