from snowflake.snowpark.functions import col, lower, upper, to_char, concat, lit
import snowflake.snowpark.functions as fn
from snowflake.snowpark import Session, DataFrame
from DP_correos_call_centre import get_correos_call_centre

def get_transacciones_olo(session: Session) -> DataFrame:
    """
    Genera un DataFrame de snowpark con las transacciones totales de olo, excluyendo
    aquellas que sean de call centre.
    
    Columnas:

    (Ocupadas)

    EMAIL: Email del usuario

    FECHA: Fecha de la transaccion

    VENTA: Monto de la venta sin IVA
    
    ORDER_ID: Identificador unico de la transaccion

    PHONE: Telefono del cliente

    STORE_ID: Identificador de la tienda

    TIENE_CUPON: Indica si la transaccion fue con cupon o sin cupon

    (Total)

    ORDER_NUMBER, STORE_ID, FECHA, IDMXPOWERSALESLOG, ORDERTIME, ORDERID, ORDERTOTALAMOUNT,
    ORDERPRODUCTSNUMBER, ORDERCOUPONSNUMBER, ORDERSTATUS, ORDERSTATUSTEXT, FIRSTNAME,
    LASTNAME, PHONE, PHONEEXT, RECEIVEPROMOS, USERAGENT, USERAGENTPLATFORM, SOURCEIPV4,
    SOURCEPLATFORM, LATITUDE, LONGITUDE, l_3ieq_CREATIONDATE, l_3ieq_UPDATEDATE,
    SERVICEMETHOD, PAYMENTTYPE, ISFUTUREORDER, ISFIXEDPLACE, EMAIL, OLD_ORDER_NUMBER,
    BEING_MODIFIED, MODIFYING, CUSTOMER_CODE, CUSTOMER_ROOM, CUSTOMER_NAME, COMMENTS,
    ACTUAL_ORDER_DATE, ORDER_STATUS_CODE, ORDER_TYPE_CODE, ORDER_SAVED, ORDER_TIME,
    SALES_TAX1, SALES_TAX2, COUPON_TOTAL, SUBTOTAL, ROUTE_TIME, DRIVER_ID, DRIVER_SHIFT,
    RETURN_TIME, DELIVERY_TIME, DELIVERY_FEE, TAXABLE_SALES1, TAXABLE_SALES2, NON_TAXABLE_SALES,
    COMPUTER_NAME, ADDED_BY, ADDED, CANCEL_REASON, ADDED_BY_LOCATION_CODE, BOTTLEDEPTOTAL,
    DISCOUNT_AMOUNT, VOID_CANC_AUTH_CODE, ORDERREVNBR, ORDERTAKECOMPLETETIME, ORDERLOADTIMESECS,
    ORDERRACKTIMESECS, ORDERDISPATCHTIMESECS, ORDERDELIVERYTIMESECS, ORDERLISTPRICE,
    ORDERMENUDISCOUNTAMT, ORDERLINEDISCOUNTAMT, ORDERDISCOUNTAMT, ORDERFINALPRICE,
    ORDERROYALTYSALES, ORDERIDEALFOODCOST, ORDEREDITCOUNT, EDITEMPLOYEECODE, ORDEREDITDATE,
    ORDERREPRINTCOUNT, REPRINTEMPLOYEECODE, ORDERREPRINTDATE, ORDERRUNSTOPSEQ, ORDERRUNSTOPCOUNT,
    UPDATEEMPLOYEECODE, ORDERUPDATEDATE, ORDERISTAXEXEMPT, ORDERTAXEXEMPTCODE, ORDERISTAXEXEMPT2,
    ORDERTAXEXEMPTCODE2, ORDERISPERSONALCAR, ORDERHASLABELPRINTED, ORDERHASRECEIPTPRINTED,
    ORDERPAYMENTDUEAMT, ORDERPHONENUMBER, ORDERPHONEEXT, ORDERCOMPANYNAME, ORDERSTREETNUMBER,
    ORDERSTREETNAME, ORDERADDRESSLINE2, ORDERADDRESSLINE3, ORDERADDRESSLINE4, ORDERPOSTALCODE,
    ORDERCITYNAME, ORDERREGIONNAME, ORDERADDRESSTYPE, ORDERCOMPLETEDTIME, r_itvt_CREATIONDATE,
    r_itvt_UPDATEDATE, SOURCE_CODE, VENTA, ORDER_ID, ID_CLIENTE, TIENE_CUPON
    """

    mx_power_sales_log = (
        session
        .table('SEGMENT_EVENTS.DOMINOS_OLO.MXPOWERSALESLOG')
        .with_column_renamed(col('ORDERNUMBER'), 'ORDER_NUMBER')
        .with_column_renamed(col('STORENUMBER'), 'LOCATION_CODE')
        .with_column_renamed(col('ORDERDATE'), 'FECHA')
        .with_column('EMAIL', lower(col('EMAIL')))
    )

    dpm_sales_full = (
        session
        .table('SEGMENT_EVENTS.DOMINOS_OLO.DPMSALES_FULL')
        .with_column_renamed(col('ORDER_DATE'), 'FECHA')
        .with_column('SOURCE_CODE', upper(col('SOURCE_CODE')))
        .filter(col('ORDER_STATUS_CODE') == 4)
        .filter(~col('LOCATION_CODE').isin(['13001', '13006', '13021', '11000']))
        .filter(col('SOURCE_CODE').isin(['ANDROID' , 'DESKTOP', 'IOS', 'MOBILE', 'WEB', 'ANDROID2', 'DESKTOP2', 'IOSAPP', 'MOBILE2', 'WHATSAPP']))
    )

    transacciones_olo = (
        mx_power_sales_log
        .join(dpm_sales_full, on = ['ORDER_NUMBER', 'LOCATION_CODE','FECHA'])
        .with_column('VENTA', col('ORDERFINALPRICE') / 1.16)
        .with_column('ORDER_ID', concat(to_char(col('FECHA')), lit('-'), col('LOCATION_CODE'), lit('-'), col('ORDER_NUMBER')))
        .with_column('ID_CLIENTE', concat(col('LOCATION_CODE'), col('CUSTOMER_CODE')))
        .with_column_renamed('PHONENUMBER', 'PHONE')
        .with_column_renamed('LOCATION_CODE', 'STORE_ID')
        .with_column('TIENE_CUPON', col('ORDERLINEDISCOUNTAMT') > 0)
        .with_column(
            'CANAL',
            fn.when(fn.col('SOURCE_CODE').isin('ANDROID', 'ANDROID2'), 'ANDROID')
            .when(fn.col('SOURCE_CODE').isin('IOS', 'IOSAPP'), 'IOS')
            .when(fn.col('SOURCE_CODE').isin('DESKTOP', 'MOBILE', 'WEB', 'DESKTOP2', 'MOBILE2'), 'WEB')
            .otherwise(fn.col('SOURCE_CODE'))
        )
    )

    correos_call_centre = get_correos_call_centre(session)

    transacciones_olo_sin_call_centre = transacciones_olo.join(correos_call_centre, on = 'EMAIL', how = 'leftanti')

    return transacciones_olo_sin_call_centre