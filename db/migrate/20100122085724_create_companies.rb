class CreateStocks < ActiveRecord::Migration
  def self.up
    create_table :companies do |t|
      t.string :name
      t.string :symbol

      t.timestamps
    end
  end

  def self.down
    drop_table :companies 
  end
end
