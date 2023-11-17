from snowflake.snowpark import DataFrame, Session
from snowflake.snowpark.functions import to_date, col, lit

def get_app_installs_DP(session: Session) -> DataFrame:
    """
    Genera un DataFrame de snowpark con los registros a Dominos

    Columnas:

    (Total)
    
    FECHA: Fecha de la instalacion

    FUENTE: Fuente de la instalacion
    """
    golo_android = (
        session
        .table('SEGMENT_EVENTS.GOLO_ANDROID_PROD.APPLICATION_INSTALLED')
        .select(to_date(col('TIMESTAMP')).alias('FECHA'))
        .with_column('FUENTE', lit('GOLO_ANDROID'))
    )

    golo_ios = (
        session
        .table('SEGMENT_EVENTS.GOLO_IOS_PROD.APPLICATION_INSTALLED')
        .select(to_date(col('TIMESTAMP')).alias('FECHA'))
        .with_column('FUENTE', lit('GOLO_IOS'))
    )

    molo_android = (
        session
        .table('SEGMENT_EVENTS.DOMINOS_ANDROID_APP_PRODUCCION.APPLICATION_INSTALLED')
        .select(to_date(col('TIMESTAMP')).alias('FECHA'))
        .with_column('FUENTE', lit('MOLO_ANDROID'))
    )

    molo_ios = (
        session
        .table('SEGMENT_EVENTS.DOMINOS_APP_PRODUCCION.APPLICATION_INSTALLED')
        .select(to_date(col('TIMESTAMP')).alias('FECHA'))
        .with_column('FUENTE', lit('MOLO_IOS'))
    )

    total = (
        golo_android
        .union_all(golo_ios)
        .union_all(molo_android)
        .union_all(molo_ios)
    )

    return total