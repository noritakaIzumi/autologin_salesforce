require './encrypt.rb'

# ------------------------------
#  Exceptions
# ------------------------------

class FileNotFoundError < StandardError
  attr_reader :message

  def initialize
    @message = 'File not found.'
  end
end


# ------------------------------
#  Functions
# ------------------------------

# import the following files
def import_files(directory_path)
  file_group = {}
  files = Dir.glob(directory_path + '\.[a-zA-Z0-9_]*')
  raise FileNotFoundError if files.empty?
  files.each do |file|
    key_name = file[/.*\.([a-zA-Z0-9_]*)$/, 1]
    # p key_name
    file_group[key_name] = IO.read(file)
  end

  # return
  file_group
end


# ------------------------------
#  Main Section
# ------------------------------

def main
  # read save file location
  Config.setSaveFileLocation(IO.read('./.saveFileLocation'))

  # import user_info and encrypted password
  user_info = import_files(Config.userInfoPath)
  puts user_info['userName']

  secret_code = import_files(Config.secretCodePath)

  decrypted_password = decryptPassword(secret_code)
  puts decrypted_password
end


# ------------------------------
#  Main Section
# ------------------------------

if $PROGRAM_NAME == __FILE__
  begin
    main
  rescue FileNotFoundError => exception
    sendErrorMessage(exception.message)
    $stderr << Text.space(1) << '(For Developers)' << Text.endl
    $stderr << Text.space(1) << exception.backtrace << Text.endl
    exit 1
  rescue Errno::ENOENT => exception
    sendErrorMessage('System call error occurred. Did you finish init settings?')
    $stderr << Text.space(1) << '(For Developers)' << Text.endl
    $stderr << Text.space(1) << exception.message << Text.endl
    $stderr << Text.space(1) << exception.backtrace << Text.endl
    exit 1
  rescue StandardError => exception
    sendErrorMessage('An error occurred.')
    $stderr << Text.space(1) << '(For Developers)' << Text.endl
    $stderr << Text.space(1) << exception.full_message << Text.endl
    $stderr << Text.space(1) << exception.backtrace << Text.endl
    exit 1
  end
end
