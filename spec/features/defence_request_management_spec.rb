require 'rails_helper'
require 'json'

RSpec.feature 'defence request creation' do

  context 'Create' do
    context 'as cso' do
      before :each do
        create_role_and_login('cso')
      end

      scenario 'Does not see the DSCC field on the Defence Request form' do
        visit root_path
        click_link 'New Defence Request'

        expect(page).not_to have_field('DSCC Number')
      end

      scenario 'Filling in form manually for own solicitor', js: true do
        visit root_path
        click_link 'New Defence Request'
        expect(page).to have_content ('New Defence Request')

        within '.new_defence_request' do
          choose 'Own'
          within '.details' do
            fill_in 'Solicitor name', with: 'Bob Smith'
            fill_in 'Solicitor firm', with: 'Acme Solicitors'
            fill_in 'Phone number', with: '0207 284 0000'
            fill_in 'Custody number', with: '#CUST-01234'
            fill_in 'Allegations', with: 'BadMurder'
            select('09', from: 'defence_request_time_of_arrival_4i')
            select('30', from: 'defence_request_time_of_arrival_5i')
          end

          within '.detainee' do
            fill_in 'Detainee name', with: 'Mannie Badder'
            choose 'Male'
            check 'defence_request[adult]'
            select('1976', from: 'defence_request_date_of_birth_1i')
            select('January', from: 'defence_request_date_of_birth_2i')
            select('1', from: 'defence_request_date_of_birth_3i')
            check 'defence_request[appropriate_adult]'
          end
          fill_in 'Comments', with: 'This is a very bad man. Send him down...'
          click_button 'Create Defence Request'
        end
        an_audit_should_exist_for_the_defence_request_creation
        expect(page).to have_content 'Bob Smith'
        expect(page).to have_content 'Defence Request successfully created'
      end

      scenario 'selecting own solicitor and choosing from search box', js: true do
        stub_solicitor_search_for_bob_smith
        visit root_path
        click_link 'New Defence Request'
        choose 'Own'
        fill_in 'q', with: "Bob Smith"

        find('.solicitor-search', match: :first).click
        expect(page).to have_content 'Bobson Smith'
        expect(page).to have_content 'Bobby Bob Smithson'

        click_link 'Bobson Smith'
        expect(page).to_not have_content 'Bobby Bob Smithson'
        expect(page).to have_field 'Solicitor name', with: 'Bobson Smith'
        expect(page).to have_field 'Solicitor firm', with: 'Kreiger LLC'
        expect(page).to have_field 'Phone number', with: '248.412.8095'
      end

      scenario 'performing multiple own solicitor searches', js: true do
        stub_solicitor_search_for_bob_smith
        stub_solicitor_search_for_barry_jones

        visit root_path
        click_link 'New Defence Request'
        choose 'Own'
        fill_in 'q', with: "Bob Smith"
        find('.solicitor-search', match: :first).click

        expect(page).to have_content 'Bobson Smith'

        fill_in 'q', with: "Barry Jones"
        click_button 'Search'

        find_link('Barry Jones').visible?
        expect(page).to_not have_content 'Bobson Smith'
      end

      scenario "searching for someone who doesn't exist", js: true do
        stub_solicitor_search_for_mystery_man

        visit root_path
        click_link 'New Defence Request'
        choose 'Own'
        fill_in 'q', with: "Mystery Man"
        find('.solicitor-search', match: :first).click

        expect(page).to have_content 'No results found'
      end

      scenario "using Close link to clear solicitor search results", js: true do
        stub_solicitor_search_for_bob_smith
        visit root_path
        click_link 'New Defence Request'
        choose 'Own'
        fill_in 'q', with: "Bob Smith"
        find('.solicitor-search', match: :first).click
        expect(page).to have_content 'Bobson Smith'

        within('.solicitor_results_list') do
        click_link("Close")
        end
        expect(page).not_to have_content 'Bobson Smith'
      end

      scenario "pressing ESC clears solicitor search results", js: true do
        stub_solicitor_search_for_bob_smith
        visit root_path
        click_link 'New Defence Request'
        choose 'Own'
        fill_in 'q', with: "Bob Smith"

        find('.solicitor-search', match: :first).click
        expect(page).to have_content 'Bobson Smith'

        page.execute_script("$('body').trigger($.Event(\"keydown\", { keyCode: 27 }))")
        expect(page).not_to have_content 'Bobson Smith'
      end

      scenario "toggling duty or own", js: true do
        stub_solicitor_search_for_bob_smith

        visit root_path
        click_link 'New Defence Request'
        choose 'Own'
        fill_in 'q', with: "Bob Smith"
        find('.solicitor-search', match: :first).click
        click_link 'Bobson Smith'
        choose 'Duty'

        expect(page).to have_field 'Solicitor name', with: "", disabled: true
        expect(page).to have_field 'Solicitor firm', with: "", disabled: true
        expect(page).to have_field 'Scheme', with: "No Scheme", disabled: false
        expect(page).to_not have_content 'Bobson Smith'

        choose 'Own'
        expect(page).to have_field 'Scheme', with: "No Scheme", disabled: true
        expect(page).to have_field 'q', with: ''
      end
    end

  end

  context 'close' do
    context 'as cso' do
      before :each do
        create_role_and_login('cso')
      end

      let!(:dr_created) { create(:defence_request) }

      scenario 'closing a DR from the dashboard' do
        visit root_path
        within "#defence_request_#{dr_created.id}" do
          click_link 'Close'
        end
        expect(page).to have_content('Close the Defence Request')
        click_button 'Close'
        expect(page).to have_content("feedback: can't be blank")
        expect(page).to have_content('Close the Defence Request')

        fill_in 'Feedback', with: 'I just cant take it any more...'
        click_button 'Close'
        expect(page).to have_content('Defence Request successfully closed')
        expect(page).to have_content('Custody Suite Officer Dashboard')
        dr_created.reload
        expect(dr_created.state).to eq 'closed'
      end
      scenario 'closing a DR from the edit' do
        visit root_path
        within "#defence_request_#{dr_created.id}" do
          click_link 'Edit'
        end
        click_link 'Close'
        expect(page).to have_content('Close the Defence Request')
        click_button 'Close'
        expect(page).to have_content("feedback: can't be blank")
        expect(page).to have_content('Close the Defence Request')

        fill_in 'Feedback', with: 'I just cant take it any more...'
        click_button 'Close'
        expect(page).to have_content('Defence Request successfully closed')
        expect(page).to have_content('Custody Suite Officer Dashboard')
        dr_created.reload
        expect(dr_created.state).to eq 'closed'
      end
    end
    context 'as cco' do
      before :each do
        create_role_and_login('cco')
      end

      let!(:dr_created) { create(:defence_request) }

      scenario 'closing a DR from the dashboard' do
        visit root_path
        within "#defence_request_#{dr_created.id}" do
          click_link 'Close'
        end
        expect(page).to have_content('Close the Defence Request')
        click_button 'Close'
        expect(page).to have_content("feedback: can't be blank")
        expect(page).to have_content('Close the Defence Request')

        fill_in 'Feedback', with: 'I just cant take it any more...'
        click_button 'Close'
        expect(page).to have_content('Defence Request successfully closed')
        expect(page).to have_content('Call Center Operative Dashboard')
        dr_created.reload
        expect(dr_created.state).to eq 'closed'
      end
    end
  end

  context 'Edit' do
    context 'as cso' do

      before :each do
        create_role_and_login('cso')
      end

      let!(:dr_1) { create(:defence_request) }

      scenario 'editing a DR' do
        visit root_path
        within "#defence_request_#{dr_1.id}" do
          click_link 'Edit'
        end
        expect(page).to have_content ('Edit Defence Request')

        within '.edit_defence_request' do
          fill_in 'Solicitor name', with: 'Dave Smith'
          fill_in 'Solicitor firm', with: 'Broken Solicitors'
          fill_in 'Phone number', with: '0207 284 9999'
          fill_in 'Custody number', with: '#CUST-9876'
          fill_in 'Allegations', with: 'BadMurder'
          select('10', from: 'defence_request_time_of_arrival_4i')
          select('00', from: 'defence_request_time_of_arrival_5i')


          fill_in 'Detainee name', with: 'Annie Nother'
          choose 'Female'
          uncheck 'defence_request[adult]'
          select('1986', from: 'defence_request_date_of_birth_1i')
          select('December', from: 'defence_request_date_of_birth_2i')
          select('31', from: 'defence_request_date_of_birth_3i')
          check 'defence_request[appropriate_adult]'
          fill_in 'Comments', with: 'I fought the law...'
          click_button 'Update Defence Request'
        end

        within "#defence_request_#{dr_1.id}" do
          expect(page).to have_content('Dave Smith')
          expect(page).to have_content('Broken Solicitors')
          expect(page).to have_content('02072849999')
          expect(page).to have_content('#CUST-9876')
          expect(page).to have_content('BadMurder')
          expect(page).to have_content('10:00')
          expect(page).to have_content('Annie')
          expect(page).to have_content('Nother')
        end
      end
    end

    context 'as cco' do
      before :each do
        create_role_and_login('cco')
      end

      let!(:dr) { create(:defence_request) }
      let!(:opened_dr) { create(:defence_request, :opened) }

      scenario 'must open a Defence Request before editing' do
        visit root_path
        within "#defence_request_#{dr.id}" do
          expect(page).not_to have_link('Edit')
          click_button 'Open'
        end

        within "#defence_request_#{dr.id}" do
          expect(page).to have_link('Edit')
          click_link 'Edit'
        end
        expect(current_path).to eq(edit_defence_request_path(dr))
      end

      scenario 'manually changing a solicitors details' do
        visit root_path
        within "#defence_request_#{opened_dr.id}" do
          click_link 'Edit'
        end

        fill_in 'Solicitor name', with: 'Henry Billy Bob'
        fill_in 'Solicitor firm', with: 'Cheap Skate Law'
        fill_in 'Phone number', with: '00112233445566'

        click_button 'Update Defence Request'
        expect(current_path).to eq(defence_requests_path)

        within "#defence_request_#{opened_dr.id}" do
          expect(page).to have_content 'Henry Billy Bob'
          expect(page).to have_content 'Cheap Skate Law'
          expect(page).to have_content '00112233445566'
        end
      end

      scenario 'editing a DR DSCC number (multiple times)' do
        visit root_path
        within "#defence_request_#{opened_dr.id}" do
          click_link 'Edit'
        end
        fill_in 'Dscc number', with: 'NUMBERWANG'
        click_button 'Update Defence Request'
        expect(page).to have_content 'Defence Request successfully updated'
        within "#defence_request_#{opened_dr.id}" do
          click_link 'Edit'
        end
        expect(page).to have_field 'Dscc number', with: 'NUMBERWANG'
        fill_in 'Dscc number', with: 'T-1000'
        click_button 'Update Defence Request'
        expect(page).to have_content 'Defence Request successfully updated'
      end
      ##############
      scenario 'I cant see an accepted button for created DR`s' do
        visit root_path
        within ".new_defence_requests" do
          expect(page).to_not have_button 'Accepted'
        end
      end

      scenario 'I cant see an accepted button for open DR`s without a DSCC number' do
        visit root_path
        within ".open_defence_requests" do
          expect(page).to_not have_button 'Accepted'
        end
      end

      scenario 'I see an accepted button for open DR`s with a DSCC number' do
        opened_dr.update(dscc_number: '012345')
        visit root_path
        within "#defence_request_#{opened_dr.id}" do
          click_button 'Accepted'
        end
        within ".accepted_defence_requests" do
          expect(page).to have_content(opened_dr.solicitor_name)
        end
      end

      scenario 'can choose update and mark accepted from the edit page' do
        opened_dr.update(dscc_number: '012345')
        visit root_path

        within "#defence_request_#{opened_dr.id}" do
          click_link 'Edit'
        end

        click_button 'Update and Accept'
        saop
        within ".accepted_defence_requests" do
          expect(page).to have_content(opened_dr.solicitor_name)
        end
      end


      xscenario 'can NOT mark a dr as "solicitor accepted" without solicitor details' do

      end
      xscenario 'can NOT mark a dr as "solicitor accepted" without DSCC number' do

      end

      xscenario 'solicitor receives a notification with a link to the case show' do

      end

      xscenario 'solicitor can see the show page of case they "own"' do

      end

      xscenario 'solicitor can sees the feedback page for a closed DR and "call Call Centre"' do

      end
    end
  end
end

def stub_solicitor_search_for_bob_smith
  body = File.open 'spec/fixtures/bob_smith_solicitor_search.json'
  stub_request(:post, "http://solicitor-search.herokuapp.com/search/?q=Bob%20Smith").
    to_return(body: body, status: 200)
end

def stub_solicitor_search_for_barry_jones
  body = File.open 'spec/fixtures/barry_jones_solicitor_search.json'
  stub_request(:post, "http://solicitor-search.herokuapp.com/search/?q=Barry%20Jones").
    to_return(body: body, status: 200)
end

def stub_solicitor_search_for_mystery_man
  body = {solicitors: [], firms: []}.to_json
  stub_request(:post, "http://solicitor-search.herokuapp.com/search/?q=Mystery%20Man").
    to_return(body: body, status: 200)
end

def an_audit_should_exist_for_the_defence_request_creation
  expect(DefenceRequest.first.audits.length).to eq 1
  audit = DefenceRequest.first.audits.first

  expect(audit.auditable_type).to eq 'DefenceRequest'
  expect(audit.action).to eq 'create'
end
