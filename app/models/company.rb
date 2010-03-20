class Company < ActiveRecord::Base
  has_many :stocks
#  has_many :functions

  validates_uniqueness_of :symbol
  attr_accessor :sdata, :formula, :method_name, :m_keys #TODO cleanup

  USER_FUNCTIONS = %w(open high low close volume field running_sum avrage min max save_results).sort
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

  def close(args)
    field(args.merge(:field => 'close'))
  end
  def open(args)
    field(args.merge(:field => 'open'))
  end
  def low(args)
    field(args.merge(:field => 'low'))
  end
  def high(args)
    field(args.merge(:field => 'high'))
  end
  def volume(args)
    field(args.merge(:field => 'volume'))
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

  def ema(args)
    # x day ema 
    #key_name = "_x_ema" 
    index = args[:index].to_i
    days = args[:days].to_i
    key_name = "_#{days}_ema".to_sym
    val = 0.0
    if @sdata[index][key_name]
      return @sdata[index][key_name]
    else
      if (index + 1) < days
      elsif (index + 1) == days
	val = avrage(:field => 'close', :days => days, :index => index) 
      else
	smoothing_constant = 2/(days + 1) 
	val = smoothing_constant * (close(:index => index) - field(:index => index - 1, :field => key_name)) 
		      + field(:index => index - 1, :field=> key_name)	
      end
      save_results(:value => val , :index => index, :key_name => key_name)
    end
    return val
  end

  def evaluate_function(args)
    index = args[:index].to_i
    key_name = args[:key_name].to_sym
    value = args[:value]
    day_ago_index = index - 1
    result = 1.0
    @sdata[index][key_name] = Hash.new
    @sdata[index][key_name][:pct_invested] = value 
    unless(day_ago_index < 0)
      result = @sdata[day_ago_index][key_name][:result] * day_factor(:index => index, :key_name => key_name)
    end
    @sdata[index][key_name][:result] = result 
    return result
  end

  def pct_change(args)
    index = args[:index].to_i 
    day_ago_index = index - 1
    return 0 if (day_ago_index < 0)
    return (close(:index => index) - close(:index => day_ago_index))/close(:index => day_ago_index)
  end

  def day_factor(args)
    key_name = args[:key_name].to_sym 
    index = args[:index].to_i
    day_ago_index = index - 1
    ris = 1 + (@sdata[day_ago_index][key_name][:pct_invested] * pct_change(:index => index)) 
    #puts "1 + #{@sdata[day_ago_index][key_name][:pct_invested]} * #{pct_change(:index => index)} = #{ris}"
    puts ris
    #return 1 + (@sdata[day_ago_index][key_name][:pct_invested] * pct_change(:index => index)) 
    return ris
  end

  def min(args)
    days_ago = (args[:days_ago] || 0).to_i
    field = args[:field].to_sym
    days = args[:days].to_i
    index = args[:index].to_i
    val = @sdata[index][field]
    unless(index < days_ago)
      start = (index - days_ago) < (days - 1) ? 0 : (index - days_ago) - (days - 1)
      start.upto(index - days_ago).each do |i|
	val = @sdata[i][field] if @sdata[i][field] < val
      end
    end 
    return val
  end

  def max(args)
    days_ago = (args[:days_ago] || 0).to_i
    field = args[:field].to_sym
    days = args[:days].to_i
    index = args[:index].to_i
    val = @sdata[index][field]
    unless (index < days_ago)
      start = (index - days_ago) < (days - 1) ? 0 : (index - days_ago) - (days - 1)
      start.upto(index - days_ago).each do |i|
	val = @sdata[i][field] if @sdata[i][field] > val
      end
    end
    return val
  end 

  def save_results(args)
    index = args[:index].to_i
    key_name = args[:key_name].to_sym
    value = args[:value]
    @sdata[index][key_name] = value
  end 

 #def evaluate_function(args)
 #  index = args[:index].to_i
 #  key_name = args[:key_name].to_sym
 #  new_key_name = "#{args[:key_name]}-eval".to_sym
 #  prediction = "" 
 #  size = @sdata.size
 #  if(index + 1 < size)
 #    if @sdata[index][key_name] == 1
 #      if(@sdata[index][:close] < @sdata[index + 1][:close])
 #        prediction = "Right"
 #      else
 #        prediction = "Wrong"
 #      end
 #    elsif @sdata[index][key_name] == -1
 #      if(@sdata[index][:close] > @sdata[index + 1][:close])
 #        prediction = "Right"
 #      else
 #        prediction = "Wrong"
 #      end
 #    else
 #      prediction = ""
 #    end
 #  end
 #  save_results(:index => index , :key_name => new_key_name, :value => prediction)
 #end
  
  def self.load_functions
    functions.each do |f|
      functions_str = "def #{f.name}\nload_sdata\n@sdata.each_with_index do |s,i|\n #{f.body}\nend\nend"
      self.class_eval(functions_str)
    end   
  end
  
  def self.functions
    Function.find_by_sql("SELECT * FROM `functions` WHERE editable = true order by name")
  end 

  def to_google_format(keys=nil) 
    data_google_format = Hash.new
    @sdata.each do |r|
      data_google_format[r[:day]] = Hash.new 
      data_google_format[r[:day]][:close] = r[:close] 
      keys.each do |k|
	if(r[k.to_sym].class == Hash)
	  data_google_format[r[:day]][k.to_sym] = r[k.to_sym][:result] 
	else
	  data_google_format[r[:day]][k.to_sym] = r[k.to_sym] 
	end
      end
    end
    data_google_format
  end

  def self.list_user_functions
    list = []
    list << USER_FUNCTIONS
    #functions.each{|f| list << f.name}   
    list << functions
    list
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


  def ppcc
    load_sdata
    @sdata.each_with_index do |s,i|
     #res = max(:index => i, :days => 10,:field => "close") - field(:field => 'close', :index => i)
     #     val = 0
     #     if res > 0
     #         val = 1	
     #     elsif res < 0
     #         val = -1
     #     else
     #         val = 0
     #end
     #evaluate_function(:index => i, :key_name => 'ppcc', :value => val)
#res = close(:days_ago => 1) - close(:index => i)
res = ema(:index => i, :days => 40) - close(:index => i)
val = 0
if res > 0
   val = 1
else
   val = -1
end

evaluate_function(:index => i, :key_name => 'pp6', :value => val)
    end
  end

private
   def this_method
     caller[0] =~ /`([^']*)'/ and $1
   end

end
