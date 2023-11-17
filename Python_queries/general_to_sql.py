from snowflake.snowpark import DataFrame
from DP_transacciones_total import get_transacciones_dp_total
from general_generar_reporte import generate_report
from general_get_tiempo import get_tiempo

def to_sql(df: DataFrame, file_name: str):
    queries = df.queries['queries']

    with open(file_name, 'w') as file:
        for query in queries:
            file.write(query)
            file.write(';')

    return 