from snowflake.snowpark import Session, DataFrame

def get_datos_tiendas_dp(session: Session) -> DataFrame:
    """
    Genera un DataFrame de snowpark con los datos de las tiendas DP

    Columnas:

    (Ocupadas)

    STORE_ID: Identificador unico de la tienda

    REGION: Region en la que se encuentra la tienda

    (Total)

    TIPO_CECO, STORE_ID, TIENDA, REGION, DIRECCION, CODIGO_POSTAL, COLONIA, CIUDAD,
    ESTADO, FORMATO, SUBFORMATO, GERENTE_DISTRITO
    """
    datos_tiendas_dp = (
        session
        .table('ANALYTICS_HUB.DATA_HUB.DS_SUCURSALES_DP')
        .with_column_renamed('CECO', 'STORE_ID')
    )

    return datos_tiendas_dp