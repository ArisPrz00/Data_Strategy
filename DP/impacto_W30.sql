SELECT DISTINCT
    SERVICEMETHOD
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
AND
    to_date(OLO.ORDER_DATE) BETWEEN to_date('2023-07-24') AND to_date('2023-08-27')
;
SELECT DISTINCT 
    SERVICEMETHOD
FROM 
    "SEGMENT_EVENTS"."DOMINOS_GOLO"."VENTA_CLOUD" A
WHERE 
    A.STOREID NOT LIKE '9%'
AND 
    A.SOURCEORGANIZATIONURI IN ('order.dominos.com','resp-order.dominos.com','iphone.dominos.mx','android.dominos.mx') 
AND 
    A.SOURCEORGANIZATIONURI IS NOT NULL
AND
    to_date(SUBSTRING(A.STOREORDERID,1,10)) BETWEEN to_date('2023-07-24') AND to_date('2023-08-27')
;


-- Canales OLO
-- Carryout
-- Delivery
-- Pickup

-- Canales GOLO
-- Carryout
-- Delivery
-- DineIn