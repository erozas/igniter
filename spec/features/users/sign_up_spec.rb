require "rails_helper"

RSpec.describe User, type: :model do
  let!(:user) { FactoryBot.create(:user) }

  feature "signs up" do
    scenario "with valid credentials" do
      valid_sign_up
      expect(page).to have_content("¡Bienvenido! Has creado tu cuenta correctamente")
    end

    scenario "without a username" do
      visit root_path
      click_link "Registrate"

      fill_in :user_email, with: "exequiel98@gmail.com"
      fill_in :user_password, with: "specter99"

      click_button "Registrate"
      expect(page).to have_content("Nombre de usuario no puede estar en blanco")
    end

    scenario "with a username that's already registered" do
      visit root_path
      click_link "Registrate"

      fill_in :user_username, with: user.username
      fill_in :user_email,    with: "unique83@uniqueemail.com"
      fill_in :user_password, with: user.password
      click_button "Registrate"

      expect(page).to have_content("Nombre de usuario ya ha sido tomado")
    end

    scenario "with an email that's already registered" do
      visit root_path
      click_link "Registrate"

      fill_in :user_username, with: "riverkpo"
      fill_in :user_email,    with: user.email
      fill_in :user_password, with: user.password
      click_button "Registrate"

      expect(page).to have_content("Correo electrónico ya ha sido tomado")
    end

    scenario "with an invalid email format" do
      visit root_path
      click_link "Registrate"

      fill_in :user_username, with: "erozas"
      fill_in :user_email,    with: "exequiel@hotmail"
      fill_in :user_password, with: "specter99"

      click_button "Registrate"
      expect(page).to have_content("no tiene un formato válido")
    end
  end

  private
  def valid_sign_up
    visit root_path
    click_link "Registrate"
    fill_in :user_username, with: "erozas"
    fill_in :user_email, with: "exequiel98@gmail.com"
    fill_in :user_password, with: "specter99"

    click_button "Registrate"
  end
end
