class Stock < ActiveRecord::Base
  belongs_to :company

  def self.refresh_stock
    Company.find(:all).each do |c|
      max_day = self.maximum('day', :conditions => "company_id = #{c.id}")
      if(max_day and max_day > Date.parse('2009-01-01'))
	self.load_historic_data(c, c.symbol, max_day + 1, Date.today)
      else
	self.load_historic_data(c, c.symbol, Date.parse('2009-01-01'), Date.today)
      end
      self.load_day_10_sum(c.id)
    end
  end

  def self.load_historic_data(company, symbol, start_date, end_date )
    stocks = []
    YahooFinance::get_HistoricalQuotes(symbol, start_date, end_date ) do |hq|
      stocks << Stock.new(:company => company, :day => hq.date, :open => hq.open, 
			:high => hq.high, :low => hq.low, :close => hq.close, 
			:volume => hq.volume, :adjusted_close => hq.adjClose)
    end
    stocks.reverse.each{|s| s.save}
  end

  def self.load_day_10_sum(company_id)
    stocks = self.find_all_by_company_id(company_id, :order => 'day').map{|s| s}
    size = stocks.length
    first_10_day = stocks[0, 10].inject(0.0) { |x,n| x+n.close}
    stocks[9..-1].each_with_index do |s,i|
      s.d10sum = first_10_day
      s.save
      first_10_day = first_10_day + stocks[i+10].close - stocks[i].close unless i + 10 >= size 
    end 
  end
end
