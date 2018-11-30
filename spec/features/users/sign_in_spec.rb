require "rails_helper"
require "spec_helper"

RSpec.describe User, type: :model do
  let!(:user) { FactoryBot.create(:user) }

  feature "signs in" do
    scenario "with valid username and password" do
      visit new_user_session_path
      fill_in :user_login, with: user.username
      fill_in :user_password, with: user.password

      click_button "Ingresa"
      expect(page).to have_text(user.username)
    end

    scenario "with valid email and password" do
      visit new_user_session_path
      fill_in :user_login, with: user.email
      fill_in :user_password, with: user.password

      click_button "Ingresa"
      expect(page).to have_text(user.username)
    end

    scenario "without a password" do
      visit new_user_session_path
      fill_in :user_login, with: user.email
      fill_in :user_password, with: ""

      click_button "Ingresa"
      expect(page).to have_content "Cuenta o contraseña inválidos"
    end

    scenario "with incorrect password" do
      visit new_user_session_path
      fill_in :user_login, with: user.email
      fill_in :user_password, with: "sanataForEver"

      click_button "Ingresa"
      expect(page).to have_content "Cuenta o contraseña inválidos"
    end

    scenario "with incorrect email" do
      visit new_user_session_path
      fill_in :user_login, with: "someUnexistentemail@email.com"
      fill_in :user_password, with: user.password

      click_button "Ingresa"
      expect(page).to have_content "Cuenta o contraseña inválidos"
    end

    scenario "with an invalid email format" do
      visit new_user_session_path
      fill_in :user_login, with: "exequiel@hotmail"
      fill_in :user_password, with: user.password

      click_button "Ingresa"
      expect(page).to have_content "Cuenta o contraseña inválidos"
    end
  end
end
