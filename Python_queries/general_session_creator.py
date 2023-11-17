from snowflake.snowpark import Session
from configparser import ConfigParser

def create_session() -> Session:
    config = ConfigParser()
    config.read('config.ini')

    connection_parameters: dict[str, int | str] = {
        'user' : config.get('SNOWFLAKE', 'USER'),
        'password' : config.get('SNOWFLAKE', 'PASSWORD'),
        'account' : config.get('SNOWFLAKE', 'ACCOUNT'),
        'database' : config.get('SNOWFLAKE', 'DATABASE'),
        'warehouse' : config.get('SNOWFLAKE', 'WAREHOUSE'),
        'schema' : config.get('SNOWFLAKE', 'SCHEMA'),
        'role' : config.get('SNOWFLAKE', 'ROLE'),
    }

    session = Session.builder.configs(connection_parameters).create()

    return session