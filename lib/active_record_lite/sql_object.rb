require_relative './associatable'
require_relative './db_connection'
require_relative './mass_object'
require_relative './searchable'

class SQLObject < MassObject

  extend Searchable
  extend Associatable

  def self.set_table_name(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name
  end

  def self.all
    query_for_all_rows = <<-SQL
      SELECT * FROM #{@table_name};
    SQL
    all_rows = DBConnection.execute(query_for_all_rows)
    all_rows.each do |row|
      new(row)
    end
  end

  def self.find(id)
    query_for_a_row = <<-SQL
      SELECT * FROM #{@table_name}
      WHERE #{@table_name}.id = ?;
    SQL
    found_row = DBConnection.execute(query_for_a_row, id)
    new(found_row.first)
  end

  def save
    @id.nil? ? create : update
  end

  private

  def create
    attribute_names = self.class.attributes.join(", ")
    attributes_count = self.class.attributes.count
    rows_placeholders = (['?'] * attributes_count).join(", ")
    values_to_insert = self.class.attributes.map { |attr_name| send(attr_name) }
    save_row_query = <<-SQL
      INSERT INTO #{self.class.table_name} (#{attribute_names})
    VALUES (#{rows_placeholders})
    SQL
    DBConnection.execute(save_row_query, *values_to_insert)
    row_id = DBConnection.last_insert_row_id
    @id = row_id
  end

  def update
    attribute_names = self.class.attributes.join(", ")
    attributes_count = self.class.attributes.count
    values_to_set = self.class.attributes.map { |attr_name| self.send("#{attr_name}") }
    update_row_query = <<-SQL
      UPDATE #{self.class.table_name}
      SET #{attribute_values}
      WHERE id = ?
    SQL
    DBConnection.execute(update_row_query, *values_to_set, @id)
  end


  def attribute_values
    self.class.attributes.map { |attr_name| "#{attr_name} = ?" }.join(", ")
  end
end
