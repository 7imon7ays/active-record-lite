require 'active_support/core_ext/object/try'
require 'active_support/inflector'
require_relative './db_connection.rb'

class AssocParams
  def other_class
  end

  def other_table
  end
end

class BelongsToAssocParams < AssocParams
  def initialize(name, params)
    @name = name
    @params = params
  end

  def type
  end
end

class HasManyAssocParams < AssocParams
  def initialize(name, params, self_class)
  end

  def type
  end
end

module Associatable
  def assoc_params
    @assoc_params || @assoc_params = {}
  end

  def belongs_to(name, params = {})
    @assoc_params[name] = BelongsToAssocParams.new(name, params)

    define_method(name) do
      if params[:classname].nil?
        other_class = name.to_s.camelize.constantize
      else
        other_class = params[:classname].constantize
      end
      other_table_name = other_class.table_name
      primary_key = params[:primary_key] || @id
      foreign_key = params[:foreign_key] || "#{name}_id".to_sym

      results = DBConnection.execute(<<-SQL, self.send(foreign_key))
        SELECT * FROM #{other_table_name}
        WHERE #{primary_key} = ?
      SQL
      other_class.parse_all(results)
    end
  end

  def has_many(name, params = {})
    define_method(name) do
      if params[:classname].nil?
        other_class = name.to_s.singularize.camelize.constantize
      else
        other_class = params[:classname].constantize
      end
      other_table_name = other_class.table_name
      primary_key = params[:primary_key] || @id
      foreign_key = params[:foreign_key] || "#{name}_id".to_sym

      results = DBConnection.execute(<<-SQL, primary_key)
        SELECT * FROM #{other_table_name}
        WHERE #{other_table_name}.#{foreign_key} = ?
      SQL
      other_class.parse_all(results)
    end
  end

  def has_one_through(name, assoc1, assoc2)

  end
end
