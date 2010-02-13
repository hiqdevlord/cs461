require 'yahoofinance'

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
#render :text => 'hi'
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
	YahooFinance::get_HistoricalQuotes_days( params[:company][:symbol] , (Date.today - Date.parse('2009-01-01')).to_i ) do |hq|
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
end
