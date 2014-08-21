Given(/^I just entered my baby's information and he was born today$/) do
   # TODO: Login?
   launch_app app_path
end


Then(/^I should be on the "(.*?)" screen$/) do |name|
    sleep 1
    check_element_exists "view:'UIView' marked:'#{name}'"
    sleep 1
end

When(/^I tap the button "(.*?)"$/) do |name|
  touch "view:'UIButton' marked:'#{name}'"
end

Then(/^I tap the text field "(.*?)" and type "(.*?)"$/) do |field, text|
    text_field_selector =  "view:'UITextFieldLabel' marked:'#{field}' parent view:'UITextField'"
    check_element_exists( text_field_selector )
    touch( text_field_selector )
    sleep 1
    type_into_keyboard(text)
end

Then(/^I tap the control "(.*?)"$/) do |name|
    touch "view:'UIControl' marked:'#{name}'"
end

Then(/^I select the month "(.*?)" and the day "(.*?)" and the year "(.*?)" in the date picker$/) do |month , day, year|
      touch("view marked:'#{month}'")
      touch("view marked:'#{day}'")
      touch("view marked:'#{year}'")
end

Then(/^I tap the navigation button "(.*?)"$/) do |name|
   selector = "view:'UINavigationButton' marked:'#{name}'"

   if !element_exists(selector)
    selector = "view:'UINavigationItemButtonView' marked:'#{name}'"
   end
   sleep 1
   touch selector
end

Then(/^I tap the back navigation button$/) do
   sleep 1
   touch "view:'_UINavigationBarBackIndicatorView' marked:'Back'"
end


Then(/^I should see the text "(.*?)"$/) do |text|
  list_of_text_contents = frankly_map( "view:'UITextView'", "text" )
    list_of_text_contents.should have(1).item
    list_of_text_contents.first.should include(text)
end

Then(/^I wait for the progress indicator to finish$/) do
  selector = "view:'MBProgressHUD'"
  wait_for_element_to_exist selector
  wait_for_element_to_not_exist selector
end



