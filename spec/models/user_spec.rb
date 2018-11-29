require 'rails_helper'

RSpec.describe User, type: :model do
	let!(:user) { FactoryBot.create(:user) }
 
	it "has a valid factory" do
		expect(user).to be_valid 
	end

	it "is not an admin by default" do
		expect(user.admin).to be_falsey
	end

	it "should generate a slug when created" do
		expect(user.slug).not_to be_nil
	end

 	it { should validate_presence_of(:email) }
 	it { should validate_uniqueness_of(:email).ignoring_case_sensitivity }

 	it { should validate_presence_of(:username) }
 	it { should validate_uniqueness_of(:username) }


end
