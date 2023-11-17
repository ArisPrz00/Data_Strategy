WITH

INTERVALOS_DE_FECHAS AS (
    SELECT
        ANIO_ALSEA,
        MES_ALSEA,
        max(to_date(FECHA)) AS FECHA_FIN,
        FECHA_FIN - 90 AS FECHA_INICIO
    FROM
        WOW_REWARDS.WORK_SPACE_WOW_REWARDS.DS_DIM_TIME
    WHERE
        ANIO_ALSEA >= 2022
    GROUP BY
        ANIO_ALSEA,
        MES_ALSEA
),

TRANSACCIONES_BY_USER AS (
    SELECT
        ANIO_ALSEA,
        MES_ALSEA,
        EMAIL,
        sum(CHECK_AMOUNT / 1.16) AS VENTAS,
        count(DISTINCT TRANSACTION_ID) AS FREQ,
        VENTAS / FREQ AS AOV
    FROM
        SEGMENT_EVENTS.SESSIONM_SBX.FACT_TRANSACTIONS
    INNER JOIN
        INTERVALOS_DE_FECHAS
    ON
        to_date(CREATED_AT) BETWEEN FECHA_INICIO AND FECHA_FIN
    WHERE
        EMAIL IS NOT null
    GROUP BY
        ANIO_ALSEA,
        MES_ALSEA,
        EMAIL
),

SEGMENTACION_BASE_ACTIVOS AS (
    SELECT DISTINCT
        TRANSACCIONES_BY_USER.*,
        CASE
            WHEN FREQ <= PERCENTILE_CONT(0.20) WITHIN GROUP (ORDER BY FREQ) OVER (PARTITION BY ANIO_ALSEA, MES_ALSEA) THEN 'LIGHT'
            WHEN FREQ <= PERCENTILE_CONT(0.40) WITHIN GROUP (ORDER BY FREQ) OVER (PARTITION BY ANIO_ALSEA, MES_ALSEA) THEN 'MIDL'
            WHEN FREQ <= PERCENTILE_CONT(0.60) WITHIN GROUP (ORDER BY FREQ) OVER (PARTITION BY ANIO_ALSEA, MES_ALSEA) THEN 'MIDH'
            WHEN FREQ <= PERCENTILE_CONT(0.80) WITHIN GROUP (ORDER BY FREQ) OVER (PARTITION BY ANIO_ALSEA, MES_ALSEA) THEN 'HEAVY'
            ELSE 'SUPER'
        END AS SEGMENTO,
        CASE
            WHEN AOV <= ROUND(PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY AOV) OVER (PARTITION BY ANIO_ALSEA, MES_ALSEA)) THEN 'LOW'
            WHEN AOV <= ROUND(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY AOV) OVER (PARTITION BY ANIO_ALSEA, MES_ALSEA)) THEN 'AVG'
            ELSE 'HIGH'
        END AS TAG_GRUPO,
        SEGMENTO || '_' || TAG_GRUPO AS FULL_SEGMENTO,
        CASE
            WHEN FULL_SEGMENTO IN ('LIGHT_LOW', 'LIGHT_AVG', 'LIGHT_HIGH', 'MIDL_LOW', 'MIDL_AVG', 'MIDH_LOW') THEN 'LOW'
            WHEN FULL_SEGMENTO IN ('MIDL_HIGH', 'MIDH_AVG', 'MIDH_HIGH', 'HEAVY_LOW', 'HEAVY_AVG') THEN 'MEDIUM' 
            WHEN FULL_SEGMENTO IN ('HEAVY_HIGH', 'SUPER_LOW', 'SUPER_AVG') THEN 'HIGH'
            ELSE 'TOP'
        END AS ULTRASEGMENTO
    FROM
        TRANSACCIONES_BY_USER
)

SELECT
    ANIO_ALSEA,
    MES_ALSEA,
    ULTRASEGMENTO,
    count(DISTINCT EMAIL) AS USUARIOS,
    sum(VENTAS) AS VENTA,
    sum(FREQ) AS TRANSACCIONES,
    VENTA / TRANSACCIONES AS TICKET_PROMEDIO,
    TRANSACCIONES / USUARIOS AS FRECUENCIA,
    VENTA / USUARIOS AS CLV
FROM
    SEGMENTACION_BASE_ACTIVOS
GROUP BY
    ANIO_ALSEA,
    MES_ALSEA,
    ULTRASEGMENTO
ORDER BY
    ANIO_ALSEA,
    MES_ALSEA,
    CASE ULTRASEGMENTO
        WHEN 'LOW' THEN 1
        WHEN 'MEDIUM' THEN 2
        WHEN 'HIGH' THEN 3
        WHEN 'TOP' THEN 4
    END
;

WITH

INTERVALOS_DE_FECHAS AS (
    SELECT
        ANIO_ALSEA,
        MES_ALSEA,
        max(to_date(FECHA)) AS FECHA_FIN,
        FECHA_FIN - 90 AS FECHA_INICIO
    FROM
        WOW_REWARDS.WORK_SPACE_WOW_REWARDS.DS_DIM_TIME
    WHERE
        ANIO_ALSEA >= 2022
    GROUP BY
        ANIO_ALSEA,
        MES_ALSEA
)

SELECT
    *
FROM    
    INTERVALOS_DE_FECHAS
ORDER BY    
    ANIO_ALSEA,
    MES_ALSEA
;