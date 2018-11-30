class ContactForm
  include ActiveModel::Model

  attr_accessor :email, :full_name, :message, :user

  validates :email,     presence: true
  validates :full_name, presence: true
  validates :message,   presence: true

  def deliver!
    if valid?
      ContactMailer.contact_email(email, full_name, message).deliver_later
    end
  end
end