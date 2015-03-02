defmodule Sqlitex do
  def close(db) do
    :esqlite3.close(db)
  end

  def open(path) do
    :esqlite3.open(path)
  end

  def with_db(path, fun) do
    {:ok, db} = open(path)
    res = fun.(db)
    close(db)
    res
  end

  def exec(db, sql) do
    :esqlite3.exec(sql, db)
  end

  def query(db, sql) do
    do_query(db, sql, [], [])
  end
  def query(db, sql, [into: into]) do
    do_query(db, sql, [], into)
  end
  def query(db, sql, params) when is_list(params) do
    do_query(db, sql, params, [])
  end
  def query(db, sql, params, [into: into]) when is_list(params) do
    do_query(db, sql, params, into)
  end

  defp do_query(db, sql, params, into) do
    {:ok, statement} = :esqlite3.prepare(sql, db)
    :ok = :esqlite3.bind(statement, params)
    types = :esqlite3.column_types(statement)
    columns = :esqlite3.column_names(statement)
    rows = :esqlite3.fetchall(statement)
    return_rows_or_error(types, columns, rows, into)
  end

  defp return_rows_or_error({:error, _} = error, _, _, _), do: error
  defp return_rows_or_error(_, {:error, _} = error, _, _), do: error
  defp return_rows_or_error(_, _, {:error, _} = error, _), do: error
  defp return_rows_or_error(types, columns, rows, into) do
    Sqlitex.Row.from(Tuple.to_list(types), Tuple.to_list(columns), rows, into)
  end
end
