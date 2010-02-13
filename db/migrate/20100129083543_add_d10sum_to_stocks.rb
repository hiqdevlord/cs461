class AddD10sumToStocks < ActiveRecord::Migration
  def self.up
    add_column :stocks, :d10sum, :decimal, :precision => 8, :scale => 2, :default => 0.0
  end

  def self.down
    remove_column :stocks, :d10sum
  end
end
