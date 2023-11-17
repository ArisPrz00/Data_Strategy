WITH

SEMANAS AS (
    SELECT
        ANIO_ALSEA,
        MES_ALSEA,
        SEM_ALSEA,
        to_date(max(FECHA)) AS FECHA_FIN_SEMANA_ACTUAL,
        FECHA_FIN_SEMANA_ACTUAL - 180 AS FECHA_INICIO_SEMANA_ACTUAL,
        FECHA_FIN_SEMANA_ACTUAL - 7 AS FECHA_FIN_SEMANA_PREVIA,
        FECHA_FIN_SEMANA_PREVIA - 180 AS FECHA_INICIO_SEMANA_PREVIA,
        FECHA_FIN_SEMANA_PREVIA - 365 AS FECHA_INICIO_INACTIVOS_SEMANA_PREVIA
    FROM
        WOW_REWARDS.WORK_SPACE_WOW_REWARDS.DS_DIM_TIME
    WHERE
    (
        ANIO_ALSEA = 2023
    )
    GROUP BY
        ANIO_ALSEA,
        MES_ALSEA,
        SEM_ALSEA
),

TRANSACCIONES_OLO AS (
    SELECT DISTINCT
        lower(MXP.EMAIL) AS EMAIL,
        to_date(OLO.ORDER_DATE) AS FECHA
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
        UPPER(OLO.SOURCE_CODE) IN ('ANDROID' , 'DESKTOP', 'IOS', 'MOBILE', 'WEB', 'ANDROID2', 'DESKTOP2', 'IOSAPP', 'MOBILE2', 'WHATSAPP')
),

TRANSACCIONES_CLOUD AS (
    SELECT DISTINCT 
        lower(A.EMAIL) AS EMAIL,
        to_date(SUBSTRING(A.STOREORDERID,1,10)) AS FECHA
    FROM 
        "SEGMENT_EVENTS"."DOMINOS_GOLO"."VENTA_CLOUD" A
    WHERE 
        A.STOREID NOT LIKE '9%'
    AND 
        A.SOURCEORGANIZATIONURI IN ('order.dominos.com','resp-order.dominos.com','iphone.dominos.mx','android.dominos.mx') 
    AND 
        A.SOURCEORGANIZATIONURI IS NOT NULL
),

TRANSACCIONES_TOTAL AS (
    SELECT * FROM TRANSACCIONES_CLOUD
    UNION ALL
    SELECT * FROM TRANSACCIONES_OLO
),

PRIMERAS_COMPRAS AS (
    SELECT
        lower(EMAIL) AS EMAIL,
        min(FECHA) AS FECHA
    FROM
        TRANSACCIONES_TOTAL
    GROUP BY
        EMAIL
),

PRIMERAS_COMPRAS_CON_SEMANA AS (
    SELECT
        ANIO_ALSEA,
        MES_ALSEA,
        SEM_ALSEA,
        EMAIL
    FROM
        PRIMERAS_COMPRAS
    INNER JOIN
        WOW_REWARDS.WORK_SPACE_WOW_REWARDS.DS_DIM_TIME
    USING(
        FECHA
    )
),

STATUS_EN_SEMANA_PREVIA AS (
    SELECT
        EMAIL,
        SEM_ALSEA,
        MES_ALSEA,
        ANIO_ALSEA,
        CASE avg(CASE WHEN FECHA > FECHA_INICIO_SEMANA_PREVIA THEN 1 ELSE 0 END)
            WHEN 0 THEN 'INACTIVO'
            ELSE 'ACTIVO'
        END AS STATUS
    FROM
        TRANSACCIONES_TOTAL
    INNER JOIN
        SEMANAS
    ON
        FECHA_INICIO_INACTIVOS_SEMANA_PREVIA <= FECHA
    AND
        FECHA <= FECHA_FIN_SEMANA_PREVIA
    GROUP BY
        EMAIL,
        SEM_ALSEA,
        MES_ALSEA,
        ANIO_ALSEA
),

ACTIVOS_EN_SEMANA_ACTUAL AS (
    SELECT
        EMAIL,
        SEM_ALSEA,
        MES_ALSEA,
        ANIO_ALSEA
    FROM
        TRANSACCIONES_TOTAL
    INNER JOIN
        SEMANAS
    ON
        FECHA_INICIO_SEMANA_ACTUAL < FECHA
    AND
        FECHA <= FECHA_FIN_SEMANA_ACTUAL 
    GROUP BY
        EMAIL,
        SEM_ALSEA,
        MES_ALSEA,
        ANIO_ALSEA
),

PRE_PIVOT AS (
    SELECT
        coalesce(STATUS_EN_SEMANA_PREVIA.ANIO_ALSEA, ACTIVOS_EN_SEMANA_ACTUAL.ANIO_ALSEA) AS ANIO,
        coalesce(STATUS_EN_SEMANA_PREVIA.MES_ALSEA, ACTIVOS_EN_SEMANA_ACTUAL.MES_ALSEA) AS MES,
        coalesce(STATUS_EN_SEMANA_PREVIA.SEM_ALSEA, ACTIVOS_EN_SEMANA_ACTUAL.SEM_ALSEA) AS SEM,
        CASE
            -- WHEN ACTIVOS_EN_SEMANA_PREVIA.EMAIL IS null AND PRIMERAS_COMPRAS_CON_SEMANA.EMAIL IS null THEN 'RECUPERADOS'
            -- WHEN STATUS_EN_SEMANA_PREVIA.EMAIL IS null THEN 'PRIMERAS_COMPRAS'
            -- WHEN ACTIVOS_EN_SEMANA_ACTUAL.EMAIL IS null THEN 'RECIEN_INACTIVADOS'
            WHEN ACTIVOS_EN_SEMANA_ACTUAL.EMAIL IS NOT NULL AND PRIMERAS_COMPRAS_CON_SEMANA.EMAIL IS NOT null THEN 'NUEVOS'
            WHEN ACTIVOS_EN_SEMANA_ACTUAL.EMAIL IS NOT NULL AND STATUS_EN_SEMANA_PREVIA.EMAIL IS null AND PRIMERAS_COMPRAS_CON_SEMANA.EMAIL IS null THEN 'RECUPERADOS (> 365)'
            WHEN ACTIVOS_EN_SEMANA_ACTUAL.EMAIL IS NOT NULL AND STATUS_EN_SEMANA_PREVIA.STATUS = 'INACTIVO' THEN 'REACTIVADOS (180 - 365)'
            ELSE 'ACTIVOS_EN_AMBOS_PERIODOS'
        END AS CATEGORIA,
        count(DISTINCT lower(coalesce(STATUS_EN_SEMANA_PREVIA.EMAIL, ACTIVOS_EN_SEMANA_ACTUAL.EMAIL))) AS USUARIOS
    FROM
        ACTIVOS_EN_SEMANA_ACTUAL
    FULL OUTER JOIN
        STATUS_EN_SEMANA_PREVIA
    USING(
        EMAIL,
        SEM_ALSEA,
        MES_ALSEA,
        ANIO_ALSEA
    )
    FULL OUTER JOIN
        PRIMERAS_COMPRAS_CON_SEMANA
    USING(
        EMAIL,
        SEM_ALSEA,
        MES_ALSEA,
        ANIO_ALSEA
    )
    GROUP BY
        SEM,
        MES,
        ANIO,
        CATEGORIA
)

SELECT
    *
FROM
    PRE_PIVOT
PIVOT(sum(USUARIOS) FOR CATEGORIA IN ('RECUPERADOS (> 365)', 'REACTIVADOS (180 - 365)', 'NUEVOS'))
-- WHERE
--     PRIMERAS_COMPRAS <> 0
ORDER BY
    ANIO,
    SEM
;
-- Tiempo de ejecucion 2023/08/14: 1m 11s