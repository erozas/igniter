class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :masqueradable, :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable, :omniauthable
  has_many :services

  def self.find_first_by_auth_conditions(warden_conditions)
    conditions = warden_conditions.dup
    if login = conditions.delete(:login)
      where(conditions).where(["lower(username) = :value OR lower(email) = :value", { :value => login.downcase }]).first
    else
      if conditions[:username].nil?
        where(conditions).first
      else
        where(username: conditions[:username]).first
      end
    end
  end

  def omniauth_by?(provider)
    provider == provider
  end

  def login=(login)
    @login = login
  end

  def login
    @login || username || email
  end

  def remember_me
    (super == nil) ? '1' : super
  end
  
  protected
  def self.find_record login
    where(["username = :value OR email = :value", {value: login}]).first
  end
end
