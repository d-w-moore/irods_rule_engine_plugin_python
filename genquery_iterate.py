import irods_types

MAX_SQL_ROWS = 256

class bad_column_spec (Exception): pass

def is_CAT_NO_ROWS_FOUND (ret_val):
  return (ret_val['status'] == False and abs( ret_val['code'] ) == 808000)

# ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
# :::::              generator-style query iterator              :::::
# ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

def PREP_genquery_row_iterator ( columns, conditions, as_dict, callback ):

  column_idx = {}

  if type(columns) not in ( list, tuple ):
    if type(columns) is str:
      columns = map (lambda obj: obj.strip(), columns.split(","))
    else:
      raise bad_column_spec ( "Column argument '{!r}' should be column names " \
                               "as list or CSV string".format(columns))

  assert len(columns) , "Must select at least one column in genquery"

  try:
    column_idx . update(map(reversed,enumerate(columns)))
  except Exception as e:
    callback.writeLine("serverLog", "{!r}".format(e))
    raise

  ret_val = callback.msiMakeGenQuery(",".join(columns) , conditions , irods_types.GenQueryInp())
  genQueryInp = ret_val['arguments'][2]
  ret_val = callback.msiExecGenQuery(genQueryInp , irods_types.GenQueryOut())
  genQueryOut = ret_val['arguments'][1]
  continue_index_old = 1
  
  while continue_index_old > 0 and not is_CAT_NO_ROWS_FOUND(ret_val):

    for j in range(genQueryOut.rowCnt):
      row_as_list = [ genQueryOut.sqlResult[i].row(j) for i in range(len(column_idx)) ]
      if as_dict : 
        yield { k : row_as_list[v] for k,v in column_idx .items() }
      else:
        yield row_as_list

    continue_index_old = genQueryOut.continueInx

    if continue_index_old > 0 :
      ret_val = callback.msiGetMoreRows(genQueryInp , genQueryOut, continue_index_old)
      if not is_CAT_NO_ROWS_FOUND(ret_val):
        genQueryOut = ret_val['arguments'][1]
        continue_index_old2 = int( ret_val['arguments'][2] )
        continue_index_old = min(continue_index_old,int(continue_index_old2))

# ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
# ::: paged iterator returns a list of up to N rows each iteration :::
# ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

class PREP_genquery_row_list_iterator (object):

  def __init__(self, columns, conditions, as_dict, callback, N_rows_per_page = MAX_SQL_ROWS):

    self.rows_per_page = min (MAX_SQL_ROWS, max(1, N_rows_per_page))
    self.generator =  PREP_genquery_row_iterator (columns, conditions, as_dict, callback)

  def __iter__(self): return self
  def next(self): return self.__next__()

  def __next__(self): 
    return [ next(self.generator) for i in range(self.rows_per_page) ]

#       
#  Test the above iterators : call with (like_rhs_path , nrows_as_string)
#       

def test_PREP_genquery_iterator( rule_args , callback, rei ):
  import os
  cond_like_RHS = rule_args[0]
  coll_name = os.path.dirname(cond_like_RHS)
  data_obj_name_pattern = cond_like_RHS.split('/')[-1]

  requested_rowcount = str( rule_args[1] )

  conditions = ("COLL_NAME = '{0}' AND DATA_NAME like '{1}'").format(coll_name, data_obj_name_pattern )

  n = 0

  if len(requested_rowcount) > 0:
   
    rows_per_page = int(requested_rowcount)
    callback.writeLine ("serverLog", "#\n#\n__query: (%d) rows at a time__"%(rows_per_page,))
    for dObj_rows in PREP_genquery_row_list_iterator("DATA_NAME,DATA_SIZE" , conditions, True, callback,
                                                     N_rows_per_page = rows_per_page ):
      i = 0
      callback.writeLine ("serverLog", "__new_page_from_query__")
      for dObj in dObj_rows:
        callback.writeLine ("serverLog",
         "n={0},i={1} ;  name = {2} ; size = {3}" . format(n, i, dObj['DATA_NAME'], dObj['DATA_SIZE'] )
        )
        n += 1; i += 1

  else:

    callback.writeLine ("serverLog", "__gen_mode_return_all_rows_from_query__")
    for dObj in PREP_genquery_row_iterator("DATA_NAME,DATA_SIZE" , conditions, True, callback):

      callback.writeLine ("serverLog",
        "n = {0} ; name = {1} ; size = {2}" . format( n, dObj['DATA_NAME'], dObj['DATA_SIZE'] )
      )
      n += 1

