Feature: Upcoming milestones
  Upcoming milestones are milestones which we think your baby will complete soon or in the future.
  An upcoming milestone can be viewed, ignored, postponed or noted.
  If an upcoming milestone is ignored, postponed or noted, then it should not be visible in the upcoming section.
  If an upcoming milestone is noted, then it should be visible in the noted milestones section.

  Scenario: View an upcoming milestone
  TODO!

  Scenario: Note an upcoming milestone
    Given I just entered my baby's information and he was born today
    Then I should be on the "Main Milestones" screen
    Then I should see the upcoming milestone "First fart"
    Then I tap on the upcoming milestone "First fart"
    Then I should be on the "Note Milestone" screen
    When I tap the text field "Comments" and type "Automted Test"
    Then I tap the navigation button "Note It"
    And I wait for the progress indicator to finish
    Then I should be on the "Main Milestone" screen
    Then I should see the noted milestone "First fart"
    And I should not see the upcoming milestone "First fart"


  Scenario: Ignore an upcoming milestone
  TODO!


  Scenario: Postpone an upcoming milestone
  TODO!
