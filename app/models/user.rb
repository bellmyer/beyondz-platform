# The purpose of this is to handle user data.

class User < ActiveRecord::Base
  def new
  end

  def create
  end

  # Returns the user ID of the matching user if the credentials
  # pass, otherwise, raises a LoginException
  def login(email, passw)
    user = User.find_by email: email
    if user == nil
      raise LoginException.new("Incorrect email address")
    else
      parts = user.password.split("-")
      salt = parts[0]
      if parts[1] == User.hashPassword(salt, passw)
        return user.id
      else
        raise LoginException.new("Incorrect password")
      end
    end
  end

  # Prepares a reset token for the account with the given
  # email address and sends an email with the given link.
  def self.forgotPassword(email, reset_link)
    user = User.find_by email: email
    if user == nil
      raise LoginException.new("Incorrect email address")
    else
      # create a random string of characters to use as the token
      user.reset_token = randomString()
      user.reset_expiration = Time.now + 15.minutes
      user.save();

      reset_link += "?token=#{user.reset_token}&id=#{user.id}"
      Notifications.forgot_password(email, user.name, reset_link).deliver
    end
  end

  def randomString
    return (0...8).map { (65 + rand(26)).chr }.join
  end

  # Changes the user's password. Don't forget to call save afterward
  def changePassword(newPassword, confirmPassword)
    if(newPassword != confirmPassword)
      raise "passwords don't match"
    end

    # Randomization for password hash
    salt = randomString()
    self.password = salt + "-" + User.hashPassword(salt, newPassword)
  end

  def self.hashPassword(salt, passw)
    return Digest::SHA1.hexdigest("#{salt}#{passw}")
  end
end

class LoginException < Exception
  def initialize(type)
    @type = type
  end

  def type
    @type
  end
end
