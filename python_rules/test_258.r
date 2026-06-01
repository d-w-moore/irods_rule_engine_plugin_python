import datetime
from genquery import Query
import os

class Err(Exception): pass

def main(rule_args, callback, rei):
    print_test_vector_and_quit = irods_rule_vars['*PRINT_TEST_VECTOR_AND_QUIT'][1:-1].upper().startswith("Y")
    colls = []
    home='/tempZone/home/rods'
    now = f'{datetime.datetime.now():%s.%f}'
    n_base_names = 10

    coll_names_lowercase = ['issue-258-'+str(i) for i in range(n_base_names)]

    # LINE COUNTER
    n = -1
    try:
        for coll in (coll_names_lowercase + [_.capitalize() for _ in coll_names_lowercase]):
            retv = callback.msiCollCreate((coll:=f'{home}/{now}/{coll}'), '1', -1)
            if retv['arguments'][2] != 0:
                raise Err(f'could not create test collection {coll}')
            else:
                colls.append(coll)

# EXPECTED RESULTS FROM THE VARIOUS TEST VECTOR COMBINATIONS: (re-generate using argument '*PRINT_TEST_VECTOR_AND_QUIT="yes"')
#       {case_sensitive_} {offset_} {limit_} {expected_result_rows} {expected_total_rows}
#             False           0       None             20                    20
#             False           0        4               4                     20
#             False           0        14              14                    20
#             False           3       None             17                    20
#             False           3        4               4                     20
#             False           3        14              14                    20
#             True            0       None             10                    10
#             True            0        4               4                     10
#             True            0        14              10                    10
#             True            3       None             7                     10
#             True            3        4               4                     10
#             True            3        14              7                     10

        for case_sensitive_ in (False, True):
            for offset_ in (0,3):
                for limit_ in (None, 4, 14):
                    # We expect double the total number of matching rows for case sensitivity being turned off,
                    # due to the capitalized versions showing up in the query.
                    expected_total_rows = n_base_names * (1 if case_sensitive_ else 2)

                    # We expect this relationship to hold for how offset and limit options affect number of
                    # matching rows actually returned.
                    expected_result_rows = min(
                        max(0, expected_total_rows - offset_),
                        limit_ if limit_ is not None else expected_total_rows
                    )

                    if print_test_vector_and_quit:
                        if 0 == (n:=n+1):
                            callback.writeLine("stderr", "{case_sensitive_} {offset_} {limit_} {expected_result_rows} {expected_total_rows}")
                        callback.writeLine("stderr", f"{case_sensitive_!r:^17} {offset_:^9} {limit_!s:^8} {expected_result_rows:^22} {expected_total_rows:^21}")
                        continue

                    query = Query(
                        callback,
                        ["COLL_NAME"],
                        f"""COLL_NAME like '%/issue%' and COLL_PARENT_NAME = '{home}/{now}'"""
                        , case_sensitive=case_sensitive_
                        , offset=offset_
                        , limit=limit_
                    )

                    # Assert that the combination of options selected returned the expected number of row results.
                    received_result_rows = len(list(query))
                    if received_result_rows != expected_result_rows:
                        raise Err(f'{expected_result_rows=}; {received_result_rows=}')

                    # Assert that total_rows() correctly found the number of rows actually matching the query condition,
                    # irrespective of the offset and limit.
                    received_total_rows = query.total_rows()
                    if received_total_rows != expected_total_rows:
                        raise Err(f'{expected_total_rows=}; {received_total_rows=}')
    except Exception as e:
        callback.writeLine("stderr", f"Exception causing test to fail: {e}")
        return -1
    finally:
        if not print_test_vector_and_quit:
            callback.msiRmColl(f'{home}/{now}','forceFlag=',-1)

INPUT *PRINT_TEST_VECTOR_AND_QUIT="no"
OUTPUT ruleExecOut
