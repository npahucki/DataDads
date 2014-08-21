Feature: Noted milestones
    Noted milestones can be viewed, shared and deleted. The picture can also be changed.

  Scenario: View a noted milestone, after being logged in already
    Given I just entered my baby's information and he was born today
    Then I should be on the "Main Milestones" screen
    And I should see the noted milestone "He's born and is beautiful!"
    When I tap the noted milestone "He's born and is beautiful"
    Then I should be on the "Details" screen
    And I should see the text "He's born and is beautiful"
    When I tap the navigation button "Milestones"
    Then I should be on the "Main Milestones" screen
