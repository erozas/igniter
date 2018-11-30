class ContactMailer < ApplicationMailer
  def contact_email(email, full_name, reason, message)
    @email = email
    @full_name = full_name
    @message = message

    if Rails.application.credentials.app.present?
    	receiver = Rails.application.credentials.app['email']
    else
    	receiver = "contacto@#{Rails.application.class.parent.to_s.downcase}.com"
    end
    
    mail(to: receiver,
         subject: 'Contacto desde el formulario',
         from: "#{@full_name} <#{@email}>")
  end
end