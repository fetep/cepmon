module CEPMon
  class Config
    attr_reader :amqp
    attr_reader :statements

    public
    def initialize(cfg_file="cepmon.cfg")
      @amqp = {}
      @statements = {}

      instance_eval(File.read(cfg_file))
    end # def initialize

    private
    def verify_present(params, required)
      required.each do |key|
        return false unless params.member?(key)
      end
      return true
    end # def verify_present

    private
    def statement(params)
      required = [:name, :epl]
      if not verify_present(params, required)
        raise "required parameters (#{required.inspect}) missing from statement: #{params.inspect}"
      end

      name = params[:name]
      epl = params[:epl]
      if @statements.member?(name)
        raise "duplicate statement name #{name}"
      end

      @statements[name] = params
    end # def statement

    private
    def amqp_input(params)
      @amqp = params
    end # def amqp_input
  end # class Config
end # module CEPMon
