WITH

RANGO_DE_FECHAS AS (
    SELECT 
        to_date('2023-07-30') AS FECHA_FIN,
        FECHA_FIN - 180 AS FECHA_INICIO_ACTIVOS
),

INSTALLED_APP_ANDROID AS (
    SELECT
        USER_ID
    FROM
        SEGMENT_EVENTS.WOW_PROD_ANDROID.APPLICATION_OPENED
    INNER JOIN 
        RANGO_DE_FECHAS 
    ON
        to_date(TIMESTAMP) BETWEEN FECHA_INICIO_ACTIVOS AND FECHA_FIN
),

INSTALLED_APP_IOS AS (
    SELECT
        USER_ID
    FROM
        SEGMENT_EVENTS.WOW_PROD_IOS.APPLICATION_OPENED
    INNER JOIN 
        RANGO_DE_FECHAS 
    ON
        to_date(TIMESTAMP) BETWEEN FECHA_INICIO_ACTIVOS AND FECHA_FIN
),

INSTALLED_APP_TOTAL AS (
    SELECT * FROM INSTALLED_APP_IOS
    UNION ALL
    SELECT * FROM INSTALLED_APP_ANDROID
),

INSTALLED_APP_BY_USER AS (
    SELECT DISTINCT
        EMAIL
    FROM
        INSTALLED_APP_TOTAL
    INNER JOIN
        SEGMENT_EVENTS.SESSIONM_NEW.SM_USERS
    ON
        lower(INSTALLED_APP_TOTAL.USER_ID) = lower(SM_USERS.USER_ID)
)

SELECT DISTINCT
    US.EMAIL,
    US.FIRST_NAME,
    US.LAST_NAME,
    'ACTIVOS' AS CATEGORIA
FROM
    WOW_REWARDS.WORK_SPACE_WOW_REWARDS.DS_VENTAS_ORDENES_WOW
INNER JOIN
    RANGO_DE_FECHAS
ON
    to_date(DATETIME) BETWEEN FECHA_INICIO_ACTIVOS AND FECHA_FIN
LEFT JOIN 
    WOW_REWARDS.WORK_SPACE_WOW_REWARDS.USUARIOS_SESSIONM AS US
ON 
    lower(US.EMAIL) = lower(DS_VENTAS_ORDENES_WOW.EMAIL)
WHERE
    MARCA IN (
        'THE CHEESECAKE FACTORY MEXICO',
        'ITS JUST WINGS',
        'CHILIS MEXICO',
        'ITALIANNIS MEXICO',
        'P.F. CHANGS MEXICO',
        'BURGER KING MEXICO'
    )
AND
    POS_EMPLOYEE_ID NOT IN ('Power', '1 service cloud')
AND
    US.EMAIL IN (SELECT lower(EMAIL) FROM INSTALLED_APP_BY_USER)