# CSV-Mapper
Enter data from a CSV file into a database

This Ruby program can read from a CSV(Comma Separated Values) file and store its headers and fields.

## Naming Conventions

### CSV Format

+ Names of headers can be enclosed in quotes
+ Header names are case insensitive and may contain multiple words
+ Field Data can be empty or blank
+ Whitespace is not allowed between data fields and a delimiter

### Table Name

+ File name has to be prefixed by the name of a database table followed by the `@` separator
+ If there is no separator, the table name will be the full file name
+ File name prefix is case insensitive

### Fields

+ A string with a number will be converted to either an integer or a float, depending on its value
+ If a value is missing at the end, it will be nil
+ If any value is missing, it will be set to nil

## Data Security

+ When an object is instantiated, a `SHA2` hash is created. The value of this hash will be stored in a row's `:hash` column
+ Before data is inserted, the existing hashes are checked against the hash of data to be added.
+ If the hash already exists, a `DuplicateData` Exception will be raised.
