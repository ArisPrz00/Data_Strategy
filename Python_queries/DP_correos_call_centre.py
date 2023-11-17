from snowflake.snowpark import DataFrame, Session

def get_correos_call_centre(session:Session) -> DataFrame:
    """
    Genera un DataFrame de snowpark con los Emails que corresponden a call centre.

    Columnas:

    (Total)

    EMAIL: Email que corresponde a call centre
    """
    lst = [
        'wilsonsalamanca12@gmail.com',
        'jeclau123@gmail.com',
        'serratorosalba@gmail.com',
        'khatleen@hotmail.com',
        'vdsalamanca@gmail.com',
        'davgel07@yahoo.es',
        'andrea.laragomez2@gmail.com',
        'laura2001camilas@hotmail.com',
        'paula.leon07@hotmail.com',
        'lelelinda2.lys@gmail.com',
        'nicollhuertas24@gmail.com',
        'julieth157@gmail.com',
        'julian.ramirez10@outlook.com',
        'valenes2002@gmail.com',
        'jakysar01@gmail.com',
        'sebastianthompson@outlook.es',
        'nyfp21@gmail.com',
        'erik.lopez1953@gmail.com',
        'karensuarezu@gmail.com',
        'oovallep@upn.edu.co',
        'palenciahiguera2020@gmail.com',
        'orjueladiazkarendaniela@gmail.com',
        'picosantiago@gmail.com',
        'felipe_88_05@hotmail.com',
        'karentar2000@gmail.com',
        'vomvom92@gmail.com',
        'c.santiagocabrera07@gmail.com',
        'jissel270591@gmail.com',
        'hernandez.mateo1002@gmail.com',
        'miladyesteban1316@outlook.es',
        'maria1994tapiero@gmail.com',
        'mmayorcabacca@gmail.com',
        'dominos1@ecd.mx',
        'dominos2@ecd.mx',
        'dominos3@ecd.mx',
        'dominos4@ecd.mx',
        'dominos5@ecd.mx',
        'dominos6@ecd.mx',
        'dominos7@ecd.mx',
        'dominos8@ecd.mx',
        'dominos9@ecd.mx',
        'dominos10@ecd.mx',
        'dominos11@ecd.mx',
        'dominos12@ecd.mx',
        'dominos13@ecd.mx',
        'dominos14@ecd.mx',
        'dominos15@ecd.mx',
        'kzarate@ecd.mx',
        'cmonter@ecd.mx',
        'pedidosdominosmexico@gmail.com',
        'pedidosdominosmx@gmail.com',
        'pedidosdominos@gmail.com',
        'vdsalamanca2012@gmail.com',
        'jeclau1230@gmail.com',
        'nicollhuertas98@gmail.com',
        'fcodanny@gmail.com',
        'fcodominos@gmail.com',
        'contactcenterdominos@gmail.com',
        'dominosegp1@hotmail.com',
        'pedidosdominoscolombia@gmail.com',
        'michael+dominos.com.mx@gravis.ca',
        'dominospizza1173@gmail.com',
        'sincorreodominos@gmail.com',
        'dominos52@ecd.mx',
        'abrahammmtzmtz+dominos1+1@gmail.com',
        'sincorreodominos11@gmail.com',
        'nube.alada+dominos@gmail.com',
        'alexisjmz+dominos@gmail.com',
        'dominos@fernandoramirez.com.mx',
        'dominos27@ecd.mx',
        'dominos@deleon.mx',
        'pdominos1612@gmail.com',
        'fernando.ramos.a+dominos@gmail.com',
        'dominos@cccpknox.com',
        'dominos.delirious760@passinbox.com',
        'hilda.alvarez@dominos.com.mx',
        'dominos.giddily533@passmail.net',
        'dontmake@dominos.com',
        'sincorreodominos20000@gmail.com',
        'sincorreodominos10000@gmail.com',
        'sincorreodominos1@gmail.com',
        'sincorreodominos5@gmail.com',
        'dominos.mx@coty-hector.com',
        'eduardo-dominos@usa.net',
        'dominos@drattek.com',
        'latlovs-dominos@yahoo.com',
        'sincorreodominos3@gmail.com',
        'dominos@aldomedina.com',
        'dominoswal@outlook.com',
        'alopez+dominos@cajanauta.com',
        'dominos@sebas12.com',
        'dominos@mbps.mx',
        '11446@dominos.live',
        'dominos@andresb.net',
        'camiladominos7@gmail.com',
        'dominos@maw.mx',
        'dominos@baniares.com',
        'dominos@mr337.com',
        'liliana.contreras@dominos.com.mx',
        'flick36+dominos@gmail.com',
        'sincorreodominos4@gmail.com',
        'dominos40xd@gmail.com',
        'sincorreodominos1000@gmail.com',
        'dominos2@ishtto.com',
        'calabasat2000-dominos@yahoo.com',
        'dominos.sgf@simplelogin.com',
        'sincorreodominos2@gmail.com',
        'sincorreodominos6@gmail.com',
        'dominosdlg75@gmail.com',
        'sincorreodominos7@gmail.com',
        'dominos@coimsa.com.mx',
        'malfonso+dominos@gmail.com',
        'dominosdominos044@gmail.com',
        'dominos25@ecd.mx',
        'dominos24@ecd.mx',
        'dominos31@ecd.mx',
        'dominos38@ecd.mx',
        'dominos51@ecd.mx',
        'dominos39@ecd.mx',
        'dominos43@ecd.mx',
        'dominos22@ecd.mx',
        'dominos26@ecd.mx',
        'dominos32@ecd.mx',
        'dominos56@ecd.mx',
        'dominos52@ecd.mx',
        'dominos58@ecd.mx',
        'dominos35@ecd.mx',
        'dominos47@ecd.mx',
        'dominos55@ecd.mx',
        'dominos44@ecd.mx',
        'dominos21@ecd.mx',
        'dominos29@ecd.mx',
        'dominos27@ecd.mx',
        'dominos40@ecd.mx',
        'dominos59@ecd.mx',
        'dominos49@ecd.mx',
        'dominos42@ecd.mx',
        'dominos36@ecd.mx',
        'dominos48@ecd.mx',
        'dominos34@ecd.mx',
        'dominos50@ecd.mx',
        'dominos54@ecd.mx',
        'dominos28@ecd.mx',
        'dominos46@ecd.mx',
        'dominos100@ecd.mx',
        'dominos111@ecd.mx',
        'dominos112@ecd.mx',
        'dominos103@ecd.mx',
        'dominos33@ecd.mx',
        '199@numerocero.com.mx',
        '665@numerocero.com.mx', 
        '197@numerocero.com.mx',
        '1e@numerocero.com.mx',
        '1d@numerocero.com.mx',
        '1las2@numerocero.com.mx',
        '479@numerocero.com.mx',
        '299a@numerocero.com.mx',
        '558@numerocero.com.mx',
        '731@numerocero.com.mx',
        '1a1@numerocero.com.mx',
        '143@numerocero.com.mx',
        'hbo8@numerocero.com.mx',
        '218@numerocero.com.mx',
        '280@numerocero.com.mx',
        '172@numerocero.com.mx',
        'dominos1@ecd.mx',
        'dominos13@ecd.mx',
        '1e@numerocero.com.mx',
        '479@numerocero.com.mx',
        '1las2@numerocero.com.mx',
        '1d@numerocero.com.mx',
        '558@numerocero.com.mx',
        '731@numerocero.com.mx',
        '665@numerocero.com.mx',
        '1a1@numerocero.com.mx',
        'hbo8@numerocero.com.mx',
        'hbo7@numerocero.com.mx',
        '218@numerocero.com.mx',
        '1@numerocero.com.mx',
        '398a@numerocero.com.mx',
        '398a@numerocero.com.mx',
        '398a@numerocero.com.mx',
        '1las@numerocero.com.mx',
        'hbo4@numerocero.com.mx',
        '207a@numerocero.com.mx',
        '1f@numerocero.com.mx',
        '207a@numerocero.com.mx',
        '226@numerocero.com.mx',
        'aa1@numerocero.com.mx',
        '1a3@numerocero.com.mx',
        '225a@numerocero.com.mx',
        'a1@numerocero.com.mx',
        '1aaa@numerocero.com.mx',
        '97@numerocero.com.mx',
        '115@numerocero.com.mx',
        '310a@numerocero.com.mx',
        '309@numerocero.com.mx',
        '4hbo@numerocero.com.mx',
        '4hbo@numerocero.com.mx',
        '168@numerocero.com.mx',
        'aa1@numerocero.com.mx',
        '398a@numerocero.com.mx',
        '1c@numerocero.com.mx',
        '1g@numerocero.com.mx',
        '458b@numerocero.com.mx',
        '1f@numerocero.com.mx',
        '2@numerocero.com.mx',
        'ap14@numerocero.com.mx',
        '171@numerocero.com.mx',
        '309@numerocero.com.mx',
        'daniel@numerocero.com.mx',
        'hbo6@numerocero.com.mx',
        '4hbo@numerocero.com.mx',
        'daniel@numerocero.com.mx',
        '4hbo@numerocero.com.mx',
        '1f@numerocero.com.mx',
        '4hbo@numerocero.com.mx',
        '1g@numerocero.com.mx',
        '1a2@numerocero.com.mx',
        '289@numerocero.com.mx',
        '192@numerocero.com.mx',
        'glup1@numerocero.com.mx',
        '1a3@numerocero.com.mx',
        '1g@numerocero.com.mx',
        '458b@numerocero.com.mx',
        'dominos71@ecd.mx',
        'dominos70@ecd.mx',
        'dominos113@ecd.mx',
        'dominos23@ecd.mx',
        'dominos98@ecd.mx',
        'dominos30@ecd.mx',
        'dominos96@ecd.mx',
        'dominos17@ecd.mx',
        'dominos37@ecd.mx',
        'dominos57@ecd.mx',
        'dominos60@ecd.mx',
        'dominos17@ecd.mx',
        'dominos110@ecd.mx',
        'dominos20@ecd.mx',
        'dominos53@ecd.mx',
        '102@numerocero.com.mx',
        'sincorreodominos100@gmail.com',
        'sincorreodominos8@gmail.com'
    ]

    return session.create_dataframe(lst, schema = ['EMAIL'])