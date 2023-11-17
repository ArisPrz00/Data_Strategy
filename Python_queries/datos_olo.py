from DP_transacciones_total import get_transacciones_dp_total
from general_indicadores import indicadores
from general_get_tiempo import get_tiempo
import snowflake.snowpark.functions as fn

def main():
    from configparser import ConfigParser

    from snowflake.snowpark import Session

    config = ConfigParser()
    config.read('config.ini')

    connection_parameters: dict[str, int | str] = {
        'user' : config.get('SNOWFLAKE', 'USER'),
        'password' : config.get('SNOWFLAKE', 'PASSWORD'),
        'account' : config.get('SNOWFLAKE', 'ACCOUNT'),
        'database' : config.get('SNOWFLAKE', 'DATABASE'),
        'warehouse' : config.get('SNOWFLAKE', 'WAREHOUSE'),
        'schema' : config.get('SNOWFLAKE', 'SCHEMA'),
        'role' : config.get('SNOWFLAKE', 'ROLE'),
    }

    session = Session.builder.configs(connection_parameters).create()

    tiempo = get_tiempo(session)

    transacciones_dp_total = get_transacciones_dp_total(session)

    transacciones_2023_H2 = (
        transacciones_dp_total
        .join(tiempo, on = 'FECHA')
        .filter(fn.col('ANIO_ALSEA') == 2023)
        .filter(fn.col('SEMESTRE') == 2)
    )

    datos_semanales = (
        transacciones_dp_total
        .join(tiempo, on = 'FECHA')
        .filter(fn.col('ANIO_ALSEA').isin([2022, 2023]))
        .group_by('ANIO_ALSEA', 'SEM_ALSEA')
        .agg(
            fn.sum('VENTA').alias('VENTA'),
            fn.count_distinct('ORDER_ID').alias('ORDENES'),
            fn.count_distinct('EMAIL').alias('CLIENTES')
        )
        .to_pandas()
    )

    datos_semanales.to_excel('datos_semanales.xlsx')

    indicadores_pd = indicadores(transacciones_2023_H2).to_pandas()

    indicadores_pd.to_excel('indicadores.xlsx')

if __name__ == '__main__':
    main()