//= require jquery
//= require jasmine-jquery
//= require disable_checker

fixtureHtml = (isChecked) ->
  if isChecked
    checked = 'checked="checked"'
  else
    checked = ""

  $("""
  <body>
  <div class="form-group">
    <label for="defence_request_detainee_name">Full Name</label>
    <input data-disable-when="defence_request_detainee_name_not_given"
           class="text-field text-field-wide not-given-check"
           name="defence_request[detainee_name]" id="defence_request_detainee_name"
           type="text">
    <label class="form-checkbox" for="defence_request_detainee_name_not_given">
      <input name="defence_request[detainee_name_not_given]" value="0" type="hidden">
      <input value="1" name="defence_request[detainee_name_not_given]" id="defence_request_detainee_name_not_given" type="checkbox" #{checked}>
      not given</label>
  </div>
  </body>
  """)

fixtureSetup = (element, context) ->
  $(document.body).append(element)

  context.disableCheckbox = $("#defence_request_detainee_name_not_given")
  context.inputToDisable = $("[data-disable-when]").eq(0)
  context.disableChecker = new window.DisableChecker(context.inputToDisable)

describe "DisableChecker", ->
  element = null

  afterEach ->
    element.remove()
    element = null

  describe "when checkbox not checked", ->
    beforeEach ->
      element = fixtureHtml(false)
      fixtureSetup(element, this)

    describe "after initialization", ->
      it "leaves input enabled", ->
        expect(@inputToDisable).not.toBeDisabled()

    describe "checkbox is checked", ->
      it "disables input", ->
        @disableCheckbox.trigger("click")
        expect(@inputToDisable).toBeDisabled()

      it "removes text from input", ->
        @inputToDisable.val("some text")
        expect(@inputToDisable.val()).toEqual "some text"

        @disableCheckbox.trigger("click")
        expect(@inputToDisable.val()).toEqual ""

    describe "checkbox is checked then unchecked", ->
      it "enables input", ->
        @disableCheckbox.trigger("click")
        @disableCheckbox.trigger("click")
        expect(@inputToDisable).not.toBeDisabled()

  describe "when checkbox checked", ->
    describe "after initialization", ->
      it "disables input", ->
        element = fixtureHtml(true)
        fixtureSetup(element, this)
        expect(@inputToDisable).toBeDisabled()
