require 'active_support/core_ext/object/try'
require 'active_support/inflector'
require_relative './db_connection.rb'

class AssocParams

  def other_class
    @other_class.constantize
  end

  def other_table
    other_class.table_name
  end

end

class HasManyAssocParams < AssocParams
  attr_reader :name, :primary_key, :foreign_key

  def initialize(name, params)
    @name = name
    if params[:class_name].nil?
      @other_class = name.to_s.singularize.camelize
    else
      @other_class = params[:class_name]
    end
    @primary_key = params[:primary_key] || 'id'
    @foreign_key = params[:foreign_key] || "#{@other_class}_id".to_sym
  end

end


class BelongsToAssocParams < AssocParams
  attr_reader :name, :primary_key, :foreign_key

  def initialize(name, params)
    @name = name
    if params[:class_name].nil?
      @other_class = name.to_s.camelize
    else
      @other_class = params[:class_name]
    end
    @primary_key = params[:primary_key] || 'id'
    @foreign_key = params[:foreign_key] || "#{name}_id".to_sym
  end

end

module Associatable
  def assoc_params
    @assoc_params ||= @assoc_params = {}
  end

  def belongs_to(name, params = {})
    define_method(name) do
      self.class.assoc_params[name] = BelongsToAssocParams.new(name, params)
      target_params = self.class.assoc_params[name]

      results = DBConnection.execute(<<-SQL, self.send(target_params.foreign_key))
        SELECT * FROM #{target_params.other_table}
        WHERE #{target_params.primary_key} = ?
      SQL
      target_params.other_class.parse_all(results)
    end
  end

  def has_many(name, params = {})
    define_method(name) do
      self.class.assoc_params[name] = HasManyAssocParams.new(name, params)
      target_params = self.class.assoc_params[name]

      results = DBConnection.execute(<<-SQL, target_params.primary_key)
        SELECT * FROM #{target_params.other_table}
        WHERE #{target_params.foreign_key} = ?
      SQL
      target_params.other_class.parse_all(results)
    end
  end

  def has_one_through(name, assoc1, assoc2)
    define_method(name) do
      neighbor_parameters = self.class.assoc_params[assoc1]
      target_parameters = neighbor_parameters.other_class.assoc_params[assoc2]

      p target_parameters.foreign_key

      query = <<-SQL
        SELECT a.* FROM #{target_parameters.other_table} a
        JOIN #{neighbor_parameters.other_table} b
        ON b.#{target_parameters.foreign_key} = a.#{target_parameters.primary_key}
        WHERE b.#{neighbor_parameters.primary_key} = #{self.send(neighbor_parameters.foreign_key)}
      SQL

      p query

      results = DBConnection.execute(<<-SQL, self.send(neighbor_parameters.foreign_key))
        SELECT a.* FROM #{target_parameters.other_table} a
        JOIN #{neighbor_parameters.other_table} b
        ON b.#{target_parameters.foreign_key} = a.#{target_parameters.primary_key}
        WHERE b.#{neighbor_parameters.primary_key} = ?
      SQL
      target_parameters.other_class.parse_all(results)
    end
  end
end
