require 'yahoofinance'
require 'csv'
require 'fastercsv'
require 'gchart'

class CompaniesController < ApplicationController
  # GET /companies
  # GET /companies.xml
  def index
    @companies = Company.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @companies }
    end
  end

  # GET /companies/1
  # GET /companies/1.xml
  def show
    @company = Company.find(params[:id])
    @data= @company.prediction1
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @company }
    end
  end

  # GET /companies/new
  # GET /companies/new.xml
  def new
    @company = Company.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @company }
    end
  end

  # GET /companies/1/edit
  def edit
    @company = Company.find(params[:id])
  end

  # POST /companies
  # POST /companies.xml
  def create
    #@company = Company.new(params[:company])
    @company = Company.find_by_symbol(params[:company][:symbol])
    respond_to do |format|
      if(@company)
	  flash[:notice] = 'Company is already in the system.'
	  format.html { redirect_to(@company) }
      else
	  #format.html { redirect_to(:controller => 'companies' , :action => 'find', :params => params) }
	  format.html { redirect_to(params.merge!(:action => 'find'))}
      end
    end
#    respond_to do |format|
#      if @company.save
#        flash[:notice] = 'Company was successfully created.'
#        format.html { redirect_to(@company) }
#        format.xml  { render :xml => @company, :status => :created, :location => @company }
#      else
#        format.html { render :action => "new" }
#        format.xml  { render :xml => @company.errors, :status => :unprocessable_entity }
#      end
#    end
  end

  # PUT /companies/1
  # PUT /companies/1.xml
  def update
    @company = Company.find(params[:id])

    respond_to do |format|
      if @company.update_attributes(params[:company])
        flash[:notice] = 'Company was successfully updated.'
        format.html { redirect_to(@company) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @company.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /companies/1
  # DELETE /companies/1.xml
  def destroy
    @company = Company.find(params[:id])
    @company.destroy

    respond_to do |format|
      format.html { redirect_to(companies_url) }
      format.xml  { head :ok }
    end
  end

  def find
    name = ""
    @stats = ""
    if(params[:company] and params[:company][:symbol] and !params[:company][:symbol].empty?)
      quotes = YahooFinance::get_standard_quotes(params[:company][:symbol])
      stats = ""
      quotes.each do |symbol, qt|
      # puts "QUOTING: #{symbol}"
	  name = qt.name.to_s
	  @stats = qt.to_s
      end
    end
    if( name.downcase != params[:company][:symbol])
      @company = Company.new(:name => name, :symbol => params[:company][:symbol])
    else
        flash[:notice] = "no company found with symbol:#{params[:company][:symbol]}."
        redirect_to(:action => "new") 
    end
  end

  def add
    @company = Company.new(params[:company])
    respond_to do |format|
      if @company.save
	YahooFinance::get_HistoricalQuotes_days( params[:company][:symbol] , (Date.today - Date.parse('2005-01-01')).to_i ) do |hq|
	 # @company.stocks = [Stock.new(:day => hq.date, :open => hq.open, :high => hq.high, :low => hq.low, :close => hq.close, 
	#			    :volume => hq.volume, :adjusted_close => hq.adjClose)]
	  stock = Stock.new(:company => @company, :day => hq.date, :open => hq.open, :high => hq.high, :low => hq.low, :close => hq.close, 
				    :volume => hq.volume, :adjusted_close => hq.adjClose)
	  stock.save
	  #puts "#{hq.symbol},#{hq.date},#{hq.open},#{hq.high},#{hq.low}," + "#{hq.close},#{hq.volume},#{hq.adjClose}"
	end
        flash[:notice] = 'Company was successfully created.'
        format.html { redirect_to(@company) }
        format.xml  { render :xml => @company, :status => :created, :location => @company }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @company.errors, :status => :unprocessable_entity }
      end
    end
  end

  def list_functions 
    @id = params[:id]
    @functions = Company.list_user_functions
  end

  def exe_functions
    @id = params[:id]
    if params[:functions] and params[:functions].class == Array
      @functions = params[:functions]
    elsif  params[:functions] and params[:functions].class == String
      @functions = params[:functions].split(',')
    end
    @columns = []
    if @id and !@id.empty? and @id.to_i > 0
      Company.load_functions
      @company = Company.find(@id)
      @functions.each do |f|
	fun = Function.find(f.to_i)
	@columns << fun.name	
	#@columns << "#{fun.name}-eval"
	cmd = "@company.#{fun.name}"
	begin
	  eval(cmd)
	rescue Exception => e
	  msg = "<h1>Bad Function! Bad Function!</h1>"
	  msg = msg + e.message
	end
      end
      @data = @company.sdata
#puts y @data
      @data_in_google = @company.to_google_format(@columns)
      respond_to do |format|
	format.html
	format.csv do  
	  header = %w( Day Open High Low Volume Close) 
	  keys = [:day,:open,:high,:low,:volume,:close]
	  @columns.each do |c|
	    if(@data[0].keys.include?(c.to_sym))
	      header << c.capitalize 
	      keys << c.to_sym
	    end
	  end
	  export_csv(@data ,header,keys)
	end
      end
    else
      render :text => "<h1>Bad Data</h1>"
    end
  end

private
    def export_csv(data,header,keys)
      stream_csv do |csv|
	csv << header if header.size > 0
	data.each do |d|
	  csv << keys.map {|k| d[k] }
	end
      end
    end

    def stream_csv
      filename = params[:action] + ".csv"
      #this is required if you want this to work with IE        
      if request.env['HTTP_USER_AGENT'] =~ /msie/i
        headers['Pragma'] = 'public'
        headers["Content-type"] = "text/plain"
        headers['Cache-Control'] = 'no-cache, must-revalidate, post-check=0, pre-check=0'
        headers['Content-Disposition'] = "attachment; filename=\"#{filename}\""
        headers['Expires'] = "0"
      else
        headers["Content-Type"] ||= 'text/csv'
        headers["Content-Disposition"] = "attachment; filename=\"#{filename}\""
      end

      render :text => Proc.new { |response, output|
        csv = FasterCSV.new(output, :row_sep => "\r\n")
        yield csv
      }
    end
end
