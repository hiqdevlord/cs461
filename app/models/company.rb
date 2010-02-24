class Company < ActiveRecord::Base
  has_many :stocks
  validates_uniqueness_of :symbol
  attr_accessor :sdata, :formula, :method_name, :m_keys

  def load_sdata 
    if !@sdata or @sdata.empty?
      @sdata = Array.new 
      stocks = self.stocks
      stocks.each_with_index do |s,i|
	@sdata[i] = {:day => s.day, :open => s.open, :high => s.high, :low => s.low, :close => s.close, :volume => s.volume }
      end
    end
  end

  def field(args)
    days_ago = (args[:days_ago] || 0).to_i
    field = args[:field].to_sym
    index = args[:index]
    if(index < days_ago)
      return 0
    else
      return @sdata[index - days_ago][field]
    end
  end

  def running_sum(args)
    days_ago = (args[:days_ago] || 0).to_i
    field = args[:field].to_sym
    days = args[:days].to_i
    index = args[:index]
    sum = 0.0
    unless ((index - days_ago ) < (days - 1)) 
      ((index - days_ago) - (days - 1)).upto(index - days_ago) do |i|
	sum += @sdata[i][field] 
      end 
    end	
    return sum
  end

  def avrage(args)
    days_ago = (args[:days_ago] || 0).to_i
    running_sum(args)/args[:days].to_i
  end

  def min(args)
    days_ago = (args[:days_ago] || 0).to_i
    field = args[:field].to_sym
    days = args[:days].to_i
    index = args[:index].to_i
    val = @sdata[0][field]
    if(index < days_ago)
      return val 
    else
      start = (index - days_ago) < (days - 1) ? 0 : (index - days_ago) - (days - 1)
      start.upto(index - days_ago).each do |i|
	val = @sdata[i][field] if val < @sdta[i][field]
      end
    end 
  end

  def max(args)
    days_ago = (args[:days_ago] || 0).to_i
    field = args[:field].to_sym
    days = args[:days].to_i
    index = args[:index].to_i
    val = @sdata[0][field]
    if(index < days_ago)
      return val 
    else
      start = (index - days_ago) < (days - 1) ? 0 : (index - days_ago) - (days - 1)
      start.upto(index - days_ago).each do |i|
	val = @sdata[i][field] if val > @sdta[i][field]
      end
    end
  end

  def check_keys(keys)
    keys.each do |k|
     if @sdata[0].has_key?(k.to_sym)
      #TODO case to be handled 
     else
       get_caller(k)	
     end
    end
  end

  def get_caller(key)
    parts = key.split("_")  
    if parts.size == 1
      #
    elsif parts.size == 4
      field(:field => parts[0], :days => parts[1].to_i)
    #elsif parts[1] =~ /\d+/
    end
  end
  
  def code_formula(args=nil)
    formula = args[:formula] || "close - close_10_days_ago"
    keys = []
    formula.gsub(/\b(\S+)\b/){ keys << "#{$1.to_s}"}
    @m_keys = keys#.map{|k| "'#{k}'"}
    formula.gsub!(/\b(\S+)\b/){"@sdata[i][:#{$1}]"}
    # TODO wait for the "parse_formula" method to be ready formula = parse_formula(formula)
    method_name = args[:method_name]
    key_name = args[:method_name].to_sym 
    method_str = "def #{method_name}(args=nil);" +
		  "@sdata.each_with_index do |s,i|;" +
		  "ris = #{formula};" +
		  "if(ris> 0);" +
		    "@sdata[i][:#{key_name}] = 1;" + 
		  "elsif(ris < 0);" +
		    "@sdata[i][:#{key_name}] = -1;" + 
		  "else;" + 
		    "@sdata[i][:#{key_name}] = 0;" + 
		  "end;" + 
		"end;" +
	      "end"
    @formula = method_str 
  end

  def load_m
    load_sdata
    check_keys @m_keys
    self.class_eval @formula
  end

  def save_results(args)
    index = args[:index].to_i
    key_name = args[:key_name].to_sym
    value = args[:value]
    @sdata[index][key_name] = value
  end

  def pp1
    load_sdata
    @sdata.each_with_index do |s,i|
      ris = field(:field => 'close', :days_ago => 10, :index => i) - field(:field => 'close', :index => i)
      val = 0
      if(ris > 0)
	val = 1
      elsif(ris < 0)
	val = -1
      else
	val = 0
      end
      save_results(:index => i, :key_name => 'pp1', :value => val) 
    end
  end

  def prediction1
    @sdata = Array.new 
    stocks = self.stocks.reverse
    stocks.each_with_index do |s,i|
      @sdata[i] = {:day => s.day, :open => s.open, :high => s.high, :low => s.low, :close => s.close, :volume => s.volume, 
		    :obv => 0, :obv_p => 0,
		    :pmo => 0, :pmo_p => 0,
		    :rsi => 0, :rsi_p => 0,
		    :k => 0, :k_p => 0,
		    :ma10 => 0, :ma10_p =>0}
      if i >= 10
	#PMO Start
	pmo = s.close - @sdata[i-10][:close]
	pmo_p = pmo > 0 ? 1 : -1
	@sdata[i][:pmo] = pmo
	@sdata[i][:pmo_p] = pmo_p
	#PMO End
	#RSI Start
	upClose = 0
	downClose = 0
	0.upto(8) do |t|
	  if(@sdata[i - t][:close] > @sdata[i - (t+1)][:close])
	    upClose = upClose + @sdata[i - t][:close]
	  elsif(@sdata[i - t][:close] < @sdata[i - (t+1)][:close])
	    downClose = downClose + @sdata[i - t][:close]
	  end
	end
	rsi = 100 - 100 * ( 1 + (upClose / downClose))
	rsi_p = rsi > 50 ? 1 : -1
	@sdata[i][:rsi] = rsi
	@sdata[i][:rsi_p] = rsi_p
	#RSI End
	#MA10 Start
	sum10 = 0
	1.upto(11) do |t|
	  sum10 = sum10 + @sdata[i - t][:close]
	end
	yma = sum10 / 10
	tma = (sum10 + @sdata[i][:close] - @sdata[i - 11][:close])/10
	@sdata[i][:ma10] = tma
	@sdata[i][:ma10_p] = (tma > yma) ? 1 : -1
	#MA10 End
      end
      if i >=  5
	#Start K
	ln = [@sdata[i][:low],@sdata[i - 1][:low],@sdata[i - 2][:low], @sdata[i - 3][:low], @sdata[i - 4][:low]].min
	hn = [@sdata[i][:high],@sdata[i - 1][:high],@sdata[i - 2][:high], @sdata[i - 3][:high], @sdata[i - 4][:high]].max
	k = 100 * (@sdata[i][:close] - ln)/(hn - ln)
	if(k > 80)
	  @sdata[i][:k_p] = 1
	elsif(k < 20)
	  @sdata[i][:k_p] = -1
	end  
	#End K
      end
      if i > 0
	# OBV Start
	obv = 0
	obv_p = 0
	if (s.close < @sdata[i-1][:close])
	  obv = obv - s.volume
	elsif(s.close >= @sdata[i-1][:close])
	  obv = obv + s.volume
	end
	if(obv > @sdata[i-1][:obv])
	  obv_p = 1
	elsif(obv < @sdata[i-1][:obv])
	  obv_p = -1
	end
	@sdata[i][:obv] = obv
	@sdata[i][:obv_p] = obv_p	
	#OBV End
      end
    end
    @sdata
  end

#@nee = 'testing'
#@dd =  "def #{@nee}(x); 10 + x; end"
#self.class_eval do 
#  @dd
#end
  

  def p1 (args)
    load_sdata
    check_keys(args[:keys]) 
    key_name = this_method.to_sym    
    @sdata.each_with_index do |s,i|
      dif = @sdata[i][:close] - @sdata[i][:close_10_days_ago]
      if(dif > 0)
	@sdata[i][key_name] = 1
      elsif(dif < 0)
	@sdata[i][key_name] = -1
      else
	@sdata[i][key_name] = 0 
      end	
    end
  end
  self.class_eval do
    def number(x)
      10 + x
    end
  end
private
   def this_method
     caller[0] =~ /`([^']*)'/ and $1
   end

end
