class Function < ActiveRecord::Base
  validates_presence_of :name, :body 
  validates_uniqueness_of :name
  validates_exclusion_of :name , :in => Company.instance_methods
end
