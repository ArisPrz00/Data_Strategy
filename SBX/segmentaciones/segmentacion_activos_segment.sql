WITH

INTERVALO_FECHAS AS (
    SELECT
        current_date() - 1 AS FECHA_FIN,
        FECHA_FIN - 90 AS FECHA_INICIO
),

TRANSACCIONES_BY_USER AS (
    SELECT
        EMAIL,
        sum(CHECK_AMOUNT / 1.16) AS VENTAS,
        count(DISTINCT TRANSACTION_ID) AS FREQ,
        VENTAS / FREQ AS AOV
    FROM
        SEGMENT_EVENTS.SESSIONM_SBX.FACT_TRANSACTIONS
    INNER JOIN
        INTERVALO_FECHAS
    ON
        to_date(CREATED_AT) BETWEEN FECHA_INICIO AND FECHA_FIN
    WHERE
        EMAIL IS NOT null
    GROUP BY
        EMAIL
),

SEGMENTACION_BASE_ACTIVOS AS (
    SELECT 
        TRANSACCIONES_BY_USER.*,
        CASE
            WHEN FREQ <= PERCENTILE_CONT(0.20) WITHIN GROUP (ORDER BY FREQ) OVER () THEN 'LIGHT'
            WHEN FREQ <= PERCENTILE_CONT(0.40) WITHIN GROUP (ORDER BY FREQ) OVER () THEN 'MIDL'
            WHEN FREQ <= PERCENTILE_CONT(0.60) WITHIN GROUP (ORDER BY FREQ) OVER () THEN 'MIDH'
            WHEN FREQ <= PERCENTILE_CONT(0.80) WITHIN GROUP (ORDER BY FREQ) OVER () THEN 'HEAVY'
            ELSE 'SUPER'
        END AS SEGMENTO,
        CASE
            WHEN AOV <= ROUND(PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY AOV) OVER ()) THEN 'LOW'
            WHEN AOV <= ROUND(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY AOV) OVER ()) THEN 'AVG'
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
    EMAIL,
    ULTRASEGMENTO,
    USER_ID
FROM
    SEGMENTACION_BASE_ACTIVOS
LEFT JOIN
    SEGMENT_EVENTS.SESSIONM_SBX.SM_USERS
USING(
    EMAIL
)
;