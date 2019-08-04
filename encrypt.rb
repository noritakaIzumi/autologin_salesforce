require 'openssl'
require 'io/console'
require 'fileutils'
require 'open3'

$stdout.sync = true

# ------------------------------
#  Class Definitions
# ------------------------------

# define formatter
class Text
  @@space = ' '
  @@list_indent = ' - '
  @@endl = "\n"
  @@error = ' *Error* '
  @@separator = '------------------------------' + @@endl

  # getter function
  def self.space(num)
    return @@space * num
  end

  def self.list_indent
    return @@list_indent
  end

  def self.endl
    return @@endl
  end

  def self.error
    return @@error
  end

  def self.separator
    return @@separator
  end
end


class Config # define config file path
  @@saveFileLocation = './'
  @@configFilePath = '.alsf/' # fixed
  @@secretCodeRelativePath = '.sc/' # fixed
  @@userInfoRelativePath = '.ui/' # fixed

  def self.setSaveFileLocation(location)
    @@saveFileLocation = location
    # if location == 'usersHome'
    #     # TODO: set home directory
    #     return
    # elsif location == 'application'
    #     @@saveFileLocation = './'
    #     return
    # end
  end

  # getter function
  def self.saveFileLocation
    return @@saveFileLocation
  end

  def self.secretCodePath
    return @@saveFileLocation + @@configFilePath + @@secretCodeRelativePath
  end

  def self.userInfoPath
    return @@saveFileLocation + @@configFilePath + @@userInfoRelativePath
  end
end


class User # user's information
  @@name = ''

  def self.setName(name)
    @@name = name
  end

  def self.getName()
    return @@name
  end
end


# ------------------------------
#  Exceptions
# ------------------------------

class DecryptionError < StandardError
  attr_accessor :message

  def initialize(message)
    @message = message
  end
end


# ------------------------------
#  Functions
# ------------------------------

# displaySubtitle
def displaySubtitle(subtitle)
  $stderr << "\e[32m"
  $stderr << Text.separator
  $stderr << Text.space(1) << subtitle << Text.endl
  $stderr << Text.separator
  $stderr << "\e[0m"
end


# send error message
def sendErrorMessage(message)
  $stderr << "\e[31m" + Text.error << message + "\e[0m" << Text.endl
end


# input user data
def inputUserInfo()
  # input user name
  while true do
    $stderr << Text.list_indent << 'User Name: '
    userName = $stdin.gets.chomp
    if userName == ''
      sendErrorMessage('Enter user name.')
      next
    else
      break
    end
  end

  # input password
  while true do
    $stderr << Text.list_indent << 'Password: '
    password1 = $stdin.noecho(&:gets).chomp
    $stderr << Text.endl
    if password1 == ''
      sendErrorMessage('Enter password.')
      next
    end
    $stderr << Text.list_indent << 'Password again: '
    password2 = $stdin.noecho(&:gets).chomp
    $stderr << Text.endl
    if password1 == password2
      password = password1
      # $stderr << 'Your input is: ' << password << Text.endl  # debug
      break
    else
      sendErrorMessage('Enter the same password as first.')
      next
    end
  end
  userInfo = {'userName' => userName, 'password' => password}
  return userInfo
end


# confirm your input
def confirmInput(userInfo) # userInfo['password'] is actually not used
  displaySubtitle('Confirm Your Input')
  $stderr << Text.list_indent << 'User Name: ' << userInfo['userName'] << Text.endl
  $stderr << Text.list_indent << 'Password: (invisible)' << Text.endl
  $stderr << Text.separator
  $stderr << Text.space(1) << 'Can I register the data above? [ (Y)es / (N)o / (R)einput ]: '
  while true do
    answer = $stdin.gets.chomp
    case answer.upcase
    when 'Y' then
      $stderr << Text.space(1) << 'Certainly.' << Text.endl
      break
    when 'N' then
      $stderr << Text.space(1) << 'Cancelled the registration.' << Text.endl
      exit
    when 'R' then
      $stderr << Text.space(1) << 'Please reinput.' << Text.endl
      $stderr << Text.separator
      userInfo = inputUserInfo()
      confirmInput(userInfo) # recursive
      break
    else
      $stderr << Text.error << 'Please Enter Y, N or R. [ (Y)es / (N)o / (R)einput ]: '
      next
    end
  end
end


# decrypt password
def decryptPassword(secretCode)
  decrypter = OpenSSL::Cipher.new("AES-256-CBC")
  decrypter.decrypt
  # 鍵とIVを設定する
  decrypter.key = secretCode['key']
  decrypter.iv = secretCode['iv']

  # decrypt
  decryptedPassword = decrypter.update(secretCode['encryptedPassword']) + decrypter.final
  return decryptedPassword
end


# mkdir if not exists the directory
def initDirectory(directoryPath)
  # does the directory exist?
  if !FileTest.exist?(directoryPath)
    FileUtils.mkdir_p(directoryPath, {:mode => 0755})
    # $stderr << FileUtils.exist?(directoryPath)
    # $stderr << Text.space(4) << "Directory successfully made: #{directoryPath}" << Text.endl
  else
    Dir.glob(directoryPath + '\.[a-zA-Z0-9_]*').each do |fileName|
      FileUtils.rm(fileName)
      # $stderr << Text.space(4) << "File deleted: #{fileName}." << Text.endl
    end
    # $stderr << Text.space(4) << "Directory successfully truncated: #{directoryPath}" << Text.endl
  end
end


# export user data
def exportConfigFiles(fileGroup, directoryPath)
  columns = fileGroup.keys
  columns.each do |column|
    filePath = directoryPath + '.' + column
    IO.write(filePath, fileGroup[column])
    # $stderr << Text.space(4) << "File successfully made : #{filePath}" << Text.endl
  end
end


# ------------------------------
#  Main Section
# ------------------------------

def main(retryCount = 0)
  displaySubtitle('Enter Your Information')
  userInfo = inputUserInfo()
  confirmInput(userInfo)

  displaySubtitle('Save File Location')
  begin
    $stderr << Text.space(1) << 'You save the data to the directory of '
    $stderr << '[ Your (H)ome / (C)urrent Directory / (P)arent Directory ]: '
    location = $stdin.gets.chomp
    case location.upcase
    when 'H' then
      # ------------------------------
      # this will be removed if home directory defined
      raise 'This option is not supported yet.'
      # ------------------------------
      # Config.setSaveFileLocation('./')
    when 'C' then
      Config.setSaveFileLocation('./')
    when 'P' then
      Config.setSaveFileLocation('../')
    when '' then
      raise 'Enter option.'
    else
      raise 'Called wrong option.'
    end
  rescue => exception
    sendErrorMessage(exception.message)
    retry
  end

  $stderr << Text.space(1) << 'Now I am verifying the data...'
  # register user name
  User.setName(userInfo['userName'])

  # generate encrypter
  encrypter = OpenSSL::Cipher.new("AES-256-CBC")
  encrypter.encrypt

  # 鍵とIV(Initialize Vector)を PKCS#5 に従ってパスワードと salt から生成する
  passphrase = OpenSSL::Random.random_bytes(65536)
  salt = OpenSSL::Random.random_bytes(65536)
  key_iv = OpenSSL::PKCS5.pbkdf2_hmac_sha1(passphrase, salt, 1200000, encrypter.key_len + encrypter.iv_len)
  key = key_iv[0, encrypter.key_len]
  iv = key_iv[encrypter.key_len, encrypter.iv_len]
  # 鍵とIVを設定する
  encrypter.key = key
  encrypter.iv = iv

  # encrypt
  encryptedPassword = encrypter.update(userInfo['password']) + encrypter.final
  # $stderr << Text.endl << 'encrypted password: ' << encryptedPassword << Text.endl  # debug

  # file groups (later used in exportConfigFiles)
  userInfo = {
      'userName' => User.getName(),
      # 'saveFileLocation' => Config.saveFileLocation,
  }
  secretCode = {
      'encryptedPassword' => encryptedPassword,
      'key' => key,
      'iv' => iv,
  }

  decryptedPassword = decryptPassword(secretCode)
  $stderr << Text.space(1) << 'finished.' << Text.endl
  # $stderr << 'Your input is: ' << decryptedPassword << Text.endl  # debug

  $stderr << Text.space(1) << 'Checking existence of directory...' << Text.endl
  initDirectory(Config.userInfoPath)
  initDirectory(Config.secretCodePath)

  $stderr << Text.space(1) << 'Exporting config files...' << Text.endl
  exportConfigFiles(userInfo, Config.userInfoPath)
  exportConfigFiles(secretCode, Config.secretCodePath)
  IO.write('./.saveFileLocation', Config.saveFileLocation)

  $stderr << Text.space(1) << 'Checking exported data...' << Text.endl

  sleep 1
  out, err, status = Open3.capture3("ruby ./decrypt.rb")
  if err != ""
    puts err
  end
  if status.exitstatus != 0
    raise DecryptionError.new('Check failed.')
  end

  $stderr << Text.space(1) << 'Setup successfully completed!' << Text.endl
end


# ------------------------------
#  Default Action
# ------------------------------

if __FILE__ == $0
  begin
    main
  rescue Interrupt => exception
    $stderr << Text.endl
    sendErrorMessage('Setup cancelled by keyboard interrupt.')
  rescue DecryptionError => exception
    sendErrorMessage(exception.message)
    # p exception.message
    $stderr << Text.space(1) << '(For Developers)' << Text.endl
    $stderr << Text.space(1) << exception.backtrace << Text.endl
  rescue Errno::EBADF => exception
    $stderr << Text.endl
    sendErrorMessage(exception.message)
    $stderr << Text.space(1) << '[Windows] If you execute in Git Bash, '
    $stderr << Text.space(1) << 'try a command "winpty ruby encrypt.rb" or execute in Command Prompt/PowerShell.' << Text.endl
    $stderr << Text.space(1) << '[Mac] Yokuwakaranaidesu.' << Text.endl
    $stderr << Text.separator
    $stderr << Text.space(1) << '(For Developers)' << Text.endl
    $stderr << Text.space(1) << exception.backtrace << Text.endl
  rescue => exception
    sendErrorMessage('An unexpected error occurred.')
    $stderr << Text.separator
    $stderr << Text.space(1) << '(For Developers)' << Text.endl
    $stderr << Text.space(1) << exception.full_message << Text.endl
    $stderr << Text.space(1) << exception.backtrace << Text.endl
  ensure
    $stderr << Text.separator
    $stderr << Text.space(1) << 'Setup ended.' << Text.endl
  end
end
