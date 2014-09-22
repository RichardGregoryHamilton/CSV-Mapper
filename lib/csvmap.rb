require 'digest'

require_relative 'string'

class CSVMapper
  attr_reader :headers, :fields, :data_hash, :executed, :delimiter, :name

  @default_separator = "@"
  @default_delimiter = ","

  # Class methods are singleton methods on a Class Object
  class << self
    attr_accessor :default_separator, :default_delimiter
  end

  def initialize(file, options = {})
    raise ArgumentError, "Couldn't find file" unless File.exist?(file)
    raise Exception, "This is not a CSV file" unless valid_type?(file)

    @executed   = false
    @data_hash  = create_hash(@fields)
    @name       = table_name(file)
    @headers    = collect_headers(data)
    @fields     = extract_fields(data)

    @separator = CSVMapper.default_separator || options[:separator]
    @delimiter = CSVMapper.default_delimeter || options[:delimeter]

    data = prepare(File.open(file))

  end

  def valid_type?(file)
    file.end_with?('.csv')
  end

  def executed?
    @executed
  end

  def execute(connection, name = nil)
    begin
      raise Exception, "Data already copied to table #{@name}!" if @executed

      name ||= @name
      # Create a dataset
      dataset = connection[name]
      data    = fields_headers_hash { |row| row.merge(:hash => @data_hash) }

      raise Exception, "Data already in table. Abort!" if duplicate_data?(dataset)
      # Seed table with data
      data.map { |row| dataset.insert(row) }
      # Last Exception Raised
      @executed = true unless $!
    end
  end

  private

  def duplicate_data?(dataset)
    hash_data = dataset.map { |row| row[:hash] }
    hash_data.detect { |value| value == @data_hash }
  end

  def table_name(path)
    dir            = File.split(path)
    table          = file.split(@separator)
    raise Exception, "Couldn't find table" if blank?(table)

    # Split filename at a period
    table.split('.').gsub(/[-\s]+/, '_').downcase.to_sym if table.match(/\./)
  end

  def prepare(file)
    array = []
    file.each_line do |line|
      # Valid lines are identified by having some text with @delimiter in between.
      # Why use regex.source:
      # http://stackoverflow.com/questions/2648054/ruby-recursive-regex
      get_line = Regexp.new(".+#{@delimiter}.+")
      next unless line.match(/#{get_line.source}/)
      # Remove end of line char, split at @delimiter
      get_word = Regexp.new("(?<! )#{@delimiter}(?! )")
      result = line.chomp.split(/#{get_word.source}/).map { |word| word.gsub(/"/, '').strip }
        # Remove all escaped quotes (\"), strip leading and trailing whitespace
      array << result
    end
    array
  end

  def collect_headers(data)
    header = data[0]
    unless delimiter_found?(header)
      raise Exception, "Delimiter '#{@delimiter}' not found in header row."
    end
    header.map { |h| to_symbol(h) }
  end

  def delimiter_found?(data)
    data.nil? || data.size == 1
  end

  def extract_fields(data)
    data.drop(1).map do |row|
      values = row.map do |value|
        result = convert_to_number(value)
        generate_string(result)
      end
      values << nil unless @headers.size >= values.size

      message = "Forbidden delimiters in data fields detected."
      unless values.size == @headers.size
        raise Exception, message
      end
      values
    end
  end

  def blank?(word)
    word.empty? || word =~ /^\s+$/
  end

  def generate_string(value, new_value=nil)
    blank?(value.to_s) ? new_value : value
  end

  # This regex will convert delimeters to underscores and strings to symbols
  def to_symbol(word)
    word.gsub(/[-\s]+/, "_").downcase.to_sym
  end

  def convert_to_number(string)
    string.is_integer? ? string.to_i : string.is_float? ? string.to_f: string
  end

  # Creates a hash using the shorthand
  def to_hash(keys, values)
    Hash[*keys.zip(values).flatten]
  end

  def create_hash(data)
    Digest::SHA2.hexdigest(data.to_s)
  end

   def fields_headers_hash(&block)
    field_headers = @fields.reduce([]) do |acc, line|
      temp = to_hash(@headers, line)
      block_given? ? acc << yield(temp) : acc << temp
    end
    field_headers
  end

end
