from  genquery import Query, Option,  AS_DICT
import datetime
from pprint import pformat

class Err(Exception): pass

def main(rule_args, callback, rei):
    colls = []
    home='/tempZone/home/rods'
    now = f'{datetime.datetime.now():%s.%f}'
    try:
        for coll in ('Test','tEST','TEST','test'):
            retv=callback.msiCollCreate((coll:=f'{home}/{now}/{coll}'), '1', 999)
            if retv['arguments'][2] != 0:
                callback.writeLine('stderr',f'error in creation: {retv = }')
                return 1
            else:
                callback.writeLine('stderr',f'newdir {coll!r}')
                colls.append(coll)
        query = Query(
            callback, ["COLL_NAME"],
            """COLL_NAME like '%/test'""" 
#           f""" and COLL_PARENT_NAME = '{home}/{now}'"""
,
            case_sensitive=False,
            offset=1,
            output=AS_DICT
        )
        rows = list(query)
        total = query.total_rows()

        if len(rows) != len(colls)-1 or total != len(colls):
            #raise Err('Incorrect Result')
            callback.writeLine('stderr',f'fail: {pformat(rows) = !s}; {total = }; {len(colls) = }')
        else:
            callback.writeLine('stderr','pass')

    finally:
        pass
        for coll in colls:
            retv = callback.msiRmColl(coll,'forceFlag=',999)
        callback.writeLine('stderr','finally')

INPUT null
OUTPUT ruleExecOut
