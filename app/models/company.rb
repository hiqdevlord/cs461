class Company < ActiveRecord::Base
  has_many :stocks
  validates_uniqueness_of :symbol

  def predictions 
    @data = Array.new 
    stocks = self.stocks
    stocks.each_with_index do |s,i|
      @data[i] = {:day => s.day, :open => s.open, :high => s.high, :low => s.low, :close => s.close, :volume => s.volume }
    end
  end

  def running_sum(*args)
    days = args[:days] rescue 10
    field = args[:field] rescue 'close'
    key_name = "#{days}_days_sum_on_#{field}".to_sym
    field = field.to_sym
    sum = 0.0
    @data.each_with_index do |s,i|
      if(i < (days - 1))
	sum += s[field]  
	@data[i][key_name] = 0 
      else
	@data[i][key_name] = sum += s[field]
	sum = sum - @data[i - days][field]
      end
    end 
  end

  def field(*args)
    field = args[:field]
    days = args[:days]
    @data.each_with_index do |s,i|
      #set up the data field
    end
  end

  #def stocks_with_prediction1
  def prediction1
    @data = Array.new 
    stocks = self.stocks.reverse
    stocks.each_with_index do |s,i|
      @data[i] = {:day => s.day, :open => s.open, :high => s.high, :low => s.low, :close => s.close, :volume => s.volume, 
		    :obv => 0, :obv_p => 0,
		    :pmo => 0, :pmo_p => 0,
		    :rsi => 0, :rsi_p => 0,
		    :k => 0, :k_p => 0,
		    :ma10 => 0, :ma10_p =>0}
      if i >= 10
	#PMO Start
	pmo = s.close - @data[i-10][:close]
	pmo_p = pmo > 0 ? 1 : -1
	@data[i][:pmo] = pmo
	@data[i][:pmo_p] = pmo_p
	#PMO End
	#RSI Start
	upClose = 0
	downClose = 0
	0.upto(8) do |t|
	  if(@data[i - t][:close] > @data[i - (t+1)][:close])
	    upClose = upClose + @data[i - t][:close]
	  elsif(@data[i - t][:close] < @data[i - (t+1)][:close])
	    downClose = downClose + @data[i - t][:close]
	  end
	end
	rsi = 100 - 100 * ( 1 + (upClose / downClose))
	rsi_p = rsi > 50 ? 1 : -1
	@data[i][:rsi] = rsi
	@data[i][:rsi_p] = rsi_p
	#RSI End
	#MA10 Start
	sum10 = 0
	1.upto(11) do |t|
	  sum10 = sum10 + @data[i - t][:close]
	end
	yma = sum10 / 10
	tma = (sum10 + @data[i][:close] - @data[i - 11][:close])/10
	@data[i][:ma10] = tma
	@data[i][:ma10_p] = (tma > yma) ? 1 : -1
	#MA10 End
      end
      if i >=  5
	#Start K
	ln = [@data[i][:low],@data[i - 1][:low],@data[i - 2][:low], @data[i - 3][:low], @data[i - 4][:low]].min
	hn = [@data[i][:high],@data[i - 1][:high],@data[i - 2][:high], @data[i - 3][:high], @data[i - 4][:high]].max
	k = 100 * (@data[i][:close] - ln)/(hn - ln)
	if(k > 80)
	  @data[i][:k_p] = 1
	elsif(k < 20)
	  @data[i][:k_p] = -1
	end  
	#End K
      end
      if i > 0
	# OBV Start
	obv = 0
	obv_p = 0
	if (s.close < @data[i-1][:close])
	  obv = obv - s.volume
	elsif(s.close >= @data[i-1][:close])
	  obv = obv + s.volume
	end
	if(obv > @data[i-1][:obv])
	  obv_p = 1
	elsif(obv < @data[i-1][:obv])
	  obv_p = -1
	end
	@data[i][:obv] = obv
	@data[i][:obv_p] = obv_p	
	#OBV End
      end
    end
    @data
  end

  
 # self.class_eval do
 #   def number(x)
 #     10 + x
 #   end
 # end
end
