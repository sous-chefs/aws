require 'chefspec'
require 'chefspec/berkshelf'

RSpec.configure do |config|
  config.color = true
end

at_exit { ChefSpec::Coverage.report! }
