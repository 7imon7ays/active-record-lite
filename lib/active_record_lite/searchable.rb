require_relative './db_connection'

module Searchable
  def where(params)
    where_clause = params.keys.map { |key| "#{key} = ?" }.join(' and ')
    values = params.values
    find_query = <<-SQL
      SELECT * FROM #{self.table_name}
      WHERE #{where_clause}
    SQL
    found_row = DBConnection.execute(find_query, *values)
    new(found_row.first)
  end
end