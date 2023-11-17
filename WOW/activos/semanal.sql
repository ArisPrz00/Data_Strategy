WITH

SEMANAS AS (
    SELECT
        SEM_ALSEA,
        MES_ALSEA,
        ANIO_ALSEA,
        max(to_date(FECHA)) AS FECHA_FIN,
        FECHA_FIN - 180 AS FECHA_INICIO
    FROM
        WOW_REWARDS.WORK_SPACE_WOW_REWARDS.DS_DIM_TIME
    WHERE
    (
        ANIO_ALSEA = 2023
        -- AND
        -- SEM_ALSEA IN (36)
    )
    -- OR
    --     ANIO_ALSEA = 2022
    GROUP BY
        SEM_ALSEA,
        MES_ALSEA,
        ANIO_ALSEA
),

VENTAS_RESTAURANTES AS (
    SELECT
        CASE 
            WHEN MARCA = 'VIPS MEXICO' THEN MARCA
            ELSE 'CASUALES'
        END AS MARCA,
        -- MARCA,
        EMAIL,
        to_date(DATETIME) AS FECHA
    FROM
        WOW_REWARDS.WORK_SPACE_WOW_REWARDS.DS_VENTAS_ORDENES_WOW
    WHERE
        MARCA IN (
            'THE CHEESECAKE FACTORY MEXICO',
            'ITS JUST WINGS',
            'CHILIS MEXICO',
            'ITALIANNIS MEXICO',
            'P.F. CHANGS MEXICO',
            'VIPS MEXICO'
        )
    AND
        POS_EMPLOYEE_ID NOT IN ('Power', '1 service cloud')
)

SELECT
    ANIO_ALSEA,
    MES_ALSEA,
    SEM_ALSEA,
    MARCA,
    count(DISTINCT lower(EMAIL))
FROM
    VENTAS_RESTAURANTES
INNER JOIN
    SEMANAS
ON
    FECHA <= FECHA_FIN
AND 
    FECHA_INICIO < FECHA
GROUP BY
    SEM_ALSEA,
    MES_ALSEA,
    MARCA,
    ANIO_ALSEA
ORDER BY
    MARCA,
    ANIO_ALSEA DESC,
    SEM_ALSEA DESC

;