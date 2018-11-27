class User < ApplicationRecord
	validates :email, presence: true, uniqueness: { case_sensitive: false }
	validates_email_format_of :email, message: "no tiene un formato válido"
	validates :username, presence: true, uniqueness: { case_sensitive: false }
	
	scope :admin, -> { where(admin: true) }

	extend FriendlyId
	friendly_id :username, use: [:slugged, :finders]

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

  protected
  def self.find_record login
  	where(["username = :value OR email = :value", {value: login}]).first
  end
end