module MoSQL
  class Writers < Hash
    def initialize(schema, ns, options = {})
      @schema = schema
      @ns = ns
      @flush = options[:flush]
      @batch = options[:batch]

      add(@schema[:meta][:table])

      @schema[:related].each do |table, columns|
        add(table, table)
      end
    end

    def [](table = @schema[:meta][:table])
      super
    end

    def add(table, suffix=nil)
      scoped_ns = [@ns, suffix].compact.join(".")
      self[table] = WriteQueue.new(table, scoped_ns, @batch, @flush)
    end

    def flush
      values.each(&:flush)
    end

    def each_table(&block)
      keys.each(&block)
    end

    class WriteQueue < Array
      attr_reader :total

      def initialize(table, ns, capacity, flush)
        @table = table
        @ns = ns
        @capacity = capacity
        @flush = flush
        @total = 0
      end

      def <<(obj)
        super
        @total += 1
        flush if length >= @capacity
      end

      def flush
        @flush.call(@table, @ns, self) if length > 0
        self.clear
      end
    end
  end
end
