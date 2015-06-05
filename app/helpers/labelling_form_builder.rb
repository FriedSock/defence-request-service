class LabellingFormBuilder < ActionView::Helpers::FormBuilder

  include ActionView::Helpers::CaptureHelper
  include ActionView::Helpers::TagHelper
  include ActionView::Context

  def form_group(attribute, options={}, &block)
    classes = ["form-group"]
    classes << options[:class] if options[:class].present?
    classes << "error" if error_for?(attribute)

    content_tag(:div, class: classes.join(" "), id: id_for(attribute)) do
      label = label(attribute, label_content_for(attribute, nil))
      label + capture(&block)
    end
  end

  def text_field_input(attribute, options={}, &block)
    text_input attribute, :text_field, options, &block
  end

  # Defaults to "Yes" "No" labels on radio inputs
  def radio_button_fieldset(attribute, legend, options={})
    translation_key = translation_key(attribute)
    raise "TBD: #{translation_key} #{options[:choice]}" if options[:choice].is_a?(Hash)

    virtual_pageview = options[:data] ? options[:data].delete("virtual-pageview") : nil
    input_class = options.delete(:input_class)

    options[:id] = id_for(attribute) unless id_for(attribute).blank?

    options[:choice] ||= [ "Yes", "No" ]

    options_class = options[:class][/inline/] ? "inline" : "options"

    data_reverse = options.delete(:toggle_fieldset) ? " data-reverse=\"true\"" : ""

    classes = ["form-group"]
    classes << "error" if error_for?(attribute)
    content_tag(:div, class: classes) do
      fieldset_tag attribute, legend, options do
        content_tag(:div, class: options_class) do
          radios = options[:choice].map do |choice|
            radio_button_row(attribute, choice, virtual_pageview, input_class)
          end
          radios.join("\n").html_safe
        end
      end
    end
  end

  def error_for?(attribute)
    attribute_errors = error_message_for(attribute)
    attribute_errors && !attribute_errors.empty?
  end

  def error_span(attribute, options={})
    content_tag(:span, class: "error-message", id: options[:id]) do
      error_message_for(attribute)[0]
    end
  end

  def error_id_for(attribute)
    field_id = "#{parent_id}_#{attribute}".squeeze("_")
    "#{field_id}_error"
  end

  def fieldset_tag(attribute, legend_text, options = {}, &block)
    fieldset = tag(:fieldset, options_for_fieldset(options), true)

    fieldset.safe_concat legend_for(attribute, legend_text, options) unless legend_text.blank?

    fieldset.concat(capture(&block)) if block_given?
    fieldset.safe_concat("</fieldset>")
  end

  private

  def parent_id
    @object_name.to_s.tr("[]","_").squeeze("_")
  end

  def parent_key
    @template.parent_key(parent_id)
  end

  def translation_key(attribute, options={})
    @template.translation_key attribute, options.merge(parent_key: parent_key)
  end

  def id_for(attribute, default=nil)
    error_for?(attribute) ? error_id_for(attribute) : (default || "")
  end

  def error_message_for(symbol)
    @object.errors.messages[symbol]
  end

  def options_for_fieldset(options)
    options.delete(:class) if options[:class].blank?
    options = {}.merge(options)
    options.delete(:hint)
    options.delete(:choice)
    options
  end

  def legend_for(attribute, legend_text, options)
    label = label_content_for(attribute, legend_text, hint: options[:hint])
    content_tag(:legend, label)
  end

  def label_content_for(attribute, label, options={})
    translation_key = translation_key(attribute, suffix: "label")
    translation = I18n.t(translation_key)
    if translation[/translation missing/]
      label ||= attribute.to_s.humanize
    else
      label = translation
    end
    label = ["<span class=\"form-label-bold\">#{label}</span>"]
    hint = hint_span(options)
    label << hint if hint
    label << error_span(attribute, options) if error_for?(attribute)

    label.join(" ").html_safe
  end

  def hint_span(options)
    options[:hint] ? "<span class='hint block'>#{options[:hint]}</span>".html_safe : nil
  end

  def radio_button_row(attribute, choice, virtual_pageview, input_class)
    translation_key = translation_key(attribute, suffix: choice)

    translation = I18n.t(translation_key)
    translation = I18n.t(choice.downcase) if translation[/translation missing/]

    raise "translation missing: #{translation_key}" if translation[/translation missing/]

    translation = translation_key if translation[/translation missing/]
    label = translation unless translation[/translation missing/]

    options = {}
    options.merge!(class: input_class) if input_class

    input = radio_button(attribute, choice, options)

    id = input[/id="([^"]+)"/,1]

    content_tag(:div, class: "option") do
      content_tag(:label, for: id) do
        [
          input,
          label
        ].compact.join("\n").html_safe
      end
    end
  end

  def text_input(attribute, input, options, &block)
    classes = ["form-group"]
    classes << options[:class] if options[:class].present?
    classes << "error" if error_for?(attribute)

    content_tag(:div, class: classes.join(" "), id: id_for(attribute)) do
      input_options = options.merge(class: options[:input_class], data: options[:input_data])
      input_options.delete(:label)
      input_options.delete(:input_class)
      input_options.delete(:input_data)

      contents = labelled_input(attribute, input, input_options, options[:label])
      contents += capture(&block) if block_given?
      contents
    end
  end

  def labelled_input(attribute, input, input_options, label=nil)
    label = label(attribute, label_content_for(attribute, label))

    if max_length = max_length(attribute)
      input_options.merge!(maxlength: max_length)
    end

    value = send(input, attribute, input_options)

    [ label, value ].join("\n").html_safe
  end

  def max_length(attribute)
    if validator = validators(attribute).detect{|x| x.is_a?(ActiveModel::Validations::LengthValidator)}
      validator.options[:maximum]
    end
  end

  def validators(attribute)
    @object.class.validators_on(attribute)
  end

end
