-- INSERT INTO WOW_REWARDS.SEGMENTACION_DOMINOS.SEGMENTACION_JULIO
WITH

RANGO_DE_FECHAS AS (
    SELECT
        to_date('2023-07-30') AS FECHA_FIN,
        FECHA_FIN - 180 AS FECHA_INICIO_ACTIVOS,
        FECHA_FIN - 365 AS FECHA_INICIO_INACTIVOS
),

TRANSACCIONES_OLO AS (
    SELECT DISTINCT
        lower(MXP.EMAIL) AS EMAIL,
        ORDER_DATE AS FECHA,
        TO_CHAR(ORDER_DATE,'YYYY-MM-DD') || '-' || LOCATION_CODE || '-' || OLO.ORDER_NUMBER AS ORDER_ID,
        OLO.ORDERFINALPRICE / 1.16 AS ORDER_AMOUNT,
        PHONENUMBER AS PHONE,
        FIRSTNAME,
        SERVICEMETHOD,
        ORDERPRODUCTSNUMBER
    FROM
       "SEGMENT_EVENTS"."DOMINOS_OLO"."MXPOWERSALESLOG" MXP
    INNER JOIN 
        "SEGMENT_EVENTS"."DOMINOS_OLO"."DPMSALES_FULL" OLO
    ON 
        OLO.ORDER_NUMBER = MXP.ORDERNUMBER AND OLO.LOCATION_CODE = MXP.STORENUMBER 
    AND 
        TO_CHAR(OLO.ORDER_DATE,'YYYY-MM-DD') = MXP.ORDERDATE
    WHERE 
        OLO.ORDER_STATUS_CODE = 4
    AND 
        OLO.LOCATION_CODE NOT IN ('13001' , '13006', '13021', '11000')
    AND 
        UPPER(OLO.SOURCE_CODE) IN (
            'ANDROID', 
            'DESKTOP', 
            'IOS', 
            'MOBILE', 
            'WEB', 
            'ANDROID2', 
            'DESKTOP2', 
            'IOSAPP', 
            'MOBILE2', 
            'WHATSAPP'
        )
),

TRANSACCIONES_CLOUD AS (
    SELECT DISTINCT 
        lower(A.EMAIL) AS EMAIL,
        to_date(SUBSTRING(A.STOREORDERID,1,10)) AS FECHA,
        split_part(A.STOREORDERID, '#', 1) || '-' || A.STOREID || '-' || split_part(A.STOREORDERID, '#', 2) AS ORDER_ID,
        PAYMENTSAMOUNT / 1.16 AS ORDER_AMOUNT,
        PHONE,
        FIRSTNAME,
        SERVICEMETHOD,
        0 AS ORDERPRODUCTSNUMBER
    FROM 
        "SEGMENT_EVENTS"."DOMINOS_GOLO"."VENTA_CLOUD" A
    WHERE 
        A.STOREID NOT LIKE '9%'
    AND 
        A.SOURCEORGANIZATIONURI IN (
            'order.dominos.com', 
            'resp-order.dominos.com', 
            'iphone.dominos.mx', 
            'android.dominos.mx'
        )
),

TRANSACCIONES_OLO_Y_CLOUD AS (
    SELECT * FROM TRANSACCIONES_OLO
    UNION ALL
    SELECT * FROM TRANSACCIONES_CLOUD
),

TRANSACCIONES_ACTIVOS AS (
    SELECT
        TRANSACCIONES_OLO_Y_CLOUD.*
    FROM
        TRANSACCIONES_OLO_Y_CLOUD
    INNER JOIN 
        RANGO_DE_FECHAS
    ON
        FECHA <= FECHA_FIN
    AND
        FECHA_INICIO_ACTIVOS <= FECHA
),

DETALLE_TRANSACCIONES_OLO_JULIO_DELIVERY AS (
    SELECT
        EMAIL,
        sum(ORDERPRODUCTSNUMBER) AS PRODUCTOS_TOTALES,
        avg(ORDERPRODUCTSNUMBER) AS PRODUCTOS_PROMEDIO,
        count(DISTINCT ORDER_ID) AS TRANSACCIONES,
        sum(ORDER_AMOUNT) AS VENTAS
    FROM
        TRANSACCIONES_OLO
    INNER JOIN 
        WOW_REWARDS.WORK_SPACE_WOW_REWARDS.DS_DIM_TIME
    USING(
        FECHA
    )
    WHERE
        SERVICEMETHOD = 'Pickup'
    AND 
        ANIO_ALSEA = 2023
    AND
        MES_ALSEA = 7
    GROUP BY
        EMAIL
),

TRANSACCIONES_ACTIVOS_BY_USER AS (
    SELECT
        EMAIL,
        count(DISTINCT ORDER_ID) AS FREQ,
        sum(ORDER_AMOUNT) AS VENTAS,
        VENTAS / FREQ AS AOV
    FROM 
        TRANSACCIONES_ACTIVOS
    GROUP BY
        EMAIL
),

PERCENTILES_AOV AS (
    SELECT
        round(percentile_cont(0.25) WITHIN GROUP (ORDER BY TRANSACCIONES_ACTIVOS_BY_USER.AOV)) p25th_AOV,
        round(percentile_cont(0.75) WITHIN GROUP (ORDER BY TRANSACCIONES_ACTIVOS_BY_USER.AOV)) p75th_AOV
    FROM
        TRANSACCIONES_ACTIVOS_BY_USER
),

SEGMENTACION_BASE_ACTIVOS AS (
    SELECT 
        EMAIL,
        CASE
            WHEN FREQ <= 1 THEN 'NUEVOS'
            WHEN FREQ <  4 THEN 'LIGHT'
            WHEN FREQ <  6 THEN 'MID'
            ELSE                'HEAVY'
        END AS SEGMENTO_FREQUENCY,
        CASE
            WHEN AOV <= p25th_AOV THEN 'LOW'
            WHEN AOV <= p75th_AOV THEN 'AVG'
            ELSE                       'HIGH'
        END AS SEGMENTO_AOV,
        (SEGMENTO_FREQUENCY || '_' || SEGMENTO_AOV) AS FULL_SEGMENTO,
        CASE 
            WHEN FULL_SEGMENTO IN ('NUEVOS_LOW','NUEVOS_AVG','LIGHT_LOW') THEN 'LOW_VALUE'
            WHEN FULL_SEGMENTO IN ('LIGHT_AVG','NUEVOS_HIGH','LIGHT_HIGH') THEN 'MEDIUM_LOW_VALUE'
            WHEN FULL_SEGMENTO IN ('MID_LOW','MID_AVG','HEAVY_LOW') THEN 'MEDIUM_HIGH_VALUE'
            WHEN FULL_SEGMENTO IN ('HEAVY_AVG','MID_HIGH') THEN 'HIGH_VALUE'
            WHEN FULL_SEGMENTO IN ('HEAVY_HIGH') THEN 'TOP_VALUE'
        END  AS SEGMENTO
    FROM
        TRANSACCIONES_ACTIVOS_BY_USER
    INNER JOIN
        PERCENTILES_AOV
)

SELECT
    SEGMENTO,
    sum(PRODUCTOS_TOTALES) / sum(TRANSACCIONES) AS PRODUCTOS_POR_TRANSACCION,
    sum(VENTAS) / sum(TRANSACCIONES) AS TICKET_PROMEDIO
FROM
    SEGMENTACION_BASE_ACTIVOS
INNER JOIN  
    DETALLE_TRANSACCIONES_OLO_JULIO_DELIVERY
USING(
    EMAIL
)
GROUP BY
    SEGMENTO
-- WHERE
--     SEGMENTO IN ('LOW_VALUE', 'MEDIUM_LOW_VALUE')