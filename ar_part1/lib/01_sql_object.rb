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
    results = DBConnection.execute(<<-SQL)
      SELECT *
      FROM #{table_name}
    SQL
    parse_all(results)
  end

  def self.parse_all(results)
    results.map {|result| self.new(result)}
  end

  def self.find(id)
    results = DBConnection.execute(<<-SQL, id)
      SELECT *
      FROM #{table_name}
      WHERE id = ?
    SQL
    parse_all(results).first
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
    columns.map {|attr_name| @attributes[attr_name]}  
  end
  
  def insert
    into_str = "#{self.class.table_name} (#{columns.join(", ")})"
    
    q_marks = ""
    attribute_values.length.times {q_marks << "?,"}
    q_marks = "(#{q_marks[0..-2]})" 
    
    results = DBConnection.execute(<<-SQL, *attribute_values)
      INSERT INTO 
        #{into_str}
      VALUES
        #{q_marks}
    SQL
    self.id = DBConnection.last_insert_row_id
  end

  def update
    set_str = ""
    @attributes.each do |col_name, value|
      value = "'#{value}'" if value.is_a?(String)
      set_str << "#{col_name} = #{value}, "  
    end 
    set_str = set_str[0..-3]
    # byebug
    DBConnection.execute(<<-SQL, self.id)
      UPDATE
        #{self.class.table_name}
      SET
        #{set_str}
      WHERE 
        id = ?
    SQL
  end

  def save
    if id 
      update
    else 
      insert 
    end 
  end
  
  private 
  
  def columns
    self.class.columns
  end 
end
