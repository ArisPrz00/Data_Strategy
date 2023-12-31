WITH

PERIODO_ACTUAL AS (
    SELECT
        to_date(max(FECHA)) AS FECHA_FIN,
        FECHA_FIN - 180 AS FECHA_INICIO,
        ANIO_ALSEA,
        MES_ALSEA,
        SEM_ALSEA
    FROM
        WOW_REWARDS.WORK_SPACE_WOW_REWARDS.DS_DIM_TIME
    WHERE
        ANIO_ALSEA = 2023
    AND
        SEM_ALSEA = 30
    GROUP BY
        ANIO_ALSEA,
        MES_ALSEA,
        SEM_ALSEA
),

SEMANA_PREVIA AS (
    SELECT
        to_date(max(FECHA)) AS FECHA_FIN,
        FECHA_FIN - 180 AS FECHA_INICIO
    FROM
    (
        SELECT
            CASE WHEN SEM_ALSEA = 1 THEN ANIO_ALSEA - 1 ELSE ANIO_ALSEA END AS ANIO_ALSEA,
            CASE WHEN SEM_ALSEA = 1 THEN 52             ELSE SEM_ALSEA - 1 END AS SEM_ALSEA
        FROM
            PERIODO_ACTUAL
    )
    INNER JOIN
        WOW_REWARDS.WORK_SPACE_WOW_REWARDS.DS_DIM_TIME
    USING(
        ANIO_ALSEA,
        SEM_ALSEA
    )
),

MES_PREVIO AS (
    SELECT
        to_date(max(FECHA)) AS FECHA_FIN,
        FECHA_FIN - 180 AS FECHA_INICIO
    FROM
    (
        SELECT
            CASE WHEN MES_ALSEA = 1 THEN ANIO_ALSEA - 1 ELSE ANIO_ALSEA END AS ANIO_ALSEA,
            CASE WHEN MES_ALSEA = 1 THEN 12             ELSE MES_ALSEA - 1 END AS MES_ALSEA
        FROM
            PERIODO_ACTUAL
    )
    INNER JOIN
        WOW_REWARDS.WORK_SPACE_WOW_REWARDS.DS_DIM_TIME
    USING(
        ANIO_ALSEA,
        MES_ALSEA
    )
),

ANIO_PREVIO AS (
    SELECT
        to_date(max(FECHA)) AS FECHA_FIN,
        FECHA_FIN - 180 AS FECHA_INICIO
    FROM
    (
        SELECT
            ANIO_ALSEA - 1 AS ANIO_ALSEA
        FROM
            PERIODO_ACTUAL
    )
    INNER JOIN
        WOW_REWARDS.WORK_SPACE_WOW_REWARDS.DS_DIM_TIME
    USING(
        ANIO_ALSEA
    )
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

PRIMERAS_COMPRAS_BY_USER AS (
    SELECT
        EMAIL,
        min(FECHA) AS FECHA
    FROM
        TRANSACCIONES_OLO_Y_CLOUD
    GROUP BY
        EMAIL
),

PRIMERAS_COMPRAS_PERIODO_ACTUAL AS (
    SELECT
        count(DISTINCT EMAIL) AS CLIENTES
    FROM
        PRIMERAS_COMPRAS_BY_USER
    INNER JOIN
        PERIODO_ACTUAL
    ON
        FECHA BETWEEN FECHA_INICIO AND FECHA_FIN
),

PRIMERAS_COMPRAS_SEMANA_PREVIA AS (
    SELECT
        count(DISTINCT EMAIL) AS CLIENTES
    FROM
        PRIMERAS_COMPRAS_BY_USER
    INNER JOIN
        SEMANA_PREVIA
    ON
        FECHA BETWEEN FECHA_INICIO AND FECHA_FIN
),

PRIMERAS_COMPRAS_MES_PREVIO AS (
    SELECT
        count(DISTINCT EMAIL) AS CLIENTES
    FROM
        PRIMERAS_COMPRAS_BY_USER
    INNER JOIN
        MES_PREVIO
    ON
        FECHA BETWEEN FECHA_INICIO AND FECHA_FIN
),

PRIMERAS_COMPRAS_ANIO_PREVIO AS (
    SELECT
        count(DISTINCT EMAIL) AS CLIENTES
    FROM
        PRIMERAS_COMPRAS_BY_USER
    INNER JOIN
        ANIO_PREVIO
    ON
        FECHA BETWEEN FECHA_INICIO AND FECHA_FIN
)

SELECT
    PRIMERAS_COMPRAS_PERIODO_ACTUAL.CLIENTES AS CLIENTES_PRIMERAS_COMPRAS_PERIODO_ACTUAL,
    PRIMERAS_COMPRAS_SEMANA_PREVIA.CLIENTES AS CLIENTES_PRIMERAS_COMPRAS_SEMANA_PREVIA,
    CLIENTES_PRIMERAS_COMPRAS_PERIODO_ACTUAL / CLIENTES_PRIMERAS_COMPRAS_SEMANA_PREVIA AS PERCENT_V_SEMANA_PREVIA,
    PRIMERAS_COMPRAS_MES_PREVIO.CLIENTES AS CLIENTES_PRIMERAS_COMPRAS_MES_PREVIO,
    CLIENTES_PRIMERAS_COMPRAS_PERIODO_ACTUAL / CLIENTES_PRIMERAS_COMPRAS_MES_PREVIO AS PERCENT_V_MES_PREVIO,
    PRIMERAS_COMPRAS_ANIO_PREVIO.CLIENTES AS CLIENTES_PRIMERAS_COMPRAS_ANIO_PREVIO,
    CLIENTES_PRIMERAS_COMPRAS_PERIODO_ACTUAL / CLIENTES_PRIMERAS_COMPRAS_ANIO_PREVIO AS PERCENT_V_ANIO_PREVIO
FROM
    PRIMERAS_COMPRAS_PERIODO_ACTUAL
JOIN
    PRIMERAS_COMPRAS_SEMANA_PREVIA
JOIN  
    PRIMERAS_COMPRAS_MES_PREVIO
JOIN
    PRIMERAS_COMPRAS_ANIO_PREVIO
;