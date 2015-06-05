require "rails_helper"

class MockTemplate
  include ActionView::Helpers::FormHelper
  include ActionView::Helpers::FormOptionsHelper

  attr_accessor :output_buffer

  def translation_key(attribute, options={})
    "defence_request.gender"
  end
end

RSpec::Matchers.define :only_show_errors_inside do |expected, opts|
  opts = opts || {}
  opts = { error_css: "span.error" }.merge(opts)
  match do |actual|
    doc                             = Nokogiri::HTML(actual)
    @count_of_all_error_messages    = doc.css(opts[:error_css]).count
    count_of_correct_error_messages = doc.css(opts[:error_css]).count{ |elem| elem.parent.name == expected.to_s }
    @total_failures                 = @count_of_all_error_messages - count_of_correct_error_messages
    (@total_failures == 0) && (@count_of_all_error_messages > 0)
  end
  failure_message do |actual|
    if @total_failures > 0
      "expected #{pluralize(@count_of_all_error_messages, "error")} to appear inside a #{expected} tag. #{@total_failures} did not."
    elsif @count_of_all_error_messages <= 0
      "expected error messages, but did not find any."
    end
  end
end

RSpec::Matchers.define :contain_css_selectors do |expected_elements|
  match do |actual|
    doc     = Nokogiri::HTML(actual)
    @errors = []
    [expected_elements].flatten.each do |element|
      @errors << "expected `#{element}`, but did not find it" if doc.css(element).blank?
    end
    @errors.empty?
  end
  failure_message do |actual|
    "generated form had the following errors: " + @errors.compact.join(", ")
  end
end

RSpec::describe "LabellingFormBuilder", type: :helper do

  let(:defence_request)   { double("model", class: double("class").as_null_object).as_null_object }
  let(:template) { MockTemplate.new }
  let(:form)     { LabellingFormBuilder.new("defence_request", defence_request, template, { }) }

  describe "#radio_button_field_set" do
    let(:fieldset) {
      form.radio_button_fieldset :gender,
      "Gender",
      class: "radio",
      choice: [ "male", "female", "transgender", "unspecified" ]
    }

    before do
      messages = double("error_messages", messages: { gender: ["can't be blank"] })
      allow(defence_request).to receive(:errors) { messages }
    end

    it "outputs the correct form element" do
      expect(fieldset).to contain_css_selectors(
        "fieldset.radio",
        "fieldset legend",
        "input[type=radio, id=gender-male]",
        "input[type=radio, id=gender-female]",
        "input[type=radio, id=gender-transgender]",
        "input[type=radio, id=gender-unspecified]"
      )
    end

    it "shows errors inside the legend" do
      expect(fieldset).to only_show_errors_inside(:legend, error_css: "legend span.error-message")
    end
  end
end