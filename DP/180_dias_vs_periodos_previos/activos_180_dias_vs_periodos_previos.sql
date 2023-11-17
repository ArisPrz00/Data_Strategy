WITH

PERIODO_ACTUAL AS (
    SELECT
        to_date(max(FECHA)) AS FECHA_FIN,
        FECHA_FIN - 180 AS FECHA_INICIO
    FROM
        WOW_REWARDS.WORK_SPACE_WOW_REWARDS.DS_DIM_TIME
    WHERE
        ANIO_ALSEA = 2023
    AND
        SEM_ALSEA = 35
),

SEMANA_PREVIA AS (
    SELECT
        to_date(max(FECHA)) AS FECHA_FIN,
        FECHA_FIN - 180 AS FECHA_INICIO
    FROM
        WOW_REWARDS.WORK_SPACE_WOW_REWARDS.DS_DIM_TIME
    WHERE
        ANIO_ALSEA = 2023
    AND
        SEM_ALSEA = 34
),

MES_PREVIO AS (
    SELECT
        to_date(max(FECHA)) AS FECHA_FIN,
        FECHA_FIN - 180 AS FECHA_INICIO
    FROM
        WOW_REWARDS.WORK_SPACE_WOW_REWARDS.DS_DIM_TIME
    WHERE
        ANIO_ALSEA = 2023
    AND
        MES_ALSEA = 8
),

ANIO_PREVIO AS (
    SELECT
        to_date(max(FECHA)) AS FECHA_FIN,
        FECHA_FIN - 180 AS FECHA_INICIO
    FROM
        WOW_REWARDS.WORK_SPACE_WOW_REWARDS.DS_DIM_TIME
    WHERE
        ANIO_ALSEA = 2022
),

TRANSACCIONES_OLO AS (
    SELECT DISTINCT
        lower(MXP.EMAIL) AS EMAIL,
        ORDER_DATE AS FECHA,
        TO_CHAR(ORDER_DATE,'YYYY-MM-DD')||LOCATION_CODE||OLO.ORDER_NUMBER AS ORDER_ID,
        OLO.ORDERFINALPRICE / 1.16 AS ORDER_AMOUNT
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
        to_char(FECHA) || A.STOREID ||A.StoreOrderID AS ORDER_ID,
        PAYMENTSAMOUNT / 1.16 AS ORDER_AMOUNT
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
    AND 
        A.SOURCEORGANIZATIONURI IS NOT NULL
),

TRANSACCIONES_OLO_Y_CLOUD AS (
    SELECT * FROM TRANSACCIONES_OLO
    UNION ALL
    SELECT * FROM TRANSACCIONES_CLOUD
),

ACTIVOS_PERIODO_ACTUAL AS (
    SELECT
        count(DISTINCT EMAIL) AS CLIENTES
    FROM
        TRANSACCIONES_OLO_Y_CLOUD
    INNER JOIN
        PERIODO_ACTUAL
    ON
        FECHA BETWEEN FECHA_INICIO AND FECHA_FIN
),

ACTIVOS_SEMANA_PREVIA AS (
    SELECT
        count(DISTINCT EMAIL) AS CLIENTES
    FROM
        TRANSACCIONES_OLO_Y_CLOUD
    INNER JOIN
        SEMANA_PREVIA
    ON
        FECHA BETWEEN FECHA_INICIO AND FECHA_FIN
),

ACTIVOS_MES_PREVIO AS (
    SELECT
        count(DISTINCT EMAIL) AS CLIENTES
    FROM
        TRANSACCIONES_OLO_Y_CLOUD
    INNER JOIN
        MES_PREVIO
    ON
        FECHA BETWEEN FECHA_INICIO AND FECHA_FIN
),

ACTIVOS_ANIO_PREVIO AS (
    SELECT
        count(DISTINCT EMAIL) AS CLIENTES
    FROM
        TRANSACCIONES_OLO_Y_CLOUD
    INNER JOIN
        ANIO_PREVIO
    ON
        FECHA BETWEEN FECHA_INICIO AND FECHA_FIN
)

SELECT
    ACTIVOS_PERIODO_ACTUAL.CLIENTES AS CLIENTES_ACTIVOS_PERIODO_ACTUAL,
    ACTIVOS_SEMANA_PREVIA.CLIENTES AS CLIENTES_ACTIVOS_SEMANA_PREVIA,
    CLIENTES_ACTIVOS_PERIODO_ACTUAL / CLIENTES_ACTIVOS_SEMANA_PREVIA AS PERCENT_V_SEMANA_PREVIA,
    ACTIVOS_MES_PREVIO.CLIENTES AS CLIENTES_ACTIVOS_MES_PREVIO,
    CLIENTES_ACTIVOS_PERIODO_ACTUAL / CLIENTES_ACTIVOS_MES_PREVIO AS PERCENT_V_MES_PREVIO,
    ACTIVOS_ANIO_PREVIO.CLIENTES AS CLIENTES_ACTIVOS_ANIO_PREVIO,
    CLIENTES_ACTIVOS_PERIODO_ACTUAL / CLIENTES_ACTIVOS_ANIO_PREVIO AS PERCENT_V_ANIO_PREVIO
FROM
    ACTIVOS_PERIODO_ACTUAL
JOIN
    ACTIVOS_SEMANA_PREVIA
JOIN  
    ACTIVOS_MES_PREVIO
JOIN
    ACTIVOS_ANIO_PREVIO
;