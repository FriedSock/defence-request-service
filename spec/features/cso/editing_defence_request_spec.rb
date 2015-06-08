require "rails_helper"

RSpec.feature "Custody Suite Officers editing defence requests" do

  specify "can edit detainee details" do
    login_and_view_defence_request

    within ".detainee-details" do
      click_link "Change this"
    end

    fill_in "defence_request_detainee_address", with: "Changed address"
    click_button "Save changes"

    expect(page).to have_content("Changed address")
  end

  specify "can edit detention details" do
    login_and_view_defence_request

    click_link "Case details"
    within ".case-details" do
      click_link "Change this"
    end

    fill_in "defence_request_custody_number", with: "New number"
    click_button "Save changes"

    click_link "Case details"
    expect(page).to have_content("New number")
  end

  def login_and_view_defence_request
    create :defence_request, :queued

    login_as_cso

    click_link "❭"
  end
end