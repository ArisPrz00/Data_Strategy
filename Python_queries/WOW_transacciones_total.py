from snowflake.snowpark import Session, DataFrame
from snowflake.snowpark.functions import col, to_date

def get_transacciones_wow_total(session:Session) -> DataFrame:
    transacciones_total = (
        session
        .table('WOW_REWARDS.WORK_SPACE_WOW_REWARDS.DS_VENTAS_ORDENES_WOW')
        .filter(~col('POS_EMPLOYEE_ID').isin(['Power','1 service cloud']))
        .with_column('FECHA', to_date(col('DATETIME')))
    )

    return transacciones_total