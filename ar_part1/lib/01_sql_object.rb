require 'byebug'
require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    unless @columns
      results = DBConnection.execute2(<<-SQL)
        SELECT *
        FROM #{table_name}
      SQL
      @columns = results.first.map {|result| result.to_sym}
    end 
    @columns
  end

  def self.finalize!
    columns.each do |attr_name|
      define_method(attr_name) {attributes[attr_name]}
      define_method("#{attr_name}=") {|value| attributes[attr_name] = value}
    end 
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    class_name_str = self.to_s.downcase + "s"
    @table_name ||= class_name_str
  end

  def self.all
    # ...
  end

  def self.parse_all(results)
    # ...
  end

  def self.find(id)
    # ...
  end

  def initialize(params = {})
    params.each do |attr_name, value|
      attr_name = attr_name.to_sym
      raise "unknown attribute '#{attr_name}'" unless self.class.columns.include?(attr_name)
      self.send("#{attr_name}=", value)
    end 
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    # ...
  end

  def insert
    # ...
  end

  def update
    # ...
  end

  def save
    # ...
  end
end
