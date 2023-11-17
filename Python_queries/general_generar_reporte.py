from snowflake.snowpark.functions import col, lit, when
from snowflake.snowpark import DataFrame
from typing import Callable

def generate_report(
    data:DataFrame, aggregating_func:Callable, aggregating_col:str, anio_actual: int,
    semana_actual: int, anio_semana_previa: int, semana_previa: int, mes_actual: int,
    anio_mes_previo: int, mes_previo: int, anio_previo: int, dato: str
) -> DataFrame:

    data_semana_actual = (
        data
        .filter(col('ANIO_ALSEA') == anio_actual)
        .filter(col('SEM_ALSEA') == semana_actual)
        .agg(aggregating_func(aggregating_col).alias('SEMANA_ACTUAL'))
    )

    data_semana_previa = (
        data
        .filter(col('ANIO_ALSEA') == anio_semana_previa)
        .filter(col('SEM_ALSEA') == semana_previa)
        .agg(aggregating_func(aggregating_col).alias('SEMANA_PREVIA'))
    )

    semanal = (
        data_semana_actual
        .join(data_semana_previa)
        .with_column('PERCENT_V_SEMANA_PREVIA', 
            when(col('SEMANA_PREVIA') != 0, (col('SEMANA_ACTUAL') - col('SEMANA_PREVIA')) / col('SEMANA_PREVIA'))
            .otherwise(0)
        )
    )

    data_mes_actual = (
        data
        .filter(col('ANIO_ALSEA') == anio_actual)
        .filter(col('MES_ALSEA') == mes_actual)
        .filter(col('SEM_ALSEA') <= semana_actual)
        .agg(aggregating_func(aggregating_col).alias('MES_ACTUAL'))
    )

    data_mes_previo = (
        data
        .filter(col('ANIO_ALSEA') == anio_mes_previo)
        .filter(col('MES_ALSEA') == mes_previo)
        .agg(aggregating_func(aggregating_col).alias('MES_PREVIO'))
    )

    mensual = (
        data_mes_actual
        .join(data_mes_previo)
        .with_column('PERCENT_V_MES_PREVIO',
            when(col('MES_PREVIO') != 0, (col('MES_ACTUAL') - col('MES_PREVIO')) / col('MES_PREVIO'))
            .otherwise(0)
        )
    )

    data_anio_actual = (
        data
        .filter(col('ANIO_ALSEA') == anio_actual)
        .filter(col('SEM_ALSEA') <= semana_actual)
        .agg(aggregating_func(aggregating_col).alias('ANIO_ACTUAL'))
    )

    data_anio_previo = (
        data
        .filter(col('ANIO_ALSEA') == anio_previo)
        .filter(col('SEM_ALSEA') <= semana_actual)
        .agg(aggregating_func(aggregating_col).alias('ANIO_PREVIO'))
    )

    anual = (
        data_anio_actual
        .join(data_anio_previo)
        .with_column('PERCENT_V_ANIO_PREVIO',
            when(col('ANIO_PREVIO') != 0, (col('ANIO_ACTUAL') - col('ANIO_PREVIO')) / col('ANIO_PREVIO'))
            .otherwise(0)
        )
    )

    report = (
        semanal
        .join(mensual)
        .join(anual)
        .with_column('DATO', lit(dato))
    )

    return report