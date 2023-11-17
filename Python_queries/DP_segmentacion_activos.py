from snowflake.snowpark import DataFrame
import snowflake.snowpark.functions as fn

def get_segmentacion_activos_DP(transacciones:DataFrame):
    datos_por_usuario = (
        transacciones
        .group_by('EMAIL')
        .agg(
            fn.count_distinct('ORDER_ID').alias('FREQ'),
            fn.sum('VENTA').alias('VENTAS')
        )
        .with_column('AOV', fn.col('VENTAS') / fn.col('FREQ'))
    )

    percentiles_aov = (
        datos_por_usuario
        .agg(
            fn.round(fn.percentile_cont(0.25).within_group('AOV')).alias('p25th_AOV'),
            fn.round(fn.percentile_cont(0.75).within_group('AOV')).alias('p75th_AOV')
        )
    )

    segmentacion = (
        datos_por_usuario
        .join(percentiles_aov)
        .with_column(
            'SEGMENTO_FREQUENCY',
            fn.when(fn.col('FREQ') <= 1, 'NUEVOS')
            .when(fn.col('FREQ') < 4, 'LIGHT')
            .when(fn.col('FREQ') < 6, 'MID')
            .otherwise('HEAVY')
        )
        .with_column(
            'SEGMENTO_AOV',
            fn.when(fn.col('AOV') <= fn.col('p25th_AOV'), 'LOW')
            .when(fn.col('AOV') <= fn.col('p75th_AOV'), 'AVG')
            .otherwise('HIGH')
        )
        .with_column('FULL_SEGMENTO', fn.concat('SEGMENTO_FREQUENCY', fn.lit('_'), 'SEGMENTO_AOV'))
        .with_column(
            'SEGMENTO',
            fn.when(fn.col('FULL_SEGMENTO').isin('NUEVOS_LOW', 'NUEVOS_AVG', 'LIGHT_LOW'), 'LOW_VALUE')
            .when(fn.col('FULL_SEGMENTO').isin('LIGHT_AVG', 'NUEVOS_HIGH', 'LIGHT_HIGH'), 'MEDIUM_LOW_VALUE')
            .when(fn.col('FULL_SEGMENTO').isin('MID_LOW', 'MID_AVG', 'HEAVY_LOW'), 'MEDIUM_HIGH_VALUE')
            .when(fn.col('FULL_SEGMENTO').isin('HEAVY_AVG', 'MID_HIGH', ), 'HIGH_VALUE')
            .when(fn.col('FULL_SEGMENTO').isin('HEAVY_HIGH', ), 'TOP_VALUE')
        )
    )

    return segmentacion