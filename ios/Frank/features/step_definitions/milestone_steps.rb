Then(/^I should see the upcoming milestone "(.*?)"$/) do |title|
   wait_for_nothing_to_be_animating
   check_element_exists_and_is_visible "view:'MilestoneTableViewCell' label marked:\"#{title}\""
end

Then(/^I should not see the upcoming milestone "(.*?)"$/) do |title|
  wait_for_nothing_to_be_animating
  selector = "view:'MilestoneTableViewCell' label marked:\"#{title}\" parent view:'MilestoneTableViewCell'"

  # there seems to be a bug in 'check_element_does_not_exist_or_is_not_visible', even though the element is hidden this fails
  if !frankly_map(selector, 'isHidden')
    check_element_does_not_exist_or_is_not_visible(selector)
  end
end

Then(/^I tap on the upcoming milestone "(.*?)"$/) do |title|
  touch("view:'MilestoneTableViewCell' label marked:\"#{title}\" parent view:'MilestoneTableViewCell'")
end

When(/^I tap the noted milestone "(.*?)"$/) do |title|
  touch("view:'AchievementTableViewCell' label marked:\"#{title}\" parent view:'AchievementTableViewCell'")
end

Then(/^I should see the noted milestone "(.*?)"$/) do |title|
   wait_for_nothing_to_be_animating
   check_element_exists "view:'AchievementTableViewCell' label marked:\"#{title}\""
end

Then(/^I should not see the noted milestone "(.*?)"$/) do |title|
    wait_for_nothing_to_be_animating
    selector = "view:'AchievementTableViewCell' label marked:\"#{title}\" parent view:'AchievementTableViewCell'"
    check_element_does_not_exist_or_is_not_visible(selector)
end