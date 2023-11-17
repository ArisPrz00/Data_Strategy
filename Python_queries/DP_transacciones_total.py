from DP_transacciones_cloud import get_transacciones_cloud
from DP_transacciones_olo import get_transacciones_olo
from snowflake.snowpark import Session, DataFrame
from snowflake.snowpark.functions import lit

def get_transacciones_dp_total(session: Session) -> DataFrame:
    """
    Genera un DataFrame de snowpark con las transacciones totales DP
    
    Columnas:

    (Total)

    EMAIL: Email del usuario

    FECHA: Fecha de la transaccion
    
    VENTA: Cantidad de venta sin iva

    ORDER_ID: Identificador de la transaccion

    PHONE: Telefono del usuario

    STORE_ID: Identificador de la tienda

    TIENE_CUPON: Valor booleano que nos dice si la venta fue con algun cupon

    FUENTE: [OLO, CLOUD] Fuente de la que proviene la transaccion

    CANAL: [IOS, ANDROID, WEB, WHATSAPP] Canal en el que se genero la transaccion
    """

    transacciones_olo = (
        get_transacciones_olo(session)
        .with_column('FUENTE', lit('OLO'))
        .select(['EMAIL', 'FECHA', 'VENTA', 'ORDER_ID', 'PHONE', 'STORE_ID', 'TIENE_CUPON', 'FUENTE', 'CANAL'])
    )
    transacciones_cloud = (
        get_transacciones_cloud(session)
        .with_column('FUENTE', lit('CLOUD'))
        .select(['EMAIL', 'FECHA', 'VENTA', 'ORDER_ID', 'PHONE', 'STORE_ID', 'TIENE_CUPON', 'FUENTE', 'CANAL'])
    )

    transacciones_total = (
        transacciones_cloud
        .union_all(transacciones_olo)
    )

    return transacciones_total