module ForemanSetup
  module SetupHelper
    def wizard_header(current, *args)
      content_tag(:ul,:class=>"wizard") do
        step=1
        content = nil
        args.each do |arg|
          step_content = content_tag(:li,(content_tag(:span,step,:class=>"badge" +" #{'badge-inverse' if step==current}")+arg).html_safe, :class=>"#{'active' if step==current}")
          step == 1 ? content = step_content : content += step_content
          step += 1
        end
        content
      end
    end
  end
end
