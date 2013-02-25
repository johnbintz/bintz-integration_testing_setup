# capybara drivers for fast testing
#
# this one runs your entire test suite
require 'capybara/poltergeist'

# this one runs while you continuously test via guard
require 'persistent_selenium/driver'

# you can override the driver with the DRIVER environment variable
ENV['DRIVER'] ||= 'persistent_selenium'

# if PhantomJS is having problems clicking something, use dom_click
class Capybara::Node::Element
  def dom_click
    synchronize do
      begin
        trigger('click')
      rescue NotImplementedError, Capybara::NotSupportedByDriverError
        click
      end
    end
  end
end

