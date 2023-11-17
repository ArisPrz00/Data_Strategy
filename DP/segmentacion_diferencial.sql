-- INSERT INTO WOW_REWARDS.SEGMENTACION_DOMINOS.SEGMENTACION_JULIO
WITH

RANGO_DE_FECHAS AS (
    SELECT
        to_date('2023-08-13') AS FECHA_FIN,
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
        FIRSTNAME
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
        FIRSTNAME
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

REGISTROS_CLOUD AS (
    SELECT lower(EMAIL) AS EMAIL, to_date(RECEIVED_AT) AS FECHA FROM SEGMENT_EVENTS.GOLO_WEB.SIGNUP_SUCCESS
    UNION ALL
    SELECT lower(EMAIL) AS EMAIL, to_date(RECEIVED_AT) AS FECHA FROM SEGMENT_EVENTS.GOLO_ANDROID_PROD.SIGNUP_SUCCESS
    UNION ALL
    SELECT lower(EMAIL) AS EMAIL, to_date(RECEIVED_AT) AS FECHA FROM SEGMENT_EVENTS.GOLO_IOS_PROD.SIGNUP_SUCCESS
),

REGISTROS_OLO AS (
    SELECT lower(CONTEXT_TRAITS_EMAIL) AS EMAIL, to_date(TIMESTAMP) AS FECHA FROM SEGMENT_EVENTS.DOMINOS_ANDROID_APP_PRODUCCION.SIGNED_IN WHERE CONTEXT_TRAITS_NAME IS NOT NULL          
    UNION ALL
    SELECT lower(CONTEXT_TRAITS_EMAIL) AS EMAIL, to_date(TIMESTAMP) AS FECHA FROM SEGMENT_EVENTS.DOMINOS_APP_PRODUCCION.SIGNED_IN WHERE CONTEXT_TRAITS_FIRST_NAME IS NOT NULL 
),

REGISTROS_TOTAL AS (
    SELECT
        EMAIL,
        min(FECHA) AS FECHA_REGISTRO
    FROM
    (
        SELECT * FROM REGISTROS_CLOUD
        UNION ALL
        SELECT * FROM REGISTROS_OLO
    )
    WHERE 
        EMAIL IS NOT null
    AND 
        EMAIL <>'NULL'
    GROUP BY
        EMAIL
),

SEGMENTACION_BASE_NUEVOS_SIN_COMPRA AS (
    SELECT DISTINCT
        EMAIL,
        'NUEVOS_SIN_COMPRA' AS SEGMENTO
    FROM
        REGISTROS_TOTAL
    LEFT JOIN
        TRANSACCIONES_OLO_Y_CLOUD
    USING(
        EMAIL
    )
    WHERE
        TRANSACCIONES_OLO_Y_CLOUD.EMAIL IS null
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
),

SEGMENTACION_BASE_INACTIVOS AS (
    SELECT
        EMAIL,
        'INACTIVOS' AS SEGMENTO
    FROM
        TRANSACCIONES_OLO_Y_CLOUD
    JOIN
        RANGO_DE_FECHAS
    GROUP BY
        EMAIL,
        FECHA_INICIO_ACTIVOS,
        FECHA_INICIO_INACTIVOS
    HAVING
        max(FECHA) < FECHA_INICIO_ACTIVOS
    AND
        FECHA_INICIO_INACTIVOS <= max(FECHA)
),

SEGMENTACION_BASE_PERDIDOS AS (
    SELECT
        EMAIL,
        'PERDIDOS' AS SEGMENTO
    FROM
        TRANSACCIONES_OLO_Y_CLOUD
    JOIN
        RANGO_DE_FECHAS
    GROUP BY
        EMAIL,
        FECHA_INICIO_ACTIVOS,
        FECHA_INICIO_INACTIVOS
    HAVING
        max(FECHA) <  FECHA_INICIO_INACTIVOS
),

SEGMENTACION_TOTAL AS (
    SELECT EMAIL, SEGMENTO FROM SEGMENTACION_BASE_NUEVOS_SIN_COMPRA
    UNION ALL
    SELECT EMAIL, SEGMENTO FROM SEGMENTACION_BASE_ACTIVOS
    UNION ALL
    SELECT EMAIL, SEGMENTO FROM SEGMENTACION_BASE_INACTIVOS
    UNION ALL
    SELECT EMAIL, SEGMENTO FROM SEGMENTACION_BASE_PERDIDOS
),

SEGMENTACION_GC AS (
    SELECT 
        EMAIL,
        'CONTROL' AS FLAG_GC 
    FROM
        SEGMENTACION_TOTAL tablesample bernoulli (10)
),

SEGMENTACION_GP_GC AS (
    SELECT
        EMAIL,
        ifnull(FLAG_GC, 'PROMOCION') AS GRUPO,
        SEGMENTO
    FROM
        SEGMENTACION_TOTAL
    LEFT JOIN
        SEGMENTACION_GC
    USING(
        EMAIL
    )
),

VENTA_CON_DELIVERY_TIME AS (
    SELECT
        TO_CHAR(FDIDDIA,'YYYY-MM-DD') || '-' || to_char(FCIDTIENDA) || '-' || to_char(FITICKET) AS ORDER_ID,
        (FCTIEMPOENTREGA) / 60 AS TIEMPO_EN_MINUTOS
    FROM
        SEGMENT_EVENTS.DOMINOS_POS.TAF_ORDENES AS ORDENES
    INNER JOIN
        SEGMENT_EVENTS.DOMINOS_POS.TACCLIENTES AS CLIENTES
    ON
        CLIENTES.FIIDCLIENTE = ORDENES.FIIDCLIENTE
    AND
        CLIENTES.FIIDTIENDA = ORDENES.FCIDTIENDA
    WHERE 
        ORDENES.FIIDCLIENTE <> 0
    AND
        ORDENES.FIIDMARCA IN ( 193, 4 )
    AND
        TIEMPO_EN_MINUTOS > 0
),

TIEMPO_DE_ENTREGA_POR_USUARIO AS (
    SELECT
        EMAIL,
        avg(TIEMPO_EN_MINUTOS) AS TIEMPO_PROMEDIO,
        CASE
            WHEN TIEMPO_PROMEDIO < 30 THEN '<30'
            WHEN TIEMPO_PROMEDIO < 45 THEN '30 - 45'
            ELSE '>45'
        END AS TIEMPO_DE_ENTREGA
    FROM
        TRANSACCIONES_OLO_Y_CLOUD
    INNER JOIN
        VENTA_CON_DELIVERY_TIME
    USING(
        ORDER_ID
    )
    GROUP BY
        EMAIL
),

APP_TOTAL AS (
    SELECT lower(CONTEXT_TRAITS_EMAIL) AS EMAIL, to_date(TIMESTAMP) AS FECHA FROM SEGMENT_EVENTS.GOLO_ANDROID_PROD.APPLICATION_OPENED
    UNION ALL
    SELECT lower(CONTEXT_TRAITS_EMAIL) AS EMAIL, to_date(TIMESTAMP) AS FECHA FROM SEGMENT_EVENTS.GOLO_IOS_PROD.APPLICATION_OPENED
    UNION ALL
    SELECT lower(CONTEXT_TRAITS_EMAIL) AS EMAIL, to_date(TIMESTAMP) AS FECHA FROM SEGMENT_EVENTS.DOMINOS_ANDROID_APP_PRODUCCION.APPLICATION_OPENED
    UNION ALL
    SELECT lower(CONTEXT_TRAITS_EMAIL) AS EMAIL, to_date(TIMESTAMP) AS FECHA FROM SEGMENT_EVENTS.DOMINOS_APP_PRODUCCION.APPLICATION_OPENED
),

TIENE_APP AS (
    SELECT
        EMAIL
    FROM
        APP_TOTAL
    INNER JOIN
        RANGO_DE_FECHAS
    ON
        FECHA <= FECHA_FIN
    AND
        FECHA_INICIO_ACTIVOS <= FECHA
    WHERE 
        EMAIL <>'NULL'
    GROUP BY
        EMAIL
),

-- ALT_DATOS_CLIENTES AS (
    -- SELECT DISTINCT
    --     lower(EMAIL) AS EMAIL,
    --     last_value(PHONE) OVER (PARTITION BY lower(EMAIL) ORDER BY FECHA) AS PHONE,
    --     last_value(FIRSTNAME) OVER (PARTITION BY lower(EMAIL) ORDER BY FECHA) AS FIRST_NAME
    -- FROM
    --     TRANSACCIONES_OLO_Y_CLOUD
    -- WHERE
    --     PHONE <> 'None'
-- )

SEGMENTACION_FINAL AS (
    SELECT
        2023 AS ANIO,
        33 AS SEMANA,
        'DOMINOSMANIA' AS PROMO,
        SEGMENTACION_GP_GC.EMAIL,
        -- coalesce(SABANA_DATOS_OLO.PHONE, ALT_DATOS_CLIENTES.PHONE) AS PHONENUMBER,
        SABANA_DATOS_OLO.PHONE AS PHONENUMBER,
        SABANA_DATOS_OLO.FIRST_NAME AS NAME,
        GRUPO,
        SEGMENTO,
        TIENE_APP.EMAIL IS NOT null AS APP_INSTALADA,
        TIEMPO_DE_ENTREGA_POR_USUARIO.TIEMPO_DE_ENTREGA
    FROM
        SEGMENTACION_GP_GC
    LEFT JOIN
        TIEMPO_DE_ENTREGA_POR_USUARIO
    USING(
        EMAIL
    )
    LEFT JOIN
        TIENE_APP
    USING(
        EMAIL
    )
    LEFT JOIN
        SEGMENT_EVENTS.SABANA_DATOS.SABANA_DATOS_OLO
    ON
        lower(SEGMENTACION_GP_GC.EMAIL) = lower(SABANA_DATOS_OLO.EMAIL)
    -- LEFT JOIN
    --     ALT_DATOS_CLIENTES
    -- ON
    --     lower(SEGMENTACION_GP_GC.EMAIL) = lower(ALT_DATOS_CLIENTES.EMAIL)
),

SEGMENTACION_PREVIA AS (
    SELECT
        *
    FROM
        WOW_REWARDS.SEGMENTACION_DOMINOS.SEGMENTACION_JULIO
    WHERE
        PROMO = 'DOMINOSMANIA'
    AND
        SEMANA = 33
)

SELECT
    *
FROM
    SEGMENTACION_FINAL
LEFT JOIN
    SEGMENTACION_PREVIA
USING(
    EMAIL
)
WHERE
    SEGMENTACION_FINAL.GRUPO <> SEGMENTACION_PREVIA.GRUPO
OR
    SEGMENTACION_FINAL.SEGMENTO <> SEGMENTACION_PREVIA.SEGMENTO
OR
    SEGMENTACION_FINAL.APP_INSTALADA <> SEGMENTACION_PREVIA.APP_INSTALADA
;