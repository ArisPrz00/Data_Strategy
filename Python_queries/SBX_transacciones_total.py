from snowflake.snowpark import Session, DataFrame
from snowflake.snowpark.functions import to_date

def transacciones_sbx_total(session: Session) -> DataFrame:
    return (
        session.table('SEGMENT_EVENTS.SESSIONM_SBX.FACT_TRANSACTIONS')
        .with_column('FECHA', to_date('CREATED_AT'))
    )