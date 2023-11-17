from snowflake.snowpark.functions import col, substring, lower, concat
import snowflake.snowpark.functions as fn
from snowflake.snowpark import Session, DataFrame   
from DP_correos_call_centre import get_correos_call_centre

def get_transacciones_cloud(session: Session) -> DataFrame:
    """
    Genera un DataFrame de snowpark con las transacciones de GOLO DP, excluyendo aquellas que sean de call centre

    Columnas:

    (Ocupadas)

    EMAIL: Email del usuario

    FECHA: Fecha de la transaccion
    
    VENTA: Cantidad de venta sin iva

    ORDER_ID: Identificador de la transaccion

    PHONE: Telefono del usuario

    STORE_ID: Identificador de la tienda

    TIENE_CUPON: Valor booleano que nos dice si la venta fue con algun cupon

    (Total)

    STOREPLACEORDERTIME, PLACEORDERTIME, STORE_ID, STOREORDERID, FUTUREORDERTIME,
    CUSTOMERID, PHONE, FIRSTNAME, LASTNAME, SERVICEMETHOD, SOURCEORGANIZATIONURI,
    COUPONSCODE, PAYMENTSAMOUNT, PAYMENTSTYPE, PAYMENTSCARDTYPE, PAYMENTSTRANSACTIONID,
    PAYMENTSPROVIDERID, FILE_NAME, FECHA, EMAIL, ORDER_ID, VENTA, TIENE_CUPON
    """

    transacciones_cloud = (
        session.table('SEGMENT_EVENTS.DOMINOS_GOLO.VENTA_CLOUD')
        .filter(~col('STOREID').like('9%'))
        .filter(col('SOURCEORGANIZATIONURI').is_not_null())
        .filter(col('SOURCEORGANIZATIONURI').isin(['order.dominos.com', 'resp-order.dominos.com', 'iphone.dominos.mx', 'android.dominos.mx']))
        .with_column('FECHA', substring(col('STOREORDERID'), 1, 10))
        .with_column('EMAIL', lower(col('EMAIL')))
        .with_column('ORDER_ID', concat(col('FECHA'), col('STOREID'), col('STOREORDERID')))
        .with_column('VENTA', col('PAYMENTSAMOUNT') / 1.16)
        .with_column_renamed('STOREID', 'STORE_ID')
        .with_column('TIENE_CUPON', col('COUPONSCODE').is_not_null())
        .with_column(
            'CANAL',
            fn.when(fn.col('SOURCEORGANIZATIONURI') == 'iphone.dominos.mx', 'IOS')
            .when(fn.col('SOURCEORGANIZATIONURI') == 'android.dominos.mx', 'ANDROID')
            .otherwise('WEB')
        )
    )

    correos_call_centre = get_correos_call_centre(session)

    transacciones_cloud_sin_call_centre = (
        transacciones_cloud
        .join(correos_call_centre, on = 'EMAIL', how = 'leftanti')
    )

    return transacciones_cloud_sin_call_centre