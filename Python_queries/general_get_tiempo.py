from snowflake.snowpark import DataFrame, Session
from snowflake.snowpark.functions import when, col

def get_tiempo(session:Session) -> DataFrame:
    return (
        session
        .table('WOW_REWARDS.WORK_SPACE_WOW_REWARDS.DS_DIM_TIME')
        .with_column('TRIMESTRE', 
            when(col('MES_ALSEA').isin([1,2,3]), 1)
            .when(col('MES_ALSEA').isin([4,5,6]), 2)
            .when(col('MES_ALSEA').isin([7,8,9]), 3)
            .otherwise(4)
        )
        .with_column('SEMESTRE',
            when(col('MES_ALSEA').isin([1,2,3,4,5,6]), 1)
            .otherwise(2)
        )
    )