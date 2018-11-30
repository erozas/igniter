class ContactsController < ApplicationController
  def new
    @contact_form = ContactForm.new
  end

  def create
    @contact_form = ContactForm.new(contact_params)
    if @contact_form.deliver!
      redirect_to contact_thank_you_path, notice: "Gracias por comunicarte con nosotros"
    else
      render :new, alert: "Hubo un problema al enviar el mensaje, inténtalo nuevamente"
    end
  end

  def thank_you
  end

  private
  def contact_params
    params.require(:contact_form).permit(:email, :full_name, :message).merge(user: current_user)
  end
end