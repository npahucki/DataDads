Feature: Custom milestones
  Custom milestones are milestones which are not found in the Upcoming or Outgrown milestone list but that the
  user wants to note with an optional photo.
  A custom milestone can be created by clicking the "+" button in the navigation bar
  If a custom milestone is noted, then it should be visible in the noted milestones section.

  Scenario: Note an upcoming milestone
    Given I just entered my baby's information and he was born today
    Then I should be on the "Main Milestones" screen
    And  I should not see the noted milestone "My Custom Milestone Test"
    When I tap the navigation button "+"
    Then I should be on the "Note Milestone" screen
    When I tap the text field "Milestone Title" and type "My Custom Milestone Test"
    And I tap the text field "Comments" and type "Automted Test"
    Then I tap the navigation button "Note It"
    And I wait for the progress indicator to finish
    Then I should be on the "Main Milestone" screen
    Then I should see the noted milestone "My Custom Milestone Test"
