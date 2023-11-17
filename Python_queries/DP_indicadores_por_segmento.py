from DP_segmentacion_activos import get_segmentacion_activos_DP
import snowflake.snowpark.functions as fn
from snowflake.snowpark import DataFrame

def indicadores_por_segmento(transacciones: DataFrame) -> DataFrame:
    return (
        get_segmentacion_activos_DP(transacciones)
        .group_by('SEGMENTO')
        .agg(
            fn.sum('VENTAS').alias('VENTA'),
            fn.sum('FREQ').alias('ORDENES'),
            fn.count_distinct('EMAIL').alias('CLIENTES')
        )
        .with_column('TICKET_PROMEDIO', fn.col('VENTA') / fn.col('ORDENES'))
        .with_column('FRECUENCIA', fn.col('ORDENES') / fn.col('CLIENTES'))
        .with_column('CLV', fn.col('VENTA') / fn.col('CLIENTES'))
    )