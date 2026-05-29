import datetime
from genquery import Query

class Err(Exception): pass

def main(rule_args, callback, rei):
    colls = []
    home='/tempZone/home/rods'
    now = f'{datetime.datetime.now():%s.%f}'

    # Keep the following an even number:
    n_base_names = 10

    coll_names_lowercase = ['issue-258-'+str(i) for i in range(n_base_names)]

    try:
        for coll in (coll_names_lowercase + [_.capitalize() for _ in coll_names_lowercase]):
            retv = callback.msiCollCreate((coll:=f'{home}/{now}/{coll}'), '1', -1)
            if retv['arguments'][2] != 0:
                raise Err(f'could not create test collection {coll}')
            else:
                colls.append(coll)

        for limit_ in (None, 4, 14):
            for case_sensitive_ in (False, True):
                for offset_ in (0,3):
                    query = Query(
                        callback,
                        ["COLL_NAME"],
                        f"""COLL_NAME like '%/issue%' and COLL_PARENT_NAME = '{home}/{now}'"""
                        , case_sensitive=case_sensitive_
                        , offset=offset_
                        , limit=limit_
                    )

                    expected_total_rows = n_base_names * (1 if case_sensitive_ else 2)
                    expected_result_rows = min(
                        max(0, expected_total_rows - offset_),
                        limit_ if limit_ is not None else expected_total_rows
                    )

                    # Assert that offset=1 produced the correct number of row results.
                    if (got_result_rows:=len(list(query))) != expected_result_rows:
                        raise Err(f'{expected_result_rows=}; {got_result_rows=}')
            
                    # Assert that total_rows found the correct number of total matching rows.
                    if (got_total_rows:=query.total_rows()) != expected_total_rows:
                        raise Err(f'{expected_total_rows=}; {got_total_rows=}')
    except:
        return -1
    finally:
        callback.msiRmColl(f'{home}/{now}','forceFlag=',-1)

INPUT null
OUTPUT ruleExecOut
