import datetime
import pprint as pp
from genquery import Query, Option, AS_DICT

class Err(Exception): pass

def main(rule_args, callback, rei):
    colls = []
    home='/tempZone/home/rods'
    now = f'{datetime.datetime.now():%s.%f}'
    coll_names_lowercase = ['issue-258-'+str(i) for i in range(10)]

    try:
        for coll in (coll_names_lowercase + [_.capitalize() for _ in coll_names_lowercase]):
            retv = callback.msiCollCreate((coll:=f'{home}/{now}/{coll}'), '1', -1)
            if retv['arguments'][2] != 0:
                raise Err(f'could not create test collection {coll}')
            else:
                colls.append(coll)

        query = Query(
            callback, ["COLL_NAME","COLL_PARENT_NAME"],
            f"""COLL_NAME like '%/issue%' and COLL_PARENT_NAME = '{home}/{now}'"""
            , case_sensitive=False
            , offset=1
        )

        rows = list(query)
        total = query.total_rows()

        # Assert that offset=1 produced the correct number of row results.

        if len(rows) != len(colls)-1:
            callback.writeLine('stderr',f'{rows=}')
            raise Err('Incorrect result')

        # Assert that total_rows found the correct number of total matching rows.

        if total != len(colls):
            raise Err('Incorrect total')

    except:
        return -1
    finally:
        callback.msiRmColl(f'{home}/{now}','forceFlag=',-1)

INPUT null
OUTPUT ruleExecOut
