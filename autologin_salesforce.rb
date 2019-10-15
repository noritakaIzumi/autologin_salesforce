# autologin_salesforce.rb v2.0

# selenium, chromedriver should be required.
# chromedriver should be installed (recommended: on your PATH).

require 'selenium-webdriver'
require 'logger'
require 'open3'
require './encrypt.rb'

# output in real time
$stdout.sync = true

# import login info (userName, password) to hash
def read_login_info
  out, err, status = Open3.capture3('ruby ./decrypt.rb')
  p err
  p status
  login_info_array = out.to_s.split("\n")
  login_info = {}
  login_info['userName'] = login_info_array[0]
  login_info['password'] = login_info_array[1]

  # return
  login_info
end

logger = Logger.new('./log/execute_logs')
logger.level = Logger::DEBUG

logger.unknown('main: start')

# receiving argument
clocking_option = if !ARGV[0].nil?
                    ARGV[0]
                  else
                    'leaving'
                  end
logger.info('received argument')

# import login info
login_info = read_login_info
pp login_info['userName']
logger.info('imported login information')
logger.debug('user name: ' << login_info['userName'])

# browser config
timeout_second = 15
options = Selenium::WebDriver::Chrome::Options.new
wait = Selenium::WebDriver::Wait.new(timeout: timeout_second)
# ignore chrome popup
options.prefs['profile.default_content_setting_values.notifications'] = 2
options.add_argument('start-maximized'); # fullscreen mode
# options.headless! # run on headless mode
logger.info('set browser config')

# open browser in chrome
driver = Selenium::WebDriver.for(:chrome, options: options)
logger.info('opened browser')

# access salesforce
driver.get('https://login.salesforce.com/')
logger.info('accessed salesforce')

wait.until { driver.find_element(:class, 'username').displayed? }
# input userName and password
driver.find_element(:class, 'username').send_keys login_info['userName']
logger.debug('input userName')
driver.find_element(:class, 'password').send_keys login_info['password']
logger.debug('input password')

# login
driver.find_element(:id, 'Login').click
logger.info('signed in')

xpath = '//*[@id="brandBand_1"]/div/div[1]/div/div/div/div/div[1]/div[1]/div[4]/article/div[2]/div/force-aloha-page/div/iframe'
# switch frame to clocking
tried = 0
begin
  tried += 1
  frame = driver.find_element(:xpath, xpath)
  driver.switch_to.frame(frame)
rescue Selenium::WebDriver::Error::NoSuchElementError
  logger.info('find_element retried: ' + tried.to_s)
  sleep 1
  retry if tried < timeout_second
  raise
end
logger.debug('focused on the clocking frame')

wait.until { driver.find_element(:id, 'btnStInput').displayed? }
wait.until { driver.find_element(:id, 'btnEtInput').displayed? }
wait.until { driver.find_element(:id, 'btnTstInput').displayed? }
wait.until { driver.find_element(:id, 'btnTetInput').displayed? }
# click button
case clocking_option
when 'arrival' then
  driver.find_element(:id, 'btnStInput').click
when 'leaving' then
  driver.find_element(:id, 'btnEtInput').click
when 'regular_arrival' then
  driver.find_element(:id, 'btnTstInput').click
when 'regular_leaving' then
  driver.find_element(:id, 'btnTetInput').click
else
  raise
end
logger.info('clocked (element: ' << clocking_option << ')')

sleep 1

# see clocked
driver.get('https://ap3.lightning.force.com/lightning/n/teamspirit__AtkWorkTimeTab')

sleep 8

# logout
driver.get('https://ap3.lightning.force.com/secur/logout.jsp')
logger.info('signed out')

# close browser
driver.quit
logger.info('closed browser')

logger.unknown('main: end')
