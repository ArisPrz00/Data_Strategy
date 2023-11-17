from snowflake.snowpark.functions import col, max, to_date
from snowflake.snowpark import Session, DataFrame
from typing import Literal, Callable
from functools import reduce

interval = Literal['ANIO_ALSEA', 'MES_ALSEA', 'SEM_ALSEA', 'FECHA']

def make_offseted_column(session: Session, time_interval:list[interval], name: str, offset: int) -> DataFrame:
    return(
        session
        .table('WOW_REWARDS.WORK_SPACE_WOW_REWARDS.DS_DIM_TIME')
        .group_by(time_interval)
        .agg(max(to_date(col('FECHA')) + offset).alias(name))
    )

def join_column(time_interval:list[interval]) -> Callable[[DataFrame, DataFrame], DataFrame]:
    def fn(x:DataFrame, y:DataFrame) -> DataFrame:
        return x.join(y, on=time_interval)

    return fn

def get_rangos(session:Session, time_interval: list[interval], columns:dict[str, int] = {'FECHA_FIN': 0}) -> DataFrame:
    column_list = [make_offseted_column(session, time_interval, name, columns[name]) for name in columns]

    return reduce(join_column(time_interval), column_list)