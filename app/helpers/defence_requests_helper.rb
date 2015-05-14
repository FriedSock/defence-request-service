module DefenceRequestsHelper

  def solicitor_id(solicitor_hash)
    "solicitor-#{solicitor_hash['id']}"
  end

  def data_chooser_setup(date_to_edit)
    today = Date.today
    tomorrow = today + 1
    initial_date = (date_to_edit || today).to_date
    initial_date_type = if initial_date == today
                          "today"
                        elsif initial_date == tomorrow
                          "tomorrow"
                        elsif initial_date < today
                          "in_past"
                        else
                          "after_tomorrow"
                        end
    [today, tomorrow, initial_date, initial_date_type]
  end

  def detainee_address(defence_request)
    attributes = %i[house_name address_1 address_2 city county postcode]
    fields = attributes.map { |f| defence_request.send(f) }.compact

    if fields.blank?
      t("address_not_given")
    else
      fields.join(", ")
    end
  end
end
