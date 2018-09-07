require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  
  def where(params)
    question_str = ""
    values = []
    params.each do |key, value|
      question_str += "#{key} = ? AND "
      values << value
    end 
    
    question_str = question_str[0...-4]
    # byebug
    results = DBConnection.execute(<<-SQL, *values)
      SELECT 
        *
      FROM 
        #{self.table_name}
      WHERE
        #{question_str}
    SQL
    self.parse_all(results)
  end
  
end

class SQLObject

  extend Searchable
  
end
