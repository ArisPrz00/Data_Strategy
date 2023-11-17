from snowflake.snowpark import Session, DataFrame
from snowflake.snowpark.functions import to_date, col, lit, max, count_distinct
from datetime import date

def get_cupones_generados_semanales(session: Session) -> DataFrame:
    """
    Genera un DataFrame de snowpark con los cupones [MISSU, HELLO] que se generan
    cada semana

    Columnas:

    (Ocupadas)

    FECHA: Fecha en la que se genero el cupon

    COUPON: Tipo del cupon [MISSU, HELLO] que se genero

    ANIO_ALSEA: Año alsea en el que se genero el cupon

    MES_ALSEA: Mes alsea en el que se genero el cupon

    SEM_ALSEA: Semana alsea en el que se genero el cupon
    
    Fecha: Fecha en la que se genero el cupon

    (Total)

    FECHA, CUPON, COUPON, MES, ANIO, SEM_ALSEA, SEM_ALSEAW, QUINCENA, MES_ALSEA,
    MES_ALSEA_DESC, ANIO_ALSEA
    """
    missu = (
        session
        .table('SEGMENT_EVENTS.DOMINOS_UNIFIED.INACTIVOS90')
        .group_by('CUPON')
        .agg(to_date(max(col('TIMESTAMP'))).alias('FECHA'))
        .filter(col('FECHA') > date.fromisoformat('2023-08-27'))
        .with_column('COUPON', lit('MISSU'))
    )

    hello = (
        session
        .table('SEGMENT_EVENTS.DOMINOS_UNIFIED.IDENTIFIES')
        .group_by('JOURNEYS_CUPON')
        .agg(to_date(max(col('TIMESTAMP'))).alias('FECHA'))
        .with_column('COUPON', lit('HELLO'))
    )

    tiempo = session.table('WOW_REWARDS.WORK_SPACE_WOW_REWARDS.DS_DIM_TIME') 

    datos = (
        missu
        .union_all(hello)
        .join(tiempo, on = 'FECHA')
    )
    
    return datos