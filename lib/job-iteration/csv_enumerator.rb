# frozen_string_literal: true

module JobIteration
  # CsvEnumerator makes it possible to write an Iteration job
  # that uses CSV file as a collection to Iterate.
  # @example
  #   def build_enumerator(cursor:)
  #     csv = CSV.open('tmp/files', { converters: :integer, headers: true })
  #     JobIteration::CsvEnumerator.new(csv).rows(cursor: cursor)
  #   end
  #
  #   def each_iteration(row)
  #     ...
  #   end
  class CsvEnumerator
    # Constructs CsvEnumerator instance based on a CSV file.
    # @param [CSV] csv An instance of CSV object
    # @return [JobIteration::CsvEnumerator]
    # @example
    #   csv = CSV.open('tmp/files', { converters: :integer, headers: true })
    #   JobIteration::CsvEnumerator.new(csv).rows(cursor: cursor)
    def initialize(csv)
      unless csv.instance_of?(CSV)
        raise ArgumentError, "CsvEnumerator.new takes CSV object"
      end

      @csv = csv
    end

    # Constructs a enumerator on CSV rows
    # @return [Enumerator] Enumerator instance
    def rows(cursor:)
      @csv.lazy
        .each_with_index
        .drop(cursor.to_i)
        .to_enum { count_rows_in_file }
    end

    # Constructs a enumerator on batches of CSV rows
    # @return [Enumerator] Enumerator instance
    def batches(batch_size:, cursor:)
      @csv.lazy
        .each_slice(batch_size)
        .each_with_index
        .drop(cursor.to_i)
        .to_enum { (count_rows_in_file.to_f / batch_size).ceil }
    end

    private

    def count_rows_in_file
      begin
        filepath = @csv.path
      rescue NoMethodError
        return
      end

      count = %x(wc -l < #{filepath}).strip.to_i
      count -= 1 if @csv.headers
      count
    end
  end
end
