class RefreshStocksTask < Rooster::Task
  
  @tags = ['RefreshStocks'] # CUSTOMIZE:  add additional tags here
  
  define_schedule do |s|
    s.every "1d", :first_at => Chronic.parse("2:00am"), :tags => @tags do  # CUSTOMIZE:  reference http://github.com/jmettraux/rufus-scheduler/tree/master
      begin
        log "#{self.name} starting at #{Time.now.to_s(:db)}"
        ActiveRecord::Base.connection.reconnect!
	Stock.refresh_stock
        ###
        # CUSTOMIZE:  Your code here (e.g. User.send_due_invoices!)
        ###
        
      ensure
        log "#{self.name} completed at #{Time.now.to_s(:db)}"
        ActiveRecord::Base.connection_pool.release_connection
      end
    end
  end
end
